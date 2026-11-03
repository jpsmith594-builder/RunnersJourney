-- Friends: every runner gets a short friend code; friends can see each other's
-- runner card and races. Run once in the Supabase SQL editor (also appended to
-- schema.sql for new projects).

-- 1. Friend codes -----------------------------------------------------------
alter table public.profiles add column if not exists friend_code text;

create or replace function public.gen_friend_code()
returns text
language plpgsql
security definer set search_path = public
as $$
declare c text;
begin
  loop
    c := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    exit when not exists (select 1 from public.profiles where friend_code = c);
  end loop;
  return c;
end $$;

update public.profiles set friend_code = public.gen_friend_code() where friend_code is null;
alter table public.profiles alter column friend_code set default public.gen_friend_code();
create unique index if not exists profiles_friend_code_idx on public.profiles (friend_code);

-- 2. Friendships ------------------------------------------------------------
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester uuid not null references auth.users(id) on delete cascade,
  addressee uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  check (requester <> addressee)
);
create unique index if not exists friendships_pair_idx
  on public.friendships (least(requester, addressee), greatest(requester, addressee));

alter table public.friendships enable row level security;

drop policy if exists "see own friendships" on public.friendships;
drop policy if exists "remove own friendships" on public.friendships;
drop policy if exists "accept requests" on public.friendships;
create policy "see own friendships" on public.friendships
  for select using (auth.uid() in (requester, addressee));
create policy "remove own friendships" on public.friendships
  for delete using (auth.uid() in (requester, addressee));
create policy "accept requests" on public.friendships
  for update using (addressee = auth.uid()) with check (addressee = auth.uid());

-- 3. Helpers (security definer, so they can look across runners safely) -----
create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.friendships
    where status = 'accepted'
      and ((requester = a and addressee = b) or (requester = b and addressee = a))
  );
$$;

-- Sends a friend request using the other runner's code. If they had already
-- asked you, the request is accepted. Returns the other runner's name.
create or replace function public.add_friend_by_code(p_code text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_other uuid;
  v_name text;
  v_existing public.friendships;
begin
  select id, display_name into v_other, v_name
  from public.profiles where friend_code = upper(trim(p_code));
  if v_other is null then
    raise exception 'No runner found with that code';
  end if;
  if v_other = auth.uid() then
    raise exception 'That is your own code';
  end if;
  select * into v_existing from public.friendships
  where (requester = auth.uid() and addressee = v_other)
     or (requester = v_other and addressee = auth.uid());
  if found then
    if v_existing.status = 'pending' and v_existing.addressee = auth.uid() then
      update public.friendships set status = 'accepted' where id = v_existing.id;
    end if;
  else
    insert into public.friendships (requester, addressee) values (auth.uid(), v_other);
  end if;
  return coalesce(v_name, 'Runner');
end $$;

-- The signed-in runner's friends and pending requests, with names.
create or replace function public.my_friendships()
returns table (friendship_id uuid, other_id uuid, other_name text, status text, incoming boolean)
language sql stable
security definer set search_path = public
as $$
  select f.id,
         o.id,
         coalesce(o.display_name, 'Runner'),
         f.status,
         (f.addressee = auth.uid())
  from public.friendships f
  join public.profiles o
    on o.id = case when f.requester = auth.uid() then f.addressee else f.requester end
  where auth.uid() in (f.requester, f.addressee)
  order by f.created_at;
$$;

-- 4. Friends may read each other's profile, races and profile photo ---------
drop policy if exists "friends read profiles" on public.profiles;
drop policy if exists "friends read races" on public.races;
drop policy if exists "friends read avatars" on storage.objects;

create policy "friends read profiles" on public.profiles
  for select using (public.are_friends(auth.uid(), id));
create policy "friends read races" on public.races
  for select using (public.are_friends(auth.uid(), user_id));
create policy "friends read avatars" on storage.objects
  for select using (
    bucket_id = 'avatars'
    and public.are_friends(auth.uid(), ((storage.foldername(name))[1])::uuid)
  );
