# Play Console declarations: answers for My Running Journal

Drafted from what the app does (Supabase sign-in/database/storage, OpenFreeMap maps, Sentry crash reports, RevenueCat + Google Play subscriptions, no ads, no live GPS). Re-check against the real forms: Google reorders and renames questions. If you add an SDK or a field, update this file and the privacy page together.

## 1. App content > Privacy policy
https://myrunningjournal.co.za/privacy.html

## 2. Data safety form

Top-level questions
- Does your app collect or share any of the required user data types? **Yes**
- Is all of the user data collected by your app encrypted in transit? **Yes** (HTTPS to Supabase, OpenFreeMap, Sentry, RevenueCat)
- Do you provide a way for users to request that their data is deleted? **Yes**
  - In app: Profile > Edit profile > Delete my account
  - Web link to give Play: https://myrunningjournal.co.za/delete-account.html

Data types to declare as COLLECTED (none are "shared" with third parties; Supabase, OpenFreeMap, Sentry and RevenueCat act as service providers processing data on your behalf, which Google does not count as sharing)

| Category > type | What it is | Optional? | Purpose |
|---|---|---|---|
| Personal info > Email address | sign-in | Required | App functionality, Account management |
| Personal info > Name | display name | Optional | App functionality |
| Personal info > User IDs | account ID, subscription ID | Required | App functionality, Account management |
| Personal info > Other info | gender, year of birth (runner card) | Optional | App functionality |
| Location > Approximate location | race towns with map coordinates and optional home town, chosen by the runner (never read from GPS) | Optional | App functionality |
| Health and fitness > Fitness info | race distance, finish time, pace, position | Optional | App functionality |
| Photos and videos > Photos | race photos, medal photos, profile photo | Optional | App functionality |
| App activity > Other user-generated content | race names, notes, bucket list, friend connections, reactions | Optional | App functionality |
| App activity > In-app search history | NOT collected once the build has no MapTiler key: town search runs on the phone from a built-in list and nothing typed leaves the phone. Declare this row only if you ship a build with MAPTILER_KEY set | Optional | App functionality |
| Financial info > Purchase history | subscription status | Optional | App functionality |
| App info and performance > Crash logs | Sentry error reports | Required (if SENTRY_DSN is set) | Analytics (app stability) |
| App info and performance > Diagnostics | app version, phone model, Android version | Required (if SENTRY_DSN is set) | Analytics (app stability) |

Data types to answer NOT collected: Precise location, Contacts, Messages, Audio, Files and docs, Calendar, Web browsing, Device or other IDs, Race and ethnicity, Political or religious beliefs, Sexual orientation, Health info (medical), Financial info other than purchase history.

Judgement calls to be aware of
- Location: the app never reads the phone's GPS, but it stores the town of each race (with coordinates) and an optional home town. Town-level places are declared as Approximate location (collected, not shared, optional, app functionality) to be on the safe side. OpenFreeMap sees the map area and IP address while the map loads (no account, no search text, no key).
- Sentry is only active when SENTRY_DSN is supplied at build time. If you ship without it, remove the two crash/diagnostics rows.
- Showing a runner's profile and races to accepted friends is user-directed, not sharing with third parties.

## 3. Advertising ID
- Does your app use advertising ID? **No.** Before submitting, open the .aab in Play Console's App bundle explorer (or check the merged manifest) and confirm there is no `com.google.android.gms.permission.AD_ID`. If a library adds it, remove it with `tools:node="remove"` in AndroidManifest.xml.

## 4. Ads
- Contains ads? **No**

## 5. Target audience and content
- Target age group: **18 and over** (simplest; the privacy page says the app is not meant for children under 13). If you choose to include teens, Play adds extra Families-policy questions.
- Appeals to children? **No**

## 6. Content rating (IARC questionnaire)
- Category: **Utility, Productivity, Communication or Other** (fitness/journal app)
- Violence, blood, sexual content, nudity, profanity, drugs, alcohol, tobacco, gambling: **No** to all
- Users can interact or share content with each other? **Yes** (friends can see accepted friends' profiles, races, photos and react)
- Shares the user's location with other users? **No**
- Digital purchases? **Yes** (subscriptions)
- Unrestricted web access? **No**
- Expected result: Everyone (with an "Users interact" note)

## 7. App access
- All or some functionality is restricted: **Yes** (sign-in needed)
- Create a reviewer account first (email + password), add a few races and a photo, and paste the credentials and a one-line note into Play Console > App content > App access.

## 8. Other declarations
- Government app: No. News app: No. Financial features: No. COVID-19 app: No.
- Health apps declaration: it is a race journal, not a medical or health-monitoring app. Choose the option that says it has no health features, or "activity and fitness" only if the form insists, and do not claim medical features.
- Category: Health & Fitness
- Subscriptions: describe the benefit (unlimited races, 10 photos per race), prices and cancellation in the store listing and in the in-app paywall.

## 9. Before the first upload
- Upload as Internal testing first, add your testers' Google Play emails, check the install link works.
- Production needs the store listing (PLAY_LISTING.md) and every item above complete.
