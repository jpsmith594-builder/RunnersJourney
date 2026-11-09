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
- **South African races** (menu; shown only to runners who look South African: phone set to South Africa, a known South African home town, or a race already there. Formerly "Race calendar", with an "Add a race that is not listed" button) and race search: a starter list of well-known South African races
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
- **Subscriber** (South Africa: R50 a month or R400 a year; everywhere else: $3 a month or $25 a year, set per country in the Play Console): unlimited races, up to 10 photos per race.
- **After cancelling**: when the paid period ends, a runner with more than 5 races keeps all of them,
  but they are read-only (viewing and deleting still work) until they subscribe again or delete down to 5.
- The limits are enforced in the database (`supabase/009_subscriptions.sql`), so the app cannot get
  around them. The app shows a banner ("3 of 5 free races used") and a paywall (menu > Go unlimited).

### Switching it on (one-off setup)

1. **Google Play Console**: create a subscription with two base plans, monthly (R50) and yearly (R400), then add per-country prices: about $3 a month and $25 a year for the rest of the world.
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

## Journey album

Menu > **Journey album** pages through finished races like an old photo album: a cover, one page per race
(photos stuck on with tape, name, date, town, distance, time, pace, position and medal), and a closing page with
totals. Swipe to turn pages, tap the play button to turn them automatically, tap a photo to open it full screen,
share the current page as a picture, and use the filter to pick a year or show only races with photos.

## Runner card rating

The card shows a rating from 0 to 1000 and one of seven categories: Novice (0), Rookie (80), Club runner (180),
Competitor (300), Veteran (450), Master (650) and Elite (850). Points come from finished races (6 each, up to 250),
distance (1 per 8 km, up to 200), towns (4 each, up to 100), medals (gold 10, silver 6, bronze 4, up to 120),
countries (10 each, up to 80) and improvement (up to 250). Improvement compares you with your own past, so it is
fair to every pace: up to 40 points per distance (5, 10, 21, 42 km) for how much your best beats your first time,
plus 10 points each time a season's best at a distance beats all earlier seasons. Elite takes years.

## App icon and name

The icon is drawn by `tools/make_icon.py` into `assets/icon/`. To put it on the phone:

1. `flutter pub get`
2. `dart run flutter_launcher_icons`
3. In `android/app/src/main/AndroidManifest.xml` set `android:label="My Running Journal"` on `<application>`
   and add `<uses-permission android:name="android.permission.INTERNET"/>` above it (release builds need it).
4. Uninstall the old app from the phone, then run again.

## Sending real emails (SMTP)

Supabase's built-in sender only allows a few emails an hour, so confirmation and password-reset emails stop
arriving once more people register. Use your own sender:

1. Get an email provider (Resend, Brevo or similar) and verify a sending domain you own (an address like
   `no-reply@yourdomain.com`). Sending from a gmail.com address is blocked by Gmail's own rules.
2. Supabase > Project Settings > Authentication > SMTP Settings: switch on **Custom SMTP** and fill in sender
   email, sender name ("My Running Journal"), host, port, username and password from the provider.
3. Supabase > Authentication > Emails > Templates: paste `supabase/email-templates/confirm-signup.html`
   into **Confirm signup** and `reset-password.html` into **Reset Password**, and set the subjects
   ("Confirm your email - My Running Journal", "Reset your password - My Running Journal").
4. Authentication > Rate Limits: raise the emails-per-hour limit.
5. Test with a fresh address, and check the spam folder once.

## Privacy policy and account-deletion pages

`docs/` holds three plain web pages: `index.html`, `privacy.html` and `delete-account.html`. Google Play needs the
privacy policy link and a web page that explains account deletion.

1. Replace `CONTACT_EMAIL` with your support address in all three pages
   (`sed -i 's/CONTACT_EMAIL/you@yourdomain.com/g' docs/*.html`).
2. GitHub > the repo > Settings > Pages > Source: **Deploy from a branch**, branch `main`, folder `/docs`.
3. The pages go live at `https://<your-github-name>.github.io/<repo-name>/privacy.html` and `.../delete-account.html`.
   Use those two links in the Play Console (Data safety and the app content section).

## On this day

When a finished race took place on today's date in an earlier year, the home screen shows a memory strip:
"2 years ago today", the race, its distance, time and town, and its first photo (tap to open the photos).
It can be hidden for the session. A 29 February race shows on 28 February in years without a leap day.

## Goals

Menu > **Goals**: set a distance goal (km) and a races goal for the year. Rings fill as finished races are added,
with a hint ("About 12 km a month for the rest of the year", "2 more races to go. 1 already planned."). The page
also shows how many points are left to the next runner-card category and the badge that is closest to being
earned. Once a goal is set a slim progress strip shows on the home screen (the races goal if there is one, otherwise the distance goal). Goals are saved per year in `yearly_goals`, so past years keep their targets: the Goals page lists them
under "Past years" with the result, and early in a new year (January to March) it offers "Keep the same"
or "Choose new". Run `supabase/013_goals.sql` and then `supabase/014_goals_by_year.sql` in the Supabase SQL
editor first.

## Help inside the app

Menu > **Frequently asked questions** (`lib/features/help/faq_screen.dart`) answers the common questions in
five groups: the runner card and rating, the subscription, races/map/photos, friends and privacy, and the account.
When prices, limits or the rating formula change, update the answers there too.

## Planned domain

The app will use **myrunningjournal.co.za** for its email and public pages. Still to do when it is bought: add the
mailboxes (for example `no-reply@` and `support@`), switch the Supabase SMTP settings to them, replace
`CONTACT_EMAIL` in `docs/*.html` with the support address, and update the privacy policy if the company name changes.

## Clubs

The running club on a profile is picked from a shared list, so two runners from the same club end up in the same
club even when one of them mistypes the name. While typing, the Profile edit screen suggests clubs from the list
(with area and member count). If what was typed matches a club once capitals, dots and words like "athletic club"
are ignored, that club is used. If it only looks like a club ("Seapoint Stridrs"), the app asks "Did you mean ...?"
before adding a new one. Anything else is added as a new club.

Run `supabase/015_clubs.sql` in the Supabase SQL editor. It adds the `clubs` table, the search and add functions,
`profiles.club_id`, links existing profiles to clubs, and seeds the Western Province Athletics affiliated club list
(105 clubs, taken from wpa.org.za/wpa-club-list). The other provinces have no public list yet: runners add their
clubs and you can add or merge clubs in the SQL editor. For example, to merge a duplicate:

```sql
update public.profiles set club_id = '<keep id>', club = '<keep name>' where club_id = '<duplicate id>';
delete from public.clubs where id = '<duplicate id>';
```

`supabase/016_clubs_boland.sql` adds the 32 Boland Athletics member clubs (from their published list as at
30 January 2026). Run it after 015. Both files skip clubs that are already in the list.

Until the SQL has been run the club box still works as a plain text box.

`supabase/017_clubs_gauteng_north.sql` adds the Athletics Gauteng North affiliated clubs (190 of the 222 on their
2026 list; school clubs are left out and a few spelling slips are corrected). Run it after 015.

## People from my club

On the Friends screen, **People from my club** has a switch, "Let people from my club find me", off by default.
When both runners have switched it on and are in the same club, they see each other's name and can send a friend
request; races, photos and the runner card stay private until the request is accepted. Changing club switches it
off again. Run `supabase/018_club_mates.sql` in the Supabase SQL editor first.

## Settings and units

Menu > Settings: distances in kilometres or miles, appearance (phone / light / dark), FAQ, and optional support and privacy links (`SUPPORT_EMAIL`, `PRIVACY_URL` in env.json; hidden when empty). The choice is saved on the phone (shared_preferences). Races are always stored in km; `lib/core/units.dart` converts for display, and distances typed in miles snap to standard race distances (6.2 mi = 10 km).

## Welcome tour

Five swipeable screens (map, adding a race, album and year review, runner card, goals and friends) shown once after a runner first opens the app (`tour_seen` in shared_preferences). Replay it from Settings. Text lives in `tourPages` in `lib/features/help/welcome_tour.dart`.

## Offline handling

Network failures show one friendly message ("No internet connection...") instead of raw errors (`lib/core/errors.dart`: `isOffline`, `describeError`, `failMessage`). The races list and map show a Try again button when they cannot load (`lib/core/load_error.dart`). Saving needs a connection; nothing is queued offline yet.

## Crash reporting (Sentry)

Set `SENTRY_DSN` in env.json (create a free Flutter project at sentry.io and copy its DSN). Without it nothing is reported. Reports carry only the error, app version and phone model: no personal details, screenshots or typed text, and offline errors are ignored. The privacy policy lists Sentry; in the Play Console Data safety form declare "Crash logs" and "Diagnostics" as collected, not linked to identity.
