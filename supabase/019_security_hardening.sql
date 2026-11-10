-- Security hardening from the security review (see SECURITY_REVIEW.md).
-- Safe to run more than once. Run in the Supabase SQL editor, then append to
-- schema.sql for new projects.

-- 1. Friend requests: the person asked may ONLY accept. Before this, the
--    update policy let them rewrite any column (for example set "requester"
--    to someone else and become "friends" with them, which opens that
--    runner's profile and races).
drop policy if exists "accept requests" on public.friendships;
create policy "accept requests" on public.friendships
  for update
  using (addressee = auth.uid() and status = 'pending')
  with check (addressee = auth.uid() and status = 'accepted');

create or replace function public.friendships_guard()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is not null and (
       new.id is distinct from old.id
    or new.requester is distinct from old.requester
    or new.addressee is distinct from old.addressee
    or new.created_at is distinct from old.created_at
  ) then
    raise exception 'friendships can only be accepted';
  end if;
  return new;
end $$;

drop trigger if exists friendships_guard on public.friendships;
create trigger friendships_guard
  before update on public.friendships
  for each row execute function public.friendships_guard();

-- 2. Friend codes: sign-in required, and a limit on guesses so codes cannot
--    be brute-forced to find runners.
create table if not exists public.friend_code_attempts (
  user_id uuid not null,
  tried_at timestamptz not null default now()
);
create index if not exists friend_code_attempts_idx
  on public.friend_code_attempts (user_id, tried_at);
alter table public.friend_code_attempts enable row level security;
-- No policies: only the function below touches this table.

create or replace function public.add_friend_by_code(p_code text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_other uuid;
  v_name text;
  v_existing public.friendships;
  v_tries int;
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;

  delete from public.friend_code_attempts where tried_at < now() - interval '1 day';
  select count(*) into v_tries from public.friend_code_attempts
   where user_id = auth.uid() and tried_at > now() - interval '1 hour';
  if v_tries >= 20 then
    raise exception 'Too many tries. Please wait an hour and try again.';
  end if;
  insert into public.friend_code_attempts (user_id) values (auth.uid());

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

revoke all on function public.add_friend_by_code(text) from public, anon;
grant execute on function public.add_friend_by_code(text) to authenticated;

-- 3. Helpers should not answer for strangers or for anonymous callers.
create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select auth.uid() in (a, b) and exists (
    select 1 from public.friendships
    where status = 'accepted'
      and ((requester = a and addressee = b) or (requester = b and addressee = a))
  );
$$;

revoke all on function public.are_friends(uuid, uuid) from public, anon;
revoke all on function public.can_see_race(uuid) from public, anon;
revoke all on function public.my_friendships() from public, anon;
revoke all on function public.is_subscriber(uuid) from public, anon;
revoke all on function public.gen_friend_code() from public, anon;
grant execute on function public.are_friends(uuid, uuid) to authenticated;
grant execute on function public.can_see_race(uuid) to authenticated;
grant execute on function public.my_friendships() to authenticated;
grant execute on function public.is_subscriber(uuid) to authenticated;
grant execute on function public.gen_friend_code() to authenticated;
-- gen_friend_code is a column default, so signed-in runners must keep access to it.

-- 4. A photo row may only point at the runner's own race (before this, a
--    friend could attach rows to someone else's race and use up its photo limit).
drop policy if exists "own photos" on public.race_photos;
create policy "own photos" on public.race_photos
  for all
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.races r
      where r.id = race_id and r.user_id = auth.uid()
    )
  );

-- 5. Storage: only small JPEG or PNG pictures. The app already shrinks photos
--    to about 1600 px, so honest uploads are far below these limits.
update storage.buckets
   set file_size_limit = 5242880,
       allowed_mime_types = array['image/jpeg', 'image/png']
 where id = 'race-photos';
update storage.buckets
   set file_size_limit = 3145728,
       allowed_mime_types = array['image/jpeg', 'image/png']
 where id = 'avatars';

-- 6. Sensible text lengths. "not valid" checks new and changed rows only, so
--    existing data is never rejected.
alter table public.races drop constraint if exists races_text_len;
alter table public.races add constraint races_text_len check (
  char_length(name) <= 120
  and char_length(coalesce(location_name, '')) <= 200
  and char_length(coalesce(notes, '')) <= 4000
) not valid;

alter table public.race_photos drop constraint if exists race_photos_caption_len;
alter table public.race_photos add constraint race_photos_caption_len check (
  char_length(coalesce(caption, '')) <= 300
) not valid;

alter table public.bucket_list drop constraint if exists bucket_list_text_len;
alter table public.bucket_list add constraint bucket_list_text_len check (
  char_length(name) <= 120 and char_length(coalesce(location_name, '')) <= 200
) not valid;

alter table public.profiles drop constraint if exists profiles_text_len;
alter table public.profiles add constraint profiles_text_len check (
  char_length(coalesce(display_name, '')) <= 60
  and char_length(coalesce(club, '')) <= 60
  and char_length(coalesce(home_town, '')) <= 100
) not valid;
