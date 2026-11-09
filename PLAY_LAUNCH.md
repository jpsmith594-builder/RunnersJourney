# Play Console and subscriptions: launch checklist

Work top to bottom. Items marked [CONFIRM] are details Google changes often; check the linked page before relying on them.

## 0. Decide the account type first

| | Personal account | Organisation account (e.g. Sustainovate) |
|---|---|---|
| Needs | ID, address verification | Registered company, D-U-N-S number, website, company email |
| Closed-test rule | At least 12 testers opted in for 14 days in a row before you can apply for production ([Google's rule](https://support.google.com/googleplay/android-developer/answer/14151465)) | Google's page does not say organisations are exempt; it is widely reported that they are [CONFIRM] |
| Store name shown | Your own name | Company name |
| Later transfer | Possible but fiddly | Easier to keep the app with the company |

Either way the one-off registration fee is about US$25 [CONFIRM]. If you plan to run the app under Sustainovate, register the organisation account now so the app never needs to move. Getting a D-U-N-S number is free but can take days to weeks, so start it today.

## 1. Before you upload anything (in the project)

1. **Application ID**: pick the final one (for example `za.co.myrunningjournal.app`) in `android/app/build.gradle`. It can never change after publishing.
2. **App name and icon**: label "My Running Journal" in `AndroidManifest.xml`; run `dart run flutter_launcher_icons`.
3. **Internet permission** in `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.INTERNET"/>`.
4. **minSdk**: set `minSdk = 24` if the build complains (RevenueCat).
5. **Upload key** (keep it safe; back it up outside the project and never commit it):
   `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   Create `android/key.properties` (add it to `.gitignore`) with `storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile=<path>`, then point the `release` signing config in `build.gradle` at it. Play App Signing (on by default) keeps the real signing key, so losing the upload key is recoverable by Google support, losing it silently is still painful.
6. **Version**: in `pubspec.yaml` `version: 1.0.0+1`. The number after `+` must go up for every upload.
7. **Build**: `flutter build appbundle --release --dart-define-from-file=env.json` gives `build/app/outputs/bundle/release/app-release.aab`.
8. Make sure `env.json` has the Supabase keys, `REVENUECAT_KEY`, `SENTRY_DSN`, `PRIVACY_URL` and `SUPPORT_EMAIL` before building.
9. Publish `docs/` (GitHub Pages or your domain) so the privacy policy and delete-account pages are live, with `CONTACT_EMAIL` replaced.

## 2. Create the app in the Play Console

1. All apps > Create app. Name, default language, App (not game), Free (the subscription is an in-app product).
2. **Set up your app** tasks (Dashboard), each must be completed:
   - Privacy policy URL: `https://.../privacy.html`
   - App access: login is needed, so give Google a test account (email and password) and say the app needs sign-in.
   - Ads: No ads.
   - Content rating: fill the questionnaire (no violence, no user-to-user chat; users can see friends' profiles and photos, answer that honestly).
   - Target audience: 18 and over is the simplest (the privacy policy says the same).
   - Data safety (use the table in section 6).
   - Account deletion: link `.../delete-account.html` and say it can also be done inside the app.
   - Government / financial / health declarations: none of these apply [CONFIRM the health apps form: tick "no" unless Google asks; the app logs races, not medical data].
   - Category: Health and fitness. Contact email and website are public.
3. **Store listing**: short description (80 characters), full description, app icon 512x512, feature graphic 1024x500, at least 2 phone screenshots (take them from the app with a few races filled in; use the Journey map, album, runner card and year review).

## 3. Subscriptions in Play

1. Monetize > Products > Subscriptions. You need a payments profile and, for paid products, a merchant account [CONFIRM South African tax and bank details].
2. Create one subscription, product ID `pro`, name "My Running Journal Unlimited".
3. Add two base plans (auto-renewing):
   - `monthly`, billing period 1 month
   - `yearly`, billing period 1 year
4. Prices: set South Africa to **R50** and **R400**. Set every other country to **US$3** and **US$25** (the console converts to each currency, check the rounding and edit any odd ones). Do the default first and then "Update prices" per country.
5. Optional: add an offer (for example a 7-day free trial) once you are happy with the basics. Free trials are the biggest conversion lever, but wait until after the first test.
6. Activate both base plans. A subscription can only be activated once the app (with the billing library) has been uploaded to a track, so upload your first build (section 4) before activating if the console blocks you.
7. Google's service fee on subscriptions is about 15% [CONFIRM current rate].

## 4. Upload and test (this also starts the 14-day clock)

1. Testing > **Internal testing**: create a release, upload the `.aab`, add yourself and family as testers by email. Install through the opt-in link. This is the only way to test real purchases (they use the Play store, not a sideloaded APK).
2. Setup > **License testing**: add the same Gmail addresses so test purchases are free and renew every few minutes.
3. Testing > **Closed testing**: create a track, upload the build, add at least 12 testers (a Google Group or an email list). Each must opt in through the link and stay opted in for 14 days. Ask running-club friends; more than 12 is safer because people drop out [CONFIRM current numbers on the account page].
4. After 14 days: Dashboard > **Apply for production**, answer the questions (how testing went, what you changed), and wait for review. Reviews can take several days.

## 5. RevenueCat (connects Play to the app)

1. Create a free project at revenuecat.com, add an **Android app** with your package name.
2. Link Play: RevenueCat shows steps to create a **Google Cloud service account**, give it access in Play Console (Users and permissions > Invite new user, with view financial data and manage orders and subscriptions), and upload its JSON key. Enable the Google Play Developer API in the same Cloud project. Also set up the Pub/Sub topic RevenueCat tells you to, for real-time notifications. Credentials can take up to a few hours to start working.
3. Products: import `pro:monthly` and `pro:yearly` (RevenueCat reads them from Play).
4. Entitlement named **`pro`**: attach both products.
5. Offering **default**, marked current, with a Monthly package (`$rc_monthly`) and Annual package (`$rc_annual`). The app reads `offerings.current.monthly` and `.annual`, so these must be the standard package types.
6. Copy the **public Android SDK key** (starts with `goog_`) into `env.json` as `REVENUECAT_KEY` and rebuild.
7. Webhook:
   `supabase secrets set REVENUECAT_WEBHOOK_SECRET=<long random string>`
   `supabase functions deploy revenuecat-webhook --no-verify-jwt`
   RevenueCat > Project settings > Integrations > Webhooks: URL `https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook`, Authorization header = the same secret. Send a test event from RevenueCat and check the `subscriptions` table.
8. Make sure SQL files 009 and 010 have been run in Supabase.

## 6. Data safety answers (match the privacy policy)

| Data | Collected | Shared | Purpose | Optional |
|---|---|---|---|---|
| Email address | Yes | No | Account management | No |
| Name (display name) | Yes | Only with friends you accept | App functionality | Yes |
| Photos | Yes | Only with friends you accept | App functionality | Yes |
| Approximate location (race towns you type, not GPS) | Yes | No | App functionality | Yes |
| Other in-app content (races, notes, goals, bucket list) | Yes | Friends only | App functionality | Yes |
| Purchase history | Yes (via RevenueCat/Google) | RevenueCat as a service provider | Account/subscription | Yes |
| Crash logs and diagnostics | Yes | Sentry as a service provider | Analytics (stability) | No |

Also tick: data is encrypted in transit; users can request deletion (give the delete-account URL).
Because the app never reads GPS, do not declare precise location.

## 7. Release day

1. Production > create release > upload the same tested bundle (or a newer one) > roll out. Start at 100% only if the closed test went smoothly; otherwise stage at 20%.
2. Check Sentry and Supabase after the first few installs.
3. Reply to Play reviews; they feed ranking.

## Typical delays

- Developer identity verification: days.
- D-U-N-S (organisation): days to weeks.
- Closed test: 14 days minimum.
- Production review: a few days, sometimes more for a first app.

Plan roughly 4 to 6 weeks from today to a public listing.
