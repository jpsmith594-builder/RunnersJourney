-- Raises the subscriber medal limit from 200 to 500. Run once in the SQL editor.
create or replace function public.enforce_medal_limit()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  cnt int;
  lim int;
begin
  if auth.uid() is null then return new; end if;
  lim := case when public.is_subscriber(new.user_id) then 500 else 5 end;
  select count(*) into cnt from public.medal_photos where user_id = new.user_id;
  if cnt >= lim then raise exception 'medal_limit'; end if;
  return new;
end;
$$;
