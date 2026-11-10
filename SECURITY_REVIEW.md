# Security and quality review: My Running Journal

Date: 10 November 2026. Method: a read-through of the whole repository (app code, Supabase SQL, the RevenueCat webhook, the website) plus a check against the OWASP Mobile Application Security Verification Standard (MASVS v2), the OWASP Mobile Top 10, Google Play requirements, WCAG 2.2 and the privacy laws that apply (POPIA, GDPR).

Limits: this was a source review. I could not run the app, attack the live Supabase project, scan the signed .aab, or see the Android manifest (the android/ folder is not in the repository). Items marked CHECK need you to look at the real thing.

## Findings

| # | Severity | Finding | Status |
|---|---|---|---|
| 1 | High | A runner who had been sent a friend request could rewrite any column of that request (for example set the requester to someone else) and become "friends" with that person, which opens their profile and races | Fixed in 019 (accept-only policy plus a guard trigger) |
| 2 | Medium | Uploaded photos had no size or type limit on the server, and a file could be uploaded without a matching photo record, so the free limit of one photo per race and storage costs could be bypassed | Fixed in 019 (5 MB / 3 MB, JPEG and PNG only) and in the app (a refused record now removes the uploaded file) |
| 3 | Medium | Friend codes are 6 characters with no limit on guesses, and the add-friend call also worked without signing in, so anyone could test codes | Fixed in 019 (sign-in required, 20 tries an hour). Longer codes still recommended, see below |
| 4 | Medium | The Supabase sign-in session is stored unencrypted in the app's private storage, and Android may include it in cloud backups | CHECK / your action: set `android:allowBackup="false"` in AndroidManifest.xml |
| 5 | Medium | The deep link `io.runnersjourney.app://login-callback` is a custom scheme; another app can register the same scheme and intercept a sign-in link | Partly mitigated if PKCE is on (supabase_flutter uses it by default). Recommend Android App Links later |
| 6 | Low | Photo records could point at another runner's race, using up that race's photo limit | Fixed in 019 |
| 7 | Low | Helper functions (are_friends, is_subscriber and others) could be called by anonymous users or used to ask about strangers | Fixed in 019 (revoked from anonymous, are_friends only answers for the caller) |
| 8 | Low | The RevenueCat webhook compared the secret with `!==`, returned database error text, and does not guard against events arriving out of order | Secret comparison and errors fixed. Event ordering still open, see below |
| 9 | Low | Minimum password length was 6 | Raised to 8 for new passwords (sign-in unchanged). Also set the same minimum in Supabase |
| 10 | Low | No limits on text length in the database | Fixed in 019 (checks apply to new and changed rows) |
| 11 | Low | The .gitignore did not list signing keys | Fixed: key.properties, *.jks, *.keystore, *.pem, *.p12 added |
| 12 | Info | The MapTiler key ships inside the app and can be extracted. The Supabase anon key and the RevenueCat public key are meant to be public | Your action: restrict the MapTiler key and watch usage |
| 13 | Info | Photo and profile data are safe from other runners: row-level security is on every table and photos use private storage with short-lived links | Good |

What is already good: row-level security on every table; the free-plan limits and race limits are enforced on the server, not only in the app; `account_type` is protected from self-promotion; all SQL functions set `search_path`; the account deletion function is restricted to signed-in users; Sentry sends no personal details or screenshots; there are no ads or trackers; no secrets are committed; HTTPS everywhere.

## Your actions

1. Run `supabase/019_security_hardening.sql` in the Supabase SQL editor (safe to repeat). Then test: add a friend by code, accept a request, upload a photo.
2. Supabase dashboard, Authentication: set minimum password length to 8 and turn on leaked-password protection if your plan offers it; keep email confirmation on; check rate limits.
3. Redeploy the webhook: `supabase functions deploy revenuecat-webhook --no-verify-jwt`.
4. In `android/app/src/main/AndroidManifest.xml` set `android:allowBackup="false"` on the `<application>` tag (and confirm `android:debuggable` is not set). Rebuild.
5. Build releases with `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` and keep the symbols folder (upload it to Sentry so crashes stay readable).
6. Restrict the MapTiler key in the MapTiler account and set a usage alert.
7. After uploading, open the Play Console pre-launch report and fix anything it flags.
8. Back up `upload-keystore.jks` and `key.properties` somewhere private and offline.

## Open items and recommendations

- Block and report: runners can send friend requests and react to each other's races with no way to block or report a person. Apple's App Store rules for apps with user content (guideline 1.2) expect this, and Play's user-generated content policy points the same way. Recommend a Block button (removes the friendship and stops requests) and a Report option that emails support. Plan this before the iOS release.
- Friend codes: 6 characters give about 16 million combinations. With the new limit, guessing is impractical, but longer codes (8 to 10 characters) for new users would be better. Existing codes should keep working.
- Webhook ordering: events can arrive out of order, so an old renewal could overwrite a newer expiry. Store the event timestamp and ignore older ones. Also handle refund and billing-issue events.
- Orphan files: if account deletion fails halfway, photo files can remain. A scheduled clean-up job (or a server-side deletion function) would close this.
- Privacy page: it says photos are visible to accepted friends, but the database only lets friends see profiles, races and profile photos, not race photos. Correct the wording or add the feature on purpose.
- Account enumeration: sign-in and sign-up messages come straight from Supabase. Keep sign-up and password-reset messages generic.
- Android App Links: replace the custom scheme with a verified https link on myrunningjournal.co.za.
- Website: add security headers in .htaccess (Strict-Transport-Security, X-Content-Type-Options, Referrer-Policy, a basic Content-Security-Policy). Google Fonts are loaded from Google, which is a small privacy point worth a line in the policy, or the fonts could be hosted on your own site.
- Email: check SPF, DKIM and DMARC records for myrunningjournal.co.za so sign-in emails reach inboxes.

## Against the benchmarks

| Benchmark | Result |
|---|---|
| OWASP MASVS: Storage | Partial. Session in plain app storage and backup not disabled (finding 4) |
| MASVS: Crypto | Pass. No custom cryptography; platform and TLS only |
| MASVS: Auth | Mostly pass. Server-side checks, email confirmation; raise password minimum (done), turn on leak protection |
| MASVS: Network | Pass. HTTPS only, no custom certificate handling. Certificate pinning is optional and not recommended for this app |
| MASVS: Platform | Partial. Custom-scheme deep link (finding 5); no exported components visible, CHECK manifest |
| MASVS: Code | Partial. Add obfuscation flags; keep dependencies updated |
| MASVS: Resilience | Not a goal for this app type; no root checks needed |
| MASVS: Privacy | Good. Minimal data, delete-account, no tracking. Fix privacy page photo wording |
| OWASP Mobile Top 10 (2024) | M1 credentials: ok. M3 authentication: ok. M5 network: ok. M8 misconfiguration: backup flag. M9 data storage: see MASVS Storage |
| Google Play | Meets the policy basics: privacy policy, account deletion, no ads. Check the current target API level requirement in Play Console before upload |
| Apple App Store (later) | Needs block/report (1.2), account deletion (have it), subscriptions via in-app purchase (have it) |
| WCAG 2.2 / Android accessibility | Weak. There are no Semantics labels in the app, so a screen reader cannot read the map pins, the runner card or the charts. Add labels to the pins ("Race name, date, medal"), the card and the charts; keep touch targets at 48 dp; test large text |
| POPIA / GDPR | Good basis: purpose, minimisation, deletion, contact. Add a named information officer and a contact for complaints, and a data retention line for Sentry |
| Website | Good basics (HTTPS, lang attribute, viewport, canonical, sitemap). Add security headers and an image alt for the logo or mark it decorative |
