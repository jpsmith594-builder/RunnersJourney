-- "Let people from my club find me": an opt-in so club-mates can see each
-- other's name and send a friend request. Races, photos and the runner card
-- stay private until the request is accepted. Run after 015_clubs.sql.
alter table public.profiles
  add column if not exists club_visible boolean not null default false;

-- Changing club switches visibility off again, so a runner is never shown to
-- a new club without choosing it.
create or replace function public.reset_club_visible()
returns trigger language plpgsql as $$
begin
  if new.club_id is distinct from old.club_id then
    new.club_visible := false;
  end if;
  return new;
end $$;

drop trigger if exists profiles_reset_club_visible on public.profiles;
create trigger profiles_reset_club_visible
  before update on public.profiles
  for each row execute function public.reset_club_visible();

-- Club-mates who have also opted in. Empty unless the caller has opted in too.
-- friend_status: none, pending_out (you asked), pending_in (they asked), friends.
create or replace function public.my_club_mates()
returns table (user_id uuid, display_name text, friend_status text)
language sql stable security definer set search_path = public as $$
  with me as (
    select club_id from public.profiles
    where id = auth.uid() and club_visible and club_id is not null
  )
  select p.id,
         coalesce(p.display_name, 'Runner'),
         case
           when f.id is null then 'none'
           when f.status = 'accepted' then 'friends'
           when f.addressee = auth.uid() then 'pending_in'
           else 'pending_out'
         end
  from public.profiles p
  join me on p.club_id = me.club_id
  left join public.friendships f
    on least(f.requester, f.addressee) = least(auth.uid(), p.id)
   and greatest(f.requester, f.addressee) = greatest(auth.uid(), p.id)
  where p.club_visible and p.id <> auth.uid()
  order by lower(coalesce(p.display_name, 'Runner'))
  limit 200
$$;

-- Sends a friend request to a club-mate (or accepts one they sent you).
-- Both runners must be in the same club and have opted in.
create or replace function public.add_club_mate(p_user uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_name text;
  v_existing public.friendships;
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  if p_user = auth.uid() then
    raise exception 'That is you';
  end if;
  select coalesce(o.display_name, 'Runner') into v_name
  from public.profiles me
  join public.profiles o on o.club_id = me.club_id
  where me.id = auth.uid() and me.club_visible and me.club_id is not null
    and o.id = p_user and o.club_visible;
  if v_name is null then
    raise exception 'That runner is not visible in your club';
  end if;
  select * into v_existing from public.friendships
  where (requester = auth.uid() and addressee = p_user)
     or (requester = p_user and addressee = auth.uid());
  if found then
    if v_existing.status = 'pending' and v_existing.addressee = auth.uid() then
      update public.friendships set status = 'accepted' where id = v_existing.id;
    end if;
  else
    insert into public.friendships (requester, addressee) values (auth.uid(), p_user);
  end if;
  return v_name;
end $$;

revoke all on function public.my_club_mates() from public, anon;
revoke all on function public.add_club_mate(uuid) from public, anon;
grant execute on function public.my_club_mates() to authenticated;
grant execute on function public.add_club_mate(uuid) to authenticated;
