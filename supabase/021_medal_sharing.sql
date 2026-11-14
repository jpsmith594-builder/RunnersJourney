-- Let friends see a runner's medal wall (opt-out switch, on by default).
-- Run once in the Supabase SQL editor. Safe to run again.

alter table public.profiles
  add column if not exists medals_visible_to_friends boolean not null default true;

-- True when the signed-in runner is a friend of [owner] and [owner] has not
-- hidden their wall.
create or replace function public.friend_medals_visible(owner uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select public.are_friends(auth.uid(), owner)
     and coalesce(
           (select p.medals_visible_to_friends from public.profiles p
             where p.id = owner),
           false);
$$;

revoke all on function public.friend_medals_visible(uuid) from public, anon;
grant execute on function public.friend_medals_visible(uuid) to authenticated;

drop policy if exists "friends read medals" on public.medal_photos;
create policy "friends read medals" on public.medal_photos
  for select using (public.friend_medals_visible(user_id));

drop policy if exists "friends read medal files" on storage.objects;
create policy "friends read medal files" on storage.objects
  for select using (
    bucket_id = 'medal-photos'
    and public.friend_medals_visible(((storage.foldername(name))[1])::uuid)
  );
