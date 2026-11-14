-- Club codes, friend referral codes, referral credit and earned free slots.
-- Run once in the Supabase SQL editor. Safe to run again.
-- Rules are in docs/growth_spec.md.

-- ---------------------------------------------------------------- tables

create table if not exists public.promo_codes (
  code text primary key,
  kind text not null check (kind in ('club', 'referral')),
  owner_id uuid references public.profiles(id) on delete cascade,
  club_name text,
  contact_email text,
  active boolean not null default true,
  note text,
  created_at timestamptz not null default now(),
  constraint promo_code_shape check (
    (kind = 'referral' and owner_id is not null) or
    (kind = 'club' and club_name is not null))
);
create unique index if not exists promo_codes_one_referral
  on public.promo_codes (owner_id) where kind = 'referral';

-- One row per runner: a runner can use ONE code, ever (club or friend).
create table if not exists public.code_redemptions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  code text not null references public.promo_codes(code),
  kind text not null,
  redeemed_at timestamptz not null default now(),
  purchased_at timestamptz,   -- set by the RevenueCat webhook (first purchase)
  product_id text,
  voided boolean not null default false  -- refunded
);
create index if not exists code_redemptions_code on public.code_redemptions (code);

-- Credit earned, expressed as free months added to the next renewal.
create table if not exists public.credit_grants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  email text,
  months int not null check (months > 0),
  reason text not null,
  grant_key text not null unique,
  created_at timestamptz not null default now(),
  applied_at timestamptz
);

-- Referral counting restarts each time credit is applied.
create table if not exists public.referral_cycle (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  cycle_start timestamptz not null default now()
);

alter table public.promo_codes enable row level security;
alter table public.code_redemptions enable row level security;
alter table public.credit_grants enable row level security;
alter table public.referral_cycle enable row level security;

drop policy if exists "read own referral code" on public.promo_codes;
create policy "read own referral code" on public.promo_codes
  for select using (owner_id = auth.uid());
drop policy if exists "read own redemption" on public.code_redemptions;
create policy "read own redemption" on public.code_redemptions
  for select using (user_id = auth.uid());
drop policy if exists "read own credit" on public.credit_grants;
create policy "read own credit" on public.credit_grants
  for select using (user_id = auth.uid());
-- No write policies: everything is written by the functions below or by the
-- server (service role).

-- ---------------------------------------------------------------- helpers

-- A redemption counts once the purchase is 30 days old and was not refunded.
create or replace function public.is_qualified(r public.code_redemptions)
returns boolean
language sql immutable
as $$
  select r.purchased_at is not null
     and r.purchased_at <= now() - interval '30 days'
     and not r.voided;
$$;

-- Free months for a number of qualified referrals (see the spec).
create or replace function public.referral_months(n int)
returns int
language sql immutable
as $$
  select case
    when n >= 30 then 6   -- 50%
    when n >= 20 then 4   -- 35%
    when n >= 10 then 3   -- 25%
    when n >= 5  then 2   -- 15%
    when n >= 3  then 1   -- 10%
    else 0 end;
$$;

-- Extra free-plan race slots earned by inviting friends (max 5): one for each
-- friend who used your code and has added a finished race.
create or replace function public.bonus_slots(uid uuid)
returns int
language plpgsql stable
security definer set search_path = public
as $$
declare n int;
begin
  if auth.uid() is not null and uid <> auth.uid() then return 0; end if;
  select count(*) into n
  from public.code_redemptions r
  join public.promo_codes c on c.code = r.code
  where c.kind = 'referral' and c.owner_id = uid and not r.voided
    and exists (select 1 from public.races x
                where x.user_id = r.user_id and x.status <> 'planned');
  return least(5, coalesce(n, 0));
end;
$$;

-- The free race limit now includes earned slots.
create or replace function public.enforce_race_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  lim int;
  cnt int;
  was_counted boolean;
  will_count boolean;
begin
  if auth.uid() is null or public.is_subscriber(new.user_id) then
    return new;
  end if;
  lim := 5 + public.bonus_slots(new.user_id);

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

-- ------------------------------------------------------- runner functions

-- The signed-in runner's own referral code (made on first use).
create or replace function public.my_referral_code()
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  c text;
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
begin
  if uid is null then raise exception 'not_signed_in'; end if;
  select code into c from public.promo_codes
    where kind = 'referral' and owner_id = uid;
  if c is not null then return c; end if;
  loop
    c := 'REF-';
    for i in 1..6 loop
      c := c || substr(alphabet, 1 + floor(random() * 32)::int, 1);
    end loop;
    begin
      insert into public.promo_codes (code, kind, owner_id) values (c, 'referral', uid);
      return c;
    exception when unique_violation then
      select code into c from public.promo_codes
        where kind = 'referral' and owner_id = uid;
      if c is not null then return c; end if;
    end;
  end loop;
end;
$$;

-- Use a club or friend code. Returns what it unlocks.
create or replace function public.redeem_code(p_code text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  c public.promo_codes;
  existing public.code_redemptions;
begin
  if uid is null then raise exception 'not_signed_in'; end if;
  select * into c from public.promo_codes
    where code = upper(trim(p_code)) and active;
  if not found then raise exception 'code_invalid'; end if;

  select * into existing from public.code_redemptions where user_id = uid;
  if found then
    if existing.code = c.code then
      return jsonb_build_object('kind', c.kind, 'club', c.club_name,
        'discount_pct', case c.kind when 'club' then 15 else 10 end);
    end if;
    raise exception 'code_already_used';
  end if;

  -- Only new subscribers: anyone who has ever had a plan is not new.
  if exists (select 1 from public.subscriptions s
             where s.user_id = uid and s.plan is not null) then
    raise exception 'code_not_new';
  end if;
  if c.kind = 'referral' and c.owner_id = uid then raise exception 'code_own'; end if;

  insert into public.code_redemptions (user_id, code, kind)
    values (uid, c.code, c.kind);
  return jsonb_build_object('kind', c.kind, 'club', c.club_name,
    'discount_pct', case c.kind when 'club' then 15 else 10 end);
end;
$$;

-- Everything the "Invite and earn" screen shows.
create or replace function public.referral_summary()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  my_code text;
  cyc timestamptz;
  joined int; pending int; qualified int;
  months int; next_at int; banked int; slots int;
begin
  if uid is null then raise exception 'not_signed_in'; end if;
  my_code := public.my_referral_code();
  perform public.sync_rewards_for(uid);
  select coalesce(cycle_start, '-infinity') into cyc
    from public.referral_cycle where user_id = uid;
  cyc := coalesce(cyc, '-infinity');

  select count(*) into joined from public.code_redemptions r
    where r.code = my_code and not r.voided;
  select count(*) filter (where public.is_qualified(r)) ,
         count(*) filter (where r.purchased_at is not null
                          and not public.is_qualified(r) and not r.voided)
    into qualified, pending
    from public.code_redemptions r
    where r.code = my_code and (r.purchased_at is null or r.purchased_at > cyc);
  months := public.referral_months(qualified);
  next_at := case when qualified < 3 then 3 when qualified < 5 then 5
                  when qualified < 10 then 10 when qualified < 20 then 20
                  when qualified < 30 then 30 else null end;
  select coalesce(sum(g.months), 0) into banked from public.credit_grants g
    where g.user_id = uid and g.applied_at is null;
  slots := public.bonus_slots(uid);
  return jsonb_build_object(
    'code', my_code, 'joined', joined, 'subscribed_pending', pending,
    'qualified', qualified, 'months_earned', months, 'next_tier_at', next_at,
    'months_banked', banked, 'bonus_slots', slots);
end;
$$;

-- --------------------------------------------------------------- rewards

-- Creates the credit a referral owner has earned (safe to run repeatedly).
create or replace function public.sync_rewards_for(uid uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  cyc timestamptz;
  v_code text;
  n int; total int; have int;
begin
  select cycle_start into cyc from public.referral_cycle where user_id = uid;
  cyc := coalesce(cyc, '-infinity');
  select p.code into v_code from public.promo_codes p
    where p.kind = 'referral' and p.owner_id = uid;
  if v_code is null then return; end if;
  select count(*) into n from public.code_redemptions r
    where r.code = v_code and public.is_qualified(r) and r.purchased_at > cyc;
  total := public.referral_months(n);
  select coalesce(sum(g.months), 0) into have from public.credit_grants g
    where g.user_id = uid and g.grant_key like 'ref:' || extract(epoch from cyc)::text || ':%';
  if total > have then
    insert into public.credit_grants (user_id, months, reason, grant_key)
    values (uid, total - have, 'referral',
            'ref:' || extract(epoch from cyc)::text || ':' || total)
    on conflict (grant_key) do nothing;
  end if;
end;
$$;

-- Club contacts earn a free year at 10 paid sign-ups and another at 25.
create or replace function public.sync_club_rewards()
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  c record;
  n int;
  m int;
  contact uuid;
begin
  for c in select * from public.promo_codes where kind = 'club' loop
    contact := null;
    select count(*) into n from public.code_redemptions r
      where r.code = c.code and public.is_qualified(r);
    if c.contact_email is not null then
      select u.id into contact from auth.users u
        where lower(u.email) = lower(c.contact_email) limit 1;
    end if;
    foreach m in array array[10, 25] loop
      if n >= m then
        insert into public.credit_grants (user_id, email, months, reason, grant_key)
        values (contact, c.contact_email, 12, 'club contact: ' || c.club_name,
                'club:' || c.code || ':' || m)
        on conflict (grant_key) do nothing;
      end if;
    end loop;
  end loop;
end;
$$;

-- Run by an admin (or on a schedule) to create all earned credit.
create or replace function public.sync_all_rewards()
returns void
language plpgsql
security definer set search_path = public
as $$
declare r record;
begin
  for r in select owner_id from public.promo_codes where kind = 'referral' loop
    perform public.sync_rewards_for(r.owner_id);
  end loop;
  perform public.sync_club_rewards();
end;
$$;

-- --------------------------------------------------------- admin (SQL editor)
-- Not callable from the app.

-- select public.create_club_code('CLUB-BELLVILLE', 'Bellville Runners', 'contact@example.com', 'note');
create or replace function public.create_club_code(
  p_code text, p_club text, p_contact_email text default null, p_note text default null)
returns text
language sql
security definer set search_path = public
as $$
  insert into public.promo_codes (code, kind, club_name, contact_email, note)
  values (upper(trim(p_code)), 'club', p_club, p_contact_email, p_note)
  returning code;
$$;

-- After you extend a runner's subscription in RevenueCat/Play, mark it done:
-- select public.mark_credits_applied('<user id>');
create or replace function public.mark_credits_applied(p_user uuid)
returns void
language sql
security definer set search_path = public
as $$
  update public.credit_grants set applied_at = now()
    where user_id = p_user and applied_at is null;
  insert into public.referral_cycle (user_id, cycle_start) values (p_user, now())
    on conflict (user_id) do update set cycle_start = now();
$$;

create or replace view public.admin_credits_to_apply as
  select g.id, g.user_id, coalesce(u.email, g.email) as email,
         g.months, g.reason, g.created_at
  from public.credit_grants g
  left join auth.users u on u.id = g.user_id
  where g.applied_at is null
  order by g.created_at;

create or replace view public.admin_code_stats as
  select c.code, c.kind, c.club_name, c.contact_email, c.active,
         count(r.user_id) as redeemed,
         count(r.purchased_at) as purchased,
         count(*) filter (where public.is_qualified(r)) as qualified
  from public.promo_codes c
  left join public.code_redemptions r on r.code = c.code
  group by c.code
  order by qualified desc, redeemed desc;

revoke all on function public.create_club_code(text, text, text, text) from public, anon, authenticated;
revoke all on function public.mark_credits_applied(uuid) from public, anon, authenticated;
revoke all on function public.sync_all_rewards() from public, anon, authenticated;
revoke all on function public.sync_club_rewards() from public, anon, authenticated;
revoke all on function public.sync_rewards_for(uuid) from public, anon, authenticated;
revoke all on public.admin_credits_to_apply from public, anon, authenticated;
revoke all on public.admin_code_stats from public, anon, authenticated;

revoke all on function public.my_referral_code() from public, anon;
revoke all on function public.redeem_code(text) from public, anon;
revoke all on function public.referral_summary() from public, anon;
revoke all on function public.bonus_slots(uuid) from public, anon;
grant execute on function public.my_referral_code() to authenticated;
grant execute on function public.redeem_code(text) to authenticated;
grant execute on function public.referral_summary() to authenticated;
grant execute on function public.bonus_slots(uuid) to authenticated;

-- Optional: create earned credit every night (Database > Extensions > pg_cron).
-- select cron.schedule('growth-rewards', '15 2 * * *', 'select public.sync_all_rewards()');
