-- Places go global: races and bucket-list items keep their own coordinates,
-- region and country, so any town in the world can be pinned on the map.
alter table public.races
  add column if not exists region text,
  add column if not exists country text;

alter table public.bucket_list
  add column if not exists lat double precision,
  add column if not exists lng double precision,
  add column if not exists region text,
  add column if not exists country text;

-- Races saved before this change were all in South Africa.
update public.races set country = 'South Africa'
  where country is null and lat is not null;
