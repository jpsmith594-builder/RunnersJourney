-- Yearly goals a runner sets for themselves (distance in km and number of races).
alter table public.profiles
  add column if not exists goal_km integer check (goal_km is null or (goal_km > 0 and goal_km <= 100000)),
  add column if not exists goal_races integer check (goal_races is null or (goal_races > 0 and goal_races <= 1000));
