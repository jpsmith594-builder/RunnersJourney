-- Account types: free, premium (given unlimited access, e.g. testers or
-- friends) and admin (the creator). Paid subscribers stay "free" here; their
-- access comes from the subscriptions table.
alter table public.profiles
  add column if not exists account_type text not null default 'free'
  check (account_type in ('free', 'premium', 'admin'));

-- Runners must not be able to promote themselves. Only the SQL editor and the
-- service role (where auth.uid() is null) can change account_type.
create or replace function public.protect_account_type()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is not null then
    if tg_op = 'INSERT' then
      new.account_type := 'free';
    else
      new.account_type := old.account_type;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_account_type on public.profiles;
create trigger profiles_protect_account_type
  before insert or update on public.profiles
  for each row execute function public.protect_account_type();

-- Premium and admin accounts get the same unlimited access as subscribers.
create or replace function public.is_subscriber(uid uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = uid and p.account_type in ('premium', 'admin')
  ) or exists (
    select 1 from public.subscriptions s
    where s.user_id = uid and s.active
      and (s.expires_at is null or s.expires_at > now())
  );
$$;

-- Make yourself the admin (run once, in the SQL editor):
--   update public.profiles set account_type = 'admin'
--   where id = (select id from auth.users where email = 'YOUR-EMAIL');
-- Give a friend or tester unlimited access the same way with 'premium'.
