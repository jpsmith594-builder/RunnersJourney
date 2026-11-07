-- Goals are kept per year, so past years keep their targets and the app can
-- show a history. Any goal already saved on the profile becomes this year's.
create table if not exists public.yearly_goals (
  user_id uuid not null references auth.users (id) on delete cascade,
  year integer not null check (year between 2000 and 2100),
  goal_km integer check (goal_km is null or (goal_km > 0 and goal_km <= 100000)),
  goal_races integer check (goal_races is null or (goal_races > 0 and goal_races <= 1000)),
  primary key (user_id, year)
);

alter table public.yearly_goals enable row level security;

drop policy if exists "own goals" on public.yearly_goals;
create policy "own goals" on public.yearly_goals
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

insert into public.yearly_goals (user_id, year, goal_km, goal_races)
select id, extract(year from now())::int, goal_km, goal_races
from public.profiles
where goal_km is not null or goal_races is not null
on conflict (user_id, year) do nothing;
