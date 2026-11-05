# My Running Journal

A runner's life diary. Races are pinned on a world map,
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
- **Journey tab**: the real world map. The town box searches any town in the world (needs the MapTiler key); South African towns also work without it
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
- **South African races** (menu, formerly "Race calendar", with an "Add a race that is not listed" button) and race search: a starter list of well-known South African races
  (Comrades, Two Oceans, Cape Town Marathon, Soweto...) with usual timing. Add one to your plan or
  bucket list in a tap, or just start typing a race name in the race form and the town and
  distance fill in. The list lives in `lib/features/calendar/race_event.dart`; dates change every
  year so check the official site
- **Year in review** (menu): a shareable poster of your year: races, km, time racing, towns and
  provinces, longest race, fastest pace, busiest month and personal bests
- **Badges** (menu): 24 crests (bronze, silver, gold, platinum, titanium) with brushed-metal frames, light sweeps and stars for difficulty; locked ones are grey with progress.
  Badges for races finished, distance, firsts (10K, half, marathon,
  ultra), sub-60 10K / sub-2 half / sub-4 marathon, towns, provinces/states, countries (Border crosser, Globetrotter), Comrades, Two Oceans
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
   `supabase/004_gender_age.sql`, `supabase/005_bucket_list.sql`, `supabase/006_friends.sql`, `supabase/007_reactions.sql`, `supabase/008_places_global.sql`, `supabase/009_subscriptions.sql`, `supabase/010_account_types.sql`, `supabase/011_medals.sql`, `supabase/012_delete_account.sql` (003 adds the profile columns and the private `avatars`
   photo bucket; 004 adds gender and age, 005 adds the bucket list, 006 adds friends, 007 adds reactions, 008 adds region and country to races and coordinates to the bucket list, 009 adds subscriptions and the free-plan limits)
2. In the repo folder: `flutter create . --project-name runners_journey --org com.runnersjourney --platforms=android`
   (generates `android/`; your `lib/` and `pubspec.yaml` are kept. Restore any file
   it overwrites with `git restore <file>` and delete `test/widget_test.dart`)
3. `flutter pub get`
4. Copy `env.example.json` to `env.json` and fill in your Supabase URL and anon/publishable
   key (`env.json` is gitignored)
5. `flutter run --dart-define-from-file=env.json`

## The map
A real, zoomable world map (flutter_map) with your pins and race cards. Zoom in to reveal towns and, deeper still, Cape
Town suburbs. The map picture follows the season with a colour tint.

- Works out of the box with a free default map (OpenStreetMap / CARTO).
- For a nicer outdoors / terrain look add a free key from https://cloud.maptiler.com
  to `env.json` as `MAPTILER_KEY` (optionally `MAP_STYLE`: `outdoor-v2`, `topo-v2`,
  `landscape`, `streets-v2`, `satellite`).
- `tools/gen_places.py` holds the towns by real GPS and writes
  `lib/features/map/places_data.dart`. Place tiers: 1 major city, 2 regional town,
  3 small town, 4 Cape Town suburb, 5 Cape Town neighbourhood.

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

## Subscription (free plan and "Go unlimited")

- **Free**: up to 5 finished races (completed, DNF or DNS), 1 photo per race. Planned races and the
  bucket list are always free.
- **Subscriber** (R30 a month or R250 a year): unlimited races, up to 10 photos per race.
- **After cancelling**: when the paid period ends, a runner with more than 5 races keeps all of them,
  but they are read-only (viewing and deleting still work) until they subscribe again or delete down to 5.
- The limits are enforced in the database (`supabase/009_subscriptions.sql`), so the app cannot get
  around them. The app shows a banner ("3 of 5 free races used") and a paywall (menu > Go unlimited).

### Switching it on (one-off setup)

1. **Google Play Console**: create a subscription with two base plans, monthly (R30) and yearly (R250).
   Subscriptions need a Play developer account and the app uploaded to a testing track.
2. **RevenueCat** (free until you earn over about $2.5k a month): create a project, add the Android app,
   connect it to Google Play, create an entitlement called `pro`, an offering marked as *current* with a
   monthly package and an annual package. Copy the public Android SDK key into `env.json` as `REVENUECAT_KEY`.
3. **Webhook**: deploy `supabase/functions/revenuecat-webhook` (the commands are at the top of the file) and
   point RevenueCat's webhook at it. It writes the `subscriptions` table that the limits read.
4. If the Android build complains about the SDK version, set `minSdk = 24` in `android/app/build.gradle`.

To test without paying, give yourself a subscription in the Supabase SQL editor (see the bottom of
`supabase/009_subscriptions.sql`).

## Email confirmation link (opens the app)

By default Supabase sends the confirmation link to `http://localhost:3000`, which fails on a phone
("this site can't be reached"). The app now asks for `io.runnersjourney.app://login-callback/` instead:

1. Supabase > Authentication > URL Configuration: set **Site URL** to `io.runnersjourney.app://login-callback/`
   and add the same value under **Redirect URLs**.
2. In `android/app/src/main/AndroidManifest.xml`, inside the `<activity android:name=".MainActivity" ...>` tag
   (next to the existing `<intent-filter>`), add:

   ```xml
   <intent-filter>
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="io.runnersjourney.app" android:host="login-callback" />
   </intent-filter>
   ```

Tapping the link in the email then opens the app and signs the runner in.

## Account types

`profiles.account_type` is `free` (default), `premium` (unlimited, given by hand) or `admin` (the creator, unlimited).
Paid subscribers stay `free` here and get access from the `subscriptions` table. Runners cannot change their own
type (a database trigger blocks it); you set it in the Supabase SQL editor:

```sql
update public.profiles set account_type = 'admin'
where id = (select id from auth.users where email = 'YOUR-EMAIL');
```

## Look and feel

Samsung Health style: a soft grey canvas with big rounded white cards (`lib/core/tiles.dart`: `SoftCard`,
`IconBubble`, `StatTile`, `RingProgress`, `SectionTitle`), light app bars with bold titles, and a white
navigation bar. The Races tab opens with summary tiles (races run, distance, time racing, next race) above
a card per race. The Badges screen leads with a progress ring.

## Charts (menu)

Four chart cards: races per year (bars), medals collected (donut: gold, silver, bronze, set on each finished race), average pace per year (line) and
kilometres per year (horizontal bars). They are drawn by hand (no chart package) in `charts_screen.dart`.

## Password reset and deleting an account

- **Forgot password?** (login screen): sends a reset email. The link opens the app (same deep link as the
  confirmation email, see above) and asks for a new password. Make sure
  `io.runnersjourney.app://login-callback/` is in Supabase > Authentication > URL Configuration > Redirect URLs.
- **Delete my account** (Profile > Edit profile, bottom): asks the runner to type DELETE, removes their photo
  files, then calls `delete_my_account()` (`supabase/012_delete_account.sql`), which deletes the auth user and
  everything that cascades from it. Google Play also wants a web page that explains how to delete an account;
  that goes with the privacy policy.

## Sharing the runner card

The card is drawn on a tall 9:16 "story" stage and shared as a 1080 x 1920 PNG through the phone's share sheet,
so it fits Instagram and Facebook Stories, WhatsApp Status and TikTok. Direct per-app buttons were left out on
purpose: they need a Meta developer app, a restricted storage permission and TikTok approval.
