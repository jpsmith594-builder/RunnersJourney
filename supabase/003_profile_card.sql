-- Runner profile fields + profile photo storage.
-- Run once in the Supabase SQL editor (also appended to schema.sql for new projects).

alter table public.profiles add column if not exists club text;
alter table public.profiles add column if not exists home_town text;
alter table public.profiles add column if not exists favourite_distance text;
alter table public.profiles add column if not exists avatar_path text;

-- Private bucket for profile photos; files live under <user_id>/<file>
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do nothing;

drop policy if exists "own avatar read" on storage.objects;
drop policy if exists "own avatar insert" on storage.objects;
drop policy if exists "own avatar update" on storage.objects;
drop policy if exists "own avatar delete" on storage.objects;

create policy "own avatar read" on storage.objects
  for select using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own avatar insert" on storage.objects
  for insert with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own avatar update" on storage.objects
  for update using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own avatar delete" on storage.objects
  for delete using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
