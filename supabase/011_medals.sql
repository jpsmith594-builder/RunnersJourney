-- The medal a runner collected at a race: gold, silver or bronze.
alter table public.races
  add column if not exists medal text check (medal in ('gold', 'silver', 'bronze'));
