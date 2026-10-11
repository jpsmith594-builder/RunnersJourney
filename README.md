# Trailkeeper (working title)

A runner's life diary: races become points of interest along an illustrated jungle trail.

## Decisions
- Flutter (Android + iOS, one codebase)
- Supabase: Auth, Postgres, Storage (photos)
- GitHub: source + CI
- Illustrated trail map (not a real map), manual race entry for v1
- Separate app from Cadence; data model kept simple so it could plug in later

## Core features (v1)
1. Sign up / log in (Supabase Auth)
2. Add a race: name, date, distance, time, positions, location, notes; status planned/completed
3. Journey screen: scrollable jungle trail, races as POIs in date order
   - Completed stretch of the trail highlighted; planned stretch dimmed/dashed
   - Tap or hover/long-press a POI -> race card (name, date, distance, time, position, a photo)
   - Mobile has no hover: long-press or tap shows the card; hover works on web/desktop
4. Photos per race (upload to Storage bucket `race-photos`)
5. Seasonal theme: palette + foliage/particles (leaves, rain, blossom, snow) chosen from
   the current date and the runner's hemisphere (from profile location)

## Season logic
Month -> season, flipped for the southern hemisphere. Theme tokens per season
(sky gradient, canopy colour, particle type). Optional later: weather API for live rain/sun.

## Architecture
lib/
  main.dart
  core/ (supabase client, theme, season service)
  features/
    auth/
    races/ (model, repository, add/edit form)
    journey/ (trail painter, POI widget, race card overlay)
    photos/ (picker, upload, gallery)

Trail rendering: CustomPainter draws a winding path; POI positions computed from race order
(equal spacing, gentle sine wobble), drawn with Flutter animations. Illustrated assets
as SVG layers (canopy, vines, ground) tinted by season theme.

## Milestones
1. Repo + Flutter scaffold + Supabase project + run `supabase/schema.sql`
2. Auth + race CRUD
3. Journey trail + POIs + race card
4. Photos
5. Seasonal theme
6. Polish, store builds (Android first, iOS needs a Mac + Apple developer account)

## Setup
1. Create a Supabase project, run `supabase/schema.sql` in the SQL editor
2. `flutter create .` then add `supabase_flutter`, `image_picker`, `flutter_svg`
3. Provide `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define` (never commit keys)
