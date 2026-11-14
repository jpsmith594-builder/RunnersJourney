# Growth: club codes, friend codes, referral credit, earned slots

Status: built (database, app screens, webhook). Needs Play Console offers and a
few manual steps (see "Set-up" and "Running it").

## Goals
Bring in subscribers through running clubs and friends, reward the people who
help, and keep the rules simple enough to explain in one line each.

## The rules

**Club code** (made by you, handed to a club contact)
- New subscribers get **15% off the first year** of the yearly plan. After 12
  months the price returns to normal (R499 / $25).
- The club contact earns **a free year at 10 paid sign-ups**, and another free
  year at 25.

**Friend (referral) code** (every runner has one, free users included)
- New subscribers get **10% off the first year** of the yearly plan.
- The code owner earns **free subscription time** by the number of paid
  referrals (see ladder). Credit is added to the next renewal, or to their
  first subscription if they are still on the free plan.
- The owner also earns **free-plan race slots**: +1 for every friend who joins
  with the code and adds a finished race, up to +5.

**One code only.** A runner can use one code, ever, club or friend. Codes are
for new subscribers only (anyone who has had a plan before is rejected). A
runner cannot use their own code.

### Referral ladder
| Paid referrals | Free time | About |
|---|---|---|
| 3 | 1 month | 10% |
| 5 | 2 months | 15% |
| 10 | 3 months | 25% |
| 20 | 4 months | 35% |
| 30 | 6 months | 50% |

- A referral counts once the new subscriber has kept the subscription **30
  days** and has not been refunded.
- Credit is **free months added to the renewal** (Google Play cannot give one
  subscriber a custom price). The months are the equivalent of the percentage.
- After credit is applied, the count restarts for the next cycle.

## How it works

Database (`supabase/022_growth_codes.sql`)
- `promo_codes` (club and referral codes), `code_redemptions` (one per runner),
  `credit_grants` (free months earned), `referral_cycle`.
- Runner functions: `my_referral_code()`, `redeem_code(code)`,
  `referral_summary()`, `bonus_slots(uid)`.
- The race-limit trigger now allows `5 + bonus_slots`.
- Admin functions (SQL editor only): `create_club_code`, `sync_all_rewards`,
  `mark_credits_applied`, views `admin_code_stats`, `admin_credits_to_apply`.

Webhook (`supabase/functions/revenuecat-webhook`)
- On the first purchase it stamps `purchased_at` on the runner's redemption.
- A refund (cancel reason CUSTOMER_SUPPORT) marks the redemption voided.

App
- Paywall: "Have a club or friend code?" opens the code screen. An applied code
  shows on the paywall and the yearly purchase uses the matching Play offer.
- Menu > "Invite and earn": own code, copy/share, slots earned, progress up the
  ladder, credit waiting.
- Home notice and limits use `5 + earned slots`.

## Set-up (once)

1. Run `supabase/022_growth_codes.sql` in the Supabase SQL editor.
2. Redeploy the webhook: `supabase functions deploy revenuecat-webhook --no-verify-jwt`.
3. Play Console > Monetise > Subscriptions > yearly subscription > base plan >
   **Add offer** (twice):
   - Offer 1: tag **`club15`**. Eligibility: *Developer determined*. Phase: one
     billing period (1 year) at 15% off the base price, then the normal price.
   - Offer 2: tag **`ref10`**. Same, with 10% off.
   Set regional prices so rand and dollar prices match the percentage (about
   R424 for 15% off and R449 for 10% off R499, entered before VAT in the Console). Activate both offers.
4. In RevenueCat the yearly package already points at the same product; the app
   picks the offer by its tag.
5. Optional: schedule `select public.sync_all_rewards()` nightly with pg_cron
   (the line is at the bottom of the SQL file).

## Running it

Create a club code:

    select public.create_club_code('CLUB-BELLVILLE', 'Bellville Runners', 'contact@club.co.za', 'met at the AGM');

See how codes are doing:

    select * from public.admin_code_stats;

Pay out earned credit (do this weekly):
1. `select public.sync_all_rewards();`
2. `select * from public.admin_credits_to_apply;`
3. For each row, extend that runner's subscription by the months shown. In
   RevenueCat open the customer and use **Defer billing** (Google Play
   subscriptions), or the Play Console customer tools.
4. `select public.mark_credits_applied('<user id>');`
   If the person is not subscribed yet, leave the row; apply it when they
   subscribe.
   If the club contact has no account yet, the row has only their email and
   `user_id` stays empty; it fills in on the next `sync_all_rewards()` after
   they sign up with that email.

Automating step 3 later: RevenueCat has a REST call to defer a Google
subscription; an Edge Function could do it from `admin_credits_to_apply`.

## Test checklist
- Make a club code, redeem it in a second account, see 15% off on the paywall.
- Try a second code in that account: "only one code".
- Try your own referral code: "cannot use your own code".
- Subscribe with a test card/licence tester; `code_redemptions.purchased_at`
  should fill in.
- A friend using your code and adding one finished race gives you +1 slot
  (Invite and earn, and the home notice limit).
- Backdate `purchased_at` by 31 days in the SQL editor to see a referral
  qualify and credit appear.

## Notes and limits
- Earned slots can shrink if a friend deletes all their races. Races already
  added are never removed; the account becomes read-only above the limit until
  it is back under or subscribed.
- Google Play's share is unchanged; discounts come out of your side.
- The Play offer eligibility is app-controlled (the app only offers a tag once
  a code was accepted). A determined user could not buy an offer without a
  valid redemption in our database only if you later add a server check; for
  launch this is accepted.
- Win-back, gifting and race-organiser codes are not built.
