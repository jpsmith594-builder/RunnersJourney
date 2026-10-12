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
   (if you ran an earlier version, run `supabase/002_profile_trigger.sql` once)
2. In the repo folder run `flutter create . --project-name runners_journey --org com.runnersjourney`
   to generate the `android/` and `ios/` folders (existing `lib/` and `pubspec.yaml` are kept)
3. `flutter pub get`
4. Copy `env.example.json` to `env.json` and fill in your Supabase URL and anon/publishable key
   (`env.json` is gitignored)
5. `flutter run --dart-define-from-file=env.json`

## Status
- [x] Auth (email + password) and race add / edit / delete / list
- [ ] Jungle trail journey screen
- [ ] Photos
- [ ] Seasonal theme (season logic is in `lib/core/season.dart`)
