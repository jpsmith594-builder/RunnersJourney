-- Gender and age (stored as birth year) for the runner profile / card.
-- Run once in the Supabase SQL editor (also appended to schema.sql for new projects).

alter table public.profiles add column if not exists gender text;
alter table public.profiles add column if not exists birth_year integer;

alter table public.profiles drop constraint if exists profiles_gender_check;
alter table public.profiles add constraint profiles_gender_check
  check (gender is null or gender in ('male', 'female', 'non_binary', 'undisclosed'));

alter table public.profiles drop constraint if exists profiles_birth_year_check;
alter table public.profiles add constraint profiles_birth_year_check
  check (birth_year is null or birth_year between 1900 and 2100);
