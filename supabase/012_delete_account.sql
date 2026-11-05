-- Lets a signed-in runner delete their own account. Deleting the auth user
-- removes everything that belongs to them (profile, races, photo rows,
-- bucket list, friendships, reactions, subscription row) because those tables
-- all cascade from auth.users. The app removes the stored photo files first.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
