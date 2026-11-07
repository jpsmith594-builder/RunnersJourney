-- Running clubs: one official record per club, so two runners from the same
-- club end up in the same place even if one of them mistypes the name.
create extension if not exists pg_trgm;

-- A cleaned-up version of a club name used to spot duplicates: lower case, no
-- dots or punctuation, and the common words "athletic(s)", "running", "club",
-- "runners", "ac", "sac" and "rc" ignored. "Sea Point A.C" and "Sea Point
-- Athletic Club" give the same key.
create or replace function public.club_key(n text)
returns text language sql immutable as $$
  select regexp_replace(
    regexp_replace(
      regexp_replace(lower(coalesce(n, '')), '\.', '', 'g'),
      '\m(athletic|athletics|running|club|runners|ac|sac|rc)\M', ' ', 'g'),
    '[^a-z0-9]', '', 'g')
$$;

create table if not exists public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 2 and 60),
  area text,
  province text,
  country text not null default 'South Africa',
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create unique index if not exists clubs_key_unique
  on public.clubs (country, public.club_key(name));
create index if not exists clubs_name_trgm
  on public.clubs using gin (name gin_trgm_ops);

alter table public.clubs enable row level security;

drop policy if exists "clubs readable" on public.clubs;
create policy "clubs readable" on public.clubs
  for select to authenticated using (true);
-- New clubs are added through find_or_create_club below; changing or removing
-- clubs (merging duplicates) is done in the SQL editor.

alter table public.profiles
  add column if not exists club_id uuid references public.clubs (id) on delete set null;

-- Suggestions while typing: prefix and contains matches first, then similar
-- spellings. "exact" is true when the club is the same after cleaning up.
create or replace function public.search_clubs(q text)
returns table (id uuid, name text, area text, members bigint, score real, exact boolean)
language sql stable security definer set search_path = public as $$
  select c.id, c.name, c.area,
         (select count(*) from public.profiles p where p.club_id = c.id) as members,
         greatest(similarity(c.name, q),
                  similarity(public.club_key(c.name), public.club_key(q)))::real as score,
         public.club_key(c.name) = public.club_key(q) as exact
  from public.clubs c
  where auth.uid() is not null
    and char_length(btrim(q)) >= 2
    and (c.name ilike '%' || btrim(q) || '%'
         or similarity(c.name, q) > 0.3
         or similarity(public.club_key(c.name), public.club_key(q)) > 0.4)
  order by (c.name ilike btrim(q) || '%') desc, score desc, c.name
  limit 8
$$;

-- Returns the club with this name (after cleaning up), creating it if needed.
create or replace function public.find_or_create_club(p_name text, p_area text default null)
returns table (id uuid, name text)
language plpgsql security definer set search_path = public as $$
declare
  n text := btrim(p_name);
  rec public.clubs;
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  if char_length(n) < 2 or char_length(n) > 60 or public.club_key(n) = '' then
    raise exception 'invalid club name';
  end if;
  select * into rec from public.clubs c
   where c.country = 'South Africa' and public.club_key(c.name) = public.club_key(n);
  if rec.id is not null then
    return query select rec.id, rec.name;
    return;
  end if;
  insert into public.clubs (name, area, created_by)
  values (n, nullif(btrim(p_area), ''), auth.uid())
  returning * into rec;
  return query select rec.id, rec.name;
end;
$$;

revoke all on function public.search_clubs(text) from public, anon;
revoke all on function public.find_or_create_club(text, text) from public, anon;
grant execute on function public.search_clubs(text) to authenticated;
grant execute on function public.find_or_create_club(text, text) to authenticated;

-- Western Province Athletics affiliated clubs (published club list, to start
-- the list). Runners can add any club that is missing.
insert into public.clubs (name, area, province) values
  ('Airports Athletics Club', null, 'Western Cape'),
  ('Adventist Athletics Club', 'Langa, Cape Town', 'Western Cape'),
  ('Afrika Tikkun Athletics Club', 'Hyde Park, Johannesburg', 'Gauteng'),
  ('Asics Athletic Club', 'Claremont', 'Western Cape'),
  ('Atlantis Harriers A.C', 'Atlantis', 'Western Cape'),
  ('Atlantic Athletic Club', 'Clifton, Cape Town', 'Western Cape'),
  ('ATC Running Club', 'Green Point', 'Western Cape'),
  ('ARD Athletic Club', 'Kenwyn', 'Western Cape'),
  ('Aurecon W.C R/W Club', 'Cape Town', 'Western Cape'),
  ('Bellville Athletic Club (Track)', 'Bellville', 'Western Cape'),
  ('Bellville Athletic Club (Road)', 'Bellville', 'Western Cape'),
  ('Bishops Running Club', 'Rondebosch', 'Western Cape'),
  ('BOKAAP Athletics', 'Cape Town', 'Western Cape'),
  ('Bonteheuwel Athletic Club', 'Belhar', 'Western Cape'),
  ('Born 2 Run Athletic Club', 'Parklands', 'Western Cape'),
  ('Bottelary Athletics Club', 'Belhar', 'Western Cape'),
  ('Boxer Athletics Club', 'Durbanville', 'Western Cape'),
  ('Brackenfell Athletic Club', 'Brackenfell', 'Western Cape'),
  ('Brimstone Itheko S.A.C', 'Rondebosch', 'Western Cape'),
  ('Cape Multi-Sport', 'Eversdal', 'Western Cape'),
  ('Capricorn Athletic Club', 'Steenberg', 'Western Cape'),
  ('Carbineers Western Province', 'Pinelands', 'Western Cape'),
  ('Celtic Harriers', 'Clareinch', 'Western Cape'),
  ('Central Athletics Club', 'Newlands', 'Western Cape'),
  ('Century City Athletic Club', 'Century City', 'Western Cape'),
  ('Correctional Services A.C', 'Tokai', 'Western Cape'),
  ('C.P.U.T Athletic Club', 'Cape Town', 'Western Cape'),
  ('Chaeli Sports & Recreation Club', 'Plumstead', 'Western Cape'),
  ('Chillie Running Club WP', 'Parklands', 'Western Cape'),
  ('Defence Athletics Club', 'Cape Town', 'Western Cape'),
  ('Durbanville Athletic Club', 'Durbanville', 'Western Cape'),
  ('DALRRD Athletic Club WP', 'Mowbray', 'Western Cape'),
  ('Easterns Kraaifontein A.C', 'Kraaifontein', 'Western Cape'),
  ('Edgemead Runners', 'Bothasig', 'Western Cape'),
  ('Eerste River Athletic Club', 'Eerste River', 'Western Cape'),
  ('Elsies River Athletic Club', 'Matroosfontein', 'Western Cape'),
  ('Farnese Athletic Club', 'Strandfontein', 'Western Cape'),
  ('Fish Hoek A.C', 'Fish Hoek', 'Western Cape'),
  ('Fit 2000 (W.P) A.C', 'Noordhoek', 'Western Cape'),
  ('Foresters Running Club', 'Steenberg', 'Western Cape'),
  ('Goodwood Harriers Running Club', 'Goodwood', 'Western Cape'),
  ('Groot Constantia', 'Constantia', 'Western Cape'),
  ('Harfield Harriers', 'Newlands', 'Western Cape'),
  ('Helderberg Harriers', 'Somerset West', 'Western Cape'),
  ('Herbalife Sports Club', 'Fish Hoek', 'Western Cape'),
  ('Hewat Athletic Club', 'Steenberg', 'Western Cape'),
  ('Hout Bay Harriers', 'Hout Bay', 'Western Cape'),
  ('In Touch Walk / Run', 'Kuils River', 'Western Cape'),
  ('KENFAC SAC', 'Cape Town', 'Western Cape'),
  ('Khayelitsha Athletic Club', 'Khayelitsha', 'Western Cape'),
  ('Kuils River Runners Club', 'Kuils River', 'Western Cape'),
  ('Langa Athletic Club', 'Plumstead', 'Western Cape'),
  ('Lwandle Athletic Club', 'Strand', 'Western Cape'),
  ('Mamre Athletic Club', 'Mamre', 'Western Cape'),
  ('Mandela Park Running Club', 'Khayelitsha', 'Western Cape'),
  ('Manoni Sports Club', 'Khayelitsha', 'Western Cape'),
  ('Mates Mountain & Trail Enthusiast', 'Mowbray', 'Western Cape'),
  ('Mazars Athletics Club', 'Century City', 'Western Cape'),
  ('Melkbos Athletic Club', 'Melkbosstrand', 'Western Cape'),
  ('Metropolitan Athletic Club', 'Bellville', 'Western Cape'),
  ('Mfuleni Athletic Club', 'Mfuleni', 'Western Cape'),
  ('Mitchell''s Plain Titans', 'Mitchells Plain', 'Western Cape'),
  ('MSA MULTISPORT', 'Lansdowne', 'Western Cape'),
  ('Multi - Sport Maniacs', 'Table View', 'Western Cape'),
  ('Midas Spartans A.C', 'Brooklyn, Cape Town', 'Western Cape'),
  ('Murray & Roberts Running Club', 'Bedfordview', 'Gauteng'),
  ('My Training Day Athletics Club', 'Meadowridge', 'Western Cape'),
  ('Nantes Athletic Club', 'Pinelands', 'Western Cape'),
  ('Nedbank A.C', 'Kraaifontein', 'Western Cape'),
  ('Ogilvy & Mather Runners Club', 'Woodstock', 'Western Cape'),
  ('Old Mutual Athletic Club', 'Mutual Park', 'Western Cape'),
  ('Ommiedraai Friends A.C', 'Glosderry', 'Western Cape'),
  ('Open Box Running Club', 'Tokai', 'Western Cape'),
  ('Pick ''n Pay Athletic Club', 'Kenilworth', 'Western Cape'),
  ('Pinelands Athletic Club', 'Howard Place', 'Western Cape'),
  ('Parliament of RSA Athletic Club', 'Cape Town', 'Western Cape'),
  ('Phoenix Athletics Club', 'Bothasig', 'Western Cape'),
  ('Ravensmead Athletic Club', 'Ravensmead', 'Western Cape'),
  ('RCS Gugulethu A.C', 'Gugulethu', 'Western Cape'),
  ('Resbank Athletic Club', 'Cape Town', 'Western Cape'),
  ('Run / Walk for Life', 'Edgemead', 'Western Cape'),
  ('Sanlam Road Running Club', 'Highbury', 'Western Cape'),
  ('SACS Old Boys Running Club', 'Newlands', 'Western Cape'),
  ('SA Police Athletic Club', 'De Tuin', 'Western Cape'),
  ('Satori Athletic Club', 'Noordhoek', 'Western Cape'),
  ('South Peninsula AC', 'Retreat', 'Western Cape'),
  ('Somerset Striders A.C', 'Somerset West', 'Western Cape'),
  ('Southern Striders A.C', 'Bergvliet', 'Western Cape'),
  ('Spartan Harriers', 'Meadowridge', 'Western Cape'),
  ('Stragglers Athletic Club', 'Strandfontein', 'Western Cape'),
  ('Strand Athletic Club', 'Strand', 'Western Cape'),
  ('Thomas Mbiza Athletic Club', 'Simon''s Town', 'Western Cape'),
  ('Top Form Athletic Club', 'Belthorn', 'Western Cape'),
  ('Totalsports VOB Running Club', 'Constantia', 'Western Cape'),
  ('Tygerberg Athletic Club', 'Goodwood', 'Western Cape'),
  ('Ultra-Athletic Club', 'Mitchells Plain', 'Western Cape'),
  ('University of Cape Town A.C', 'Rondebosch', 'Western Cape'),
  ('University of Western Cape AC', 'Bellville', 'Western Cape'),
  ('Velocity Athletic Club', 'Pella', 'Western Cape'),
  ('Vodacom Striders W.P', 'Cape Town', 'Western Cape'),
  ('Walmers Athletics Club', 'Walmer Estate, Woodstock', 'Western Cape'),
  ('West Coast Athletic Club', 'Bloubergstrand', 'Western Cape'),
  ('Western Province Cricket Club', 'Newlands', 'Western Cape'),
  ('Wild Runner Athletic Club', 'Constantia', 'Western Cape'),
  ('Zandvlei Athletic Club', 'Muizenberg', 'Western Cape')
on conflict do nothing;

-- Existing runners who typed a club name: create or match the club and link it.
insert into public.clubs (name, created_by)
select distinct on (public.club_key(p.club)) btrim(p.club), p.id
from public.profiles p
where p.club is not null and public.club_key(p.club) <> ''
  and char_length(btrim(p.club)) between 2 and 60
on conflict do nothing;

update public.profiles p
set club_id = c.id
from public.clubs c
where p.club is not null
  and c.country = 'South Africa'
  and public.club_key(c.name) = public.club_key(p.club);
