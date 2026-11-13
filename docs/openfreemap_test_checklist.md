# OpenFreeMap: phone test checklist (phase 5)

OpenFreeMap is now the default map. Test on your Samsung, and on an older or slower phone if you can borrow one.
Build without MAPTILER_KEY first (remove it from env.json), because that is how the release will be.

## Every phone
- [ ] Fresh install: Journey tab opens on the OpenFreeMap map with your pins, no setting changed.
- [ ] Pins and trail follow the map with no lag while panning and zooming.
- [ ] Tap a pin: race card opens. Tap elsewhere: card closes. Pan the town off screen: card closes.
- [ ] Zoom out to the whole world, then in to a street. Towns appear and fan out as you zoom.
- [ ] Add race button: the town search finds a big town, a small SA town (try Hilton, Pinetown, Botha's Hill) and an overseas town. No internet is needed for this.
- [ ] Seasons and the Vivid switch change the map colours. Light and dark phone themes both look right.
- [ ] Credit line "OpenFreeMap..." is visible and does not cover the Add race button.
- [ ] Leave the Journey tab and come back several times: map still draws.
- [ ] Rotate the phone and switch apps and back: map and pins survive.

## No network
- [ ] Airplane mode, open Journey: within about 12 seconds a "The map is taking a while to load" message with "Try again" appears (new in this build).
- [ ] Switch network back on, press "Try again": map loads, pins return.
- [ ] Open a place you already viewed, then go offline: the cached map area still shows.

## Weak or slow signal
- [ ] Switch to mobile data only with a poor signal: map eventually loads, no crash.

## Long session
- [ ] Use the map for 10 minutes, panning and zooming around the world. No slowdown, no crash, memory looks stable.

## Low-end phone
- [ ] Pins stay smooth with 20 or more races. Map pan does not stutter badly.

## Fallback
- [ ] Hidden screen (long-press the version line in Settings > Journey: OFM off) still shows the old map, in case a problem is found.

Report anything that fails with the phone model, Android version, and whether it was Wi-Fi or mobile data.
