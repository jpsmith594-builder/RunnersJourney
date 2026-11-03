-- Reactions: friends can cheer on each other's races. Run once in the Supabase
-- SQL editor (also appended to schema.sql for new projects). Needs 006_friends.sql first.

create table if not exists public.race_reactions (
  race_id uuid not null references public.races(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  emoji text not null check (emoji in ('clap', 'fire', 'muscle', 'party')),
  created_at timestamptz not null default now(),
  primary key (race_id, user_id, emoji)
);

alter table public.race_reactions enable row level security;

-- Runner who owns the race, or their friends, can see and add reactions.
create or replace function public.can_see_race(p_race uuid)
returns boolean
language sql stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.races r
    where r.id = p_race
      and (r.user_id = auth.uid() or public.are_friends(auth.uid(), r.user_id))
  );
$$;

drop policy if exists "see reactions" on public.race_reactions;
drop policy if exists "add reactions" on public.race_reactions;
drop policy if exists "remove own reactions" on public.race_reactions;
create policy "see reactions" on public.race_reactions
  for select using (public.can_see_race(race_id));
create policy "add reactions" on public.race_reactions
  for insert with check (user_id = auth.uid() and public.can_see_race(race_id));
create policy "remove own reactions" on public.race_reactions
  for delete using (user_id = auth.uid());
