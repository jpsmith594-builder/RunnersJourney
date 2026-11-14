# Medal Wall: spec (13 Nov 2026)

**Status:** phase 1 built (menu > My Medals). Needs `supabase/020_medal_wall.sql` run once in the Supabase SQL editor. Code is in `lib/features/medals/`.

**Friends can see the wall:** run `supabase/021_medal_sharing.sql` once. A switch on the wall ("Friends can see my wall", on by default) controls it; a friend's wall opens read-only from their runner card.


## Summary
A separate menu option opens the "My Medals" wall: a dark purple wall with titanium hanger bars lit from behind by an LED glow. The runner photographs a real medal, the app crops it and hangs it on the wall. Tapping a medal opens the linked race card. The wall delivers the brand line "the medals you've earned" and gives runners something to show and share.

## User flow
1. Menu > Medal wall. Empty state shows an empty bar and an "Add medal" button.
2. Add medal: take a photo (or pick one), with a hint to use a plain surface.
3. Crop: circle crop with pinch and drag. Later: automatic background removal.
4. Link to a race: pick an existing race or create one. Medal inherits name, date and distance.
5. The medal drops onto the next free hook with a short light-up animation.
6. Tap a medal: race card, with options to replace the photo or remove the medal.

## Screens
- **Header:** "My Medals" in bold italic LED letters glowing directly on the wall, with a soft cyan halo. Drawn in code (stacked blurred and sharp text layers), so it stays sharp and costs no image download. See `docs/medal_wall_mockup.png`.
- **Wall:** scrolling column of hanger bars, 3 medals per bar, new bar after every third medal. Titanium bar and screws drawn in code; LED glow is a blurred light behind each bar plus a faint wash on the wall. Ribbon colour is chosen by the user from a small palette; metal (gold, silver, bronze, titanium) follows the user's pick.
- **Add medal:** camera, crop, link-to-race, ribbon colour.
- **Medal detail:** large medal, race card link, replace and remove.
- Dark theme only for this screen, so the LED effect always reads.

## Photo handling
- Phase 1: circle crop of a plain-background photo. Reliable, no machine-learning model.
- Phase 3: on-device background removal (for example ML Kit subject segmentation on Android). Test on shiny metal and ribbons before committing.
- Compress to about 600 px square WebP before upload; cache locally so 40 medals load quickly on low-end phones.
- Photos are user content: include them in the block / report plan used for race photos.

## Data (Supabase)
Table `medals`: id, user_id, race_id (nullable), image_path, ribbon_colour, metal, position, created_at.
Storage bucket `medals` (private, per-user folder). Row-level security: a user can read and write only their own rows and files. Deleting a race keeps the medal unless the user removes it; deleting the account removes all medals and files.

## Free and paid (proposal)
- Free: up to 5 medals (matches the 5 finished races on the free plan).
- Paid: unlimited medals, extra hanger styles, share-image of the wall.
- Read-only after cancellation, same as races.

## Build phases
1. Wall screen, hanger and LED drawing, medals from existing race photos, circle crop, add and link flow.
2. Ribbon and metal choices, light-up animation, share image.
3. Automatic background removal, more hanger styles.
Rough size: phase 1 is a few days of focused work; phase 3 depends on how well segmentation handles medals.

## Risks and open questions
- Messy photos make the wall look worse: mitigated by the plain-surface hint and crop.
- Storage cost grows with medals: mitigated by compression and the free limit.
- Do you want medals without a race (for example a parkrun or a gift medal)? Proposed: yes, race link optional.
- Moderation of uploaded photos to be covered in the block / report feature.
