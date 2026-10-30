-- ============================================================
-- Assignment Tracking Portal - Supabase setup
-- Run this ONCE in Supabase: SQL Editor -> New query -> paste -> Run
-- ============================================================

-- 1. Table that stores each teacher's assignments
create table if not exists assignments (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  due_date date not null,
  file_path text,
  created_at timestamptz default now()
);

-- 2. Privacy: each teacher can only see and change their OWN rows
alter table assignments enable row level security;

create policy "own select" on assignments for select using (auth.uid() = user_id);
create policy "own insert" on assignments for insert with check (auth.uid() = user_id);
create policy "own update" on assignments for update using (auth.uid() = user_id);
create policy "own delete" on assignments for delete using (auth.uid() = user_id);

-- 3. Private storage bucket for assignment files
insert into storage.buckets (id, name, public)
values ('assignment-files', 'assignment-files', false)
on conflict (id) do nothing;

-- 4. Each teacher can only reach files inside their own folder (folder name = their user id)
create policy "own files select" on storage.objects for select to authenticated
  using (bucket_id = 'assignment-files' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "own files insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'assignment-files' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "own files delete" on storage.objects for delete to authenticated
  using (bucket_id = 'assignment-files' and (storage.foldername(name))[1] = auth.uid()::text);
