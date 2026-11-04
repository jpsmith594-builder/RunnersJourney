-- Subscriptions and the free-plan limits.
--
-- Free plan:  up to 5 races that are not "planned", 1 photo per race.
-- Subscriber: unlimited races, up to 10 photos per race.
-- Planned races and the bucket list are always free.
-- When a subscription ends, a runner with more than 5 races keeps all of them,
-- but they are read-only (viewing and deleting work; adding and editing do not)
-- until the runner subscribes again or deletes down to 5.

create table if not exists public.subscriptions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  active boolean not null default false,
  plan text,
  expires_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

drop policy if exists "read own subscription" on public.subscriptions;
create policy "read own subscription" on public.subscriptions
  for select using (user_id = auth.uid());
-- No insert/update policies: only the server (RevenueCat webhook, service role)
-- writes this table.

create or replace function public.is_subscriber(uid uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.subscriptions s
    where s.user_id = uid and s.active
      and (s.expires_at is null or s.expires_at > now())
  );
$$;

create or replace function public.enforce_race_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  lim constant int := 5;
  cnt int;
  was_counted boolean;
  will_count boolean;
begin
  -- The SQL editor and the service role are not limited.
  if auth.uid() is null or public.is_subscriber(new.user_id) then
    return new;
  end if;

  will_count := new.status <> 'planned';
  select count(*) into cnt from public.races
    where user_id = new.user_id and status <> 'planned'
      and (tg_op = 'INSERT' or id <> new.id);

  if tg_op = 'INSERT' then
    if cnt > lim then raise exception 'read_only'; end if;
    if will_count and cnt >= lim then raise exception 'free_limit'; end if;
    return new;
  end if;

  was_counted := old.status <> 'planned';
  if cnt + (case when was_counted then 1 else 0 end) > lim then
    raise exception 'read_only';
  end if;
  if will_count and not was_counted and cnt >= lim then
    raise exception 'free_limit';
  end if;
  return new;
end;
$$;

drop trigger if exists races_limit on public.races;
create trigger races_limit
  before insert or update on public.races
  for each row execute function public.enforce_race_limit();

create or replace function public.enforce_photo_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  cnt int;
  lim int;
begin
  if auth.uid() is null then return new; end if;
  lim := case when public.is_subscriber(new.user_id) then 10 else 1 end;
  select count(*) into cnt from public.race_photos where race_id = new.race_id;
  if cnt >= lim then raise exception 'photo_limit'; end if;
  return new;
end;
$$;

drop trigger if exists race_photos_limit on public.race_photos;
create trigger race_photos_limit
  before insert on public.race_photos
  for each row execute function public.enforce_photo_limit();

-- To give yourself a subscription while testing (run in the SQL editor):
--   insert into public.subscriptions (user_id, active, plan, expires_at)
--   values ('YOUR-USER-ID', true, 'test', now() + interval '30 days')
--   on conflict (user_id) do update set active = true, expires_at = excluded.expires_at;
