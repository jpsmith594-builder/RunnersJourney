# Runner's Journey

A runner's life diary. Races are pinned on an illustrated map of South Africa,
at the city or town where they were run. Zoom in to see smaller towns, tap a pin
for the race card, and see your own football-style runner card.

## Stack
- Flutter (Android first, iOS later from the same code)
- Supabase: Auth, Postgres, Storage (profile photos)
- GitHub for source

## Features
- Email sign-up / sign-in
- Add, edit, delete races: name, date, status (planned / completed / DNF / DNS),
  distance, finish time, positions, town, notes
- **Journey tab**: the real map of South Africa
  - Races sit on their town. Pinch, scroll, or use the +/- buttons to zoom
  - Major cities always show; regional towns and small towns appear as you zoom in
  - Several races in one town show as a numbered pin; tap it or zoom in and the
    races fan out around the town
  - Tap (or hover on desktop / web) a pin for the race card, then Edit
  - Tap a town name and choose "Add race here"
  - The map's colour grade follows the season (southern hemisphere by default)
  - Races with no known town are listed as "N not on map" until you pick a town
- **Share your runner card**: the share button on the Profile screen turns the card into a
  picture and opens the phone's share sheet (WhatsApp, Instagram, save to gallery...)
- **Race bucket list** (menu): races you want to do one day, each with a tickbox. Open ones
  show as grey pins on the map (tap one to tick it off there); ticked ones leave the map
- **Race calendar** (menu) and race search: a starter list of well-known South African races
  (Comrades, Two Oceans, Cape Town Marathon, Soweto...) with usual timing. Add one to your plan or
  bucket list in a tap, or just start typing a race name in the race form and the town and
  distance fill in. The list lives in `lib/features/calendar/race_event.dart`; dates change every
  year so check the official site
- **Year in review** (menu): a shareable poster of your year: races, km, time racing, towns and
  provinces, longest race, fastest pace, busiest month and personal bests
- **Badges** (menu): 24 crests (bronze, silver, gold, platinum, titanium) with brushed-metal frames, light sweeps and stars for difficulty; locked ones are grey with progress.
  Badges for races finished, distance, firsts (10K, half, marathon,
  ultra), sub-60 10K / sub-2 half / sub-4 marathon, towns and provinces, Comrades, Two Oceans
- **Leaderboard** (Friends screen): you and your friends ranked by km, races or towns, this year
  or all time. Friends can cheer on each other's races with reactions
- **Race reminder**: a banner above the map counts down to your next planned race (within 60
  days). Real phone notifications need extra Android setup and are not added yet
- **My results** (menu): a table of completed races. Filter by distance (5K, 10K, 21K, 42K...)
  and year; sort by date, time, pace, distance or name (tap a column header or use the
  sort box), ascending or descending
- **Friends** (menu): every runner has a friend code. Invite on WhatsApp (or copy the invite),
  or type a friend's code to send a request. Once accepted you can open each other's runner
  card and recent races; either side can remove the friendship at any time
- **Photos**: add pictures to any race (gallery or camera) in the race form; they are
  shrunk on upload, stored privately in Supabase Storage (`race-photos` bucket) and shown
  as thumbnails on the map's race card
- **Races tab**: plain list, newest first
- **Profile** (menu, top right): name, age, gender, running club, home town,
  favourite distance, profile photo. Shows your **runner card**: rating, photo, races, km, towns and
  personal bests (5K / 10K / 21K / 42K). Card tier (bronze, silver, gold, elite) comes
  from the rating: 45 + 2 per finished race + 1 per 15 km + 1 per town

## Setup
1. Create a Supabase project and run `supabase/schema.sql` in the SQL editor.
   If you set up an earlier version, run these once instead:
   `supabase/002_profile_trigger.sql`, `supabase/003_profile_card.sql` and
   `supabase/004_gender_age.sql`, `supabase/005_bucket_list.sql`, `supabase/006_friends.sql`, `supabase/007_reactions.sql` (003 adds the profile columns and the private `avatars`
   photo bucket; 004 adds gender and age, 005 adds the bucket list, 006 adds friends, 007 adds reactions)
2. In the repo folder: `flutter create . --project-name runners_journey --org com.runnersjourney --platforms=android`
   (generates `android/`; your `lib/` and `pubspec.yaml` are kept. Restore any file
   it overwrites with `git restore <file>` and delete `test/widget_test.dart`)
3. `flutter pub get`
4. Copy `env.example.json` to `env.json` and fill in your Supabase URL and anon/publishable
   key (`env.json` is gitignored)
5. `flutter run --dart-define-from-file=env.json`

## The map
A real, zoomable map of South Africa (flutter_map) with your pins, race cards, route lines
and a "replay my journey" button on top. Zoom in to reveal towns and, deeper still, Cape
Town suburbs. The map picture follows the season with a colour tint.

- Works out of the box with a free default map (OpenStreetMap / CARTO).
- For a nicer outdoors / terrain look add a free key from https://cloud.maptiler.com
  to `env.json` as `MAPTILER_KEY` (optionally `MAP_STYLE`: `outdoor-v2`, `topo-v2`,
  `landscape`, `streets-v2`, `satellite`).
- `tools/gen_places.py` holds the towns by real GPS and writes
  `lib/features/map/places_data.dart`. Place tiers: 1 major city, 2 regional town,
  3 small town, 4 Cape Town suburb, 5 Cape Town neighbourhood.
- Route lines join your races by date (solid red between completed races, dashed green
  once a planned race is involved). They are hidden by default; use the route button on
  the map to show them.

## Layout
```
lib/
  main.dart, core/ (config, season)
  features/
    auth/      login and auth gate
    home/      tabs, menu, add-race button
    map/       map view, places, clustering, race card, season colour grade
    races/     model, repository, store, list, add/edit form
    profile/   profile model/store/repository, edit screen, runner card, stats
supabase/      schema.sql and migrations
tools/         gen_places.py
```

## Roadmap
- [x] Auth and race add / edit / delete / list
- [x] South Africa map with zoom, town labels by zoom level, clusters
- [x] Seasonal colour grade
- [x] Profile and runner card
- [x] Race bucket list
- [x] Photos on a race
- [x] Route lines between consecutive races (completed solid, planned dashed)
- [x] Friends with invite codes and WhatsApp invites
- [x] Share the runner card as an image
- [ ] iOS build (needs a Mac and Apple developer account; add camera and photo
  library permission text to `ios/Runner/Info.plist` for `image_picker`)
