# Today (22-09-2026) change log — map follow, rotation fix, UI

## A) Splash / app launch experience (NEW today)

User-visible change: splash is now pure white with the new icon centered, held
for minimum 2 seconds (can extend while init completes). Then a circular reveal
from center transitions directly into the app. Permissions screen (if shown) is
white, and may show the same logo smaller.

Files involved: `lib/screens/splash_screen.dart`

Regression risks to test: cold start (white screen shows immediately, logo
visible ≥2s); circular reveal doesn't flash black, doesn't double-navigate;
permissions flow appears correctly and doesn't show a second conflicting logo.

Rollback scope: reverting only `splash_screen.dart` reverts all splash changes.

## B) Auth screen UI — login + create account (NEW today)

User-visible change: the black "Welcome to Taligo" top block/header is removed
completely. Screen is now white from top to bottom. Status bar icons adjusted
for white background. App logo appended at the bottom of both login and
register flows.

Files involved: `lib/screens/auth_screen.dart`

Regression risks to test: keyboard/scroll behavior still correct (especially
register form); no overflow in Arabic; all validation + login/register actions
still behave exactly the same.

Rollback scope: reverting only `auth_screen.dart` reverts auth UI changes.

## C) Driver screens — UI overlay redesign (NEW today)

User-visible change (both driver nav-to-pickup and active ride): map is
dominant; overlays are compact — small top status pill; compact floating
destination/pickup card (address + live ETA/distance); side-by-side compact
actions (not stacked big buttons); buttons restyled to modern ride-hailing
patterns (outlined Navigate, destructive Complete etc.). No large old bottom
sheet.

Files involved: `lib/screens/driver_active_ride_screen.dart`,
`lib/screens/driver_navigation_to_rider_screen.dart`

Regression risks to test: buttons still trigger the exact same actions as
before (Start/Complete/Cash/Waiting branches preserved); swipe safety still
present (no accidental completes); on small screens (320px) the overlay
doesn't cover route too much; Arabic text does not overflow.

Rollback note (important): these files now also contain camera-follow logic
and rotation gating (see sections E/F), so reverting the whole file rolls back
multiple features at once. Use patch/hunk rollback if you need only one piece
reverted.

## D) Rider screens — UI changes / removals (NEW today)

1) Rider active ride UI cleanup — upper ETA/progress/destination card area
removed (and "download" button removed). Lower live ETA remains. File:
`lib/screens/rider_active_ride_screen.dart`. Regression risks: rider still
sees essential trip info (ETA, destination) somewhere; no missing action that
riders relied on (download/share/receipt etc.).

2) Rider dropoff location behavior change — no auto-zoom on entry. Details
fit is preserved but done once post-frame (`_pendingReviewFit`), not a
continuous auto-shift. File: `lib/screens/rider_dropoff_location_screen.dart`.
Regression risks: entering screen doesn't jump camera unexpectedly; the
one-time fit happens reliably and doesn't block user panning. Rollback:
reverting only `rider_dropoff_location_screen.dart` restores yesterday's
behavior.

## E) Map camera-follow behavior — Uber-like framing + 30s silent resume (NEW today)

Rider camera-follow (2 files): tracking (driver→pickup) follows framing
driver+pickup; user pan pauses; recenter appears; 30s idle resumes silently.
Active ride (→drop-off): same behavior added (previously had no follow).
Files: `lib/screens/rider_tracking_screen.dart`,
`lib/screens/rider_active_ride_screen.dart`. Special note to test: tracking
reconnect behavior still refits unconditionally after reconnect (can be
surprising even if user had paused follow). This is intentional but test it so
you're aware.

Driver camera-follow (2 files): nav-to-rider now follows driver+pickup; pause
on gesture; 30s silent resume; recenter FAB shown when paused; no camera moves
during Arrived overlay. Driver active ride now initially frames
driver+destination (changed from destination-only), then follows similarly;
existing my_location FAB still toggles marker visibility; recenter FAB
distinct. Files: `lib/screens/driver_navigation_to_rider_screen.dart`,
`lib/screens/driver_active_ride_screen.dart`.

## F) Car marker snap-rotation fix (NEW today)

User-visible change: marker no longer briefly snaps north/up for a millisecond
when the driver stops or when duplicate points arrive. Implemented via a
movement gate: only update heading/rotation when moved ≥ 3 meters; otherwise
keep last heading. Expected side-effect (not a bug): in very slow crawl
(<3m per tick), rotation may hold slightly longer; it should not snap
incorrectly.

Files involved (8 files): `lib/screens/rider_tracking_screen.dart`,
`lib/screens/rider_active_ride_screen.dart`,
`lib/screens/rider_home_screen.dart`,
`lib/screens/rider_pickup_location_screen.dart`,
`lib/screens/rider_dropoff_location_screen.dart`,
`lib/screens/driver_home_screen.dart`,
`lib/screens/driver_navigation_to_rider_screen.dart`,
`lib/screens/driver_active_ride_screen.dart`

## G) Marker size consistency (minor visual change)

Two screens changed car marker asset load size from 48 to 64 for consistency.
Files: `lib/screens/rider_active_ride_screen.dart`,
`lib/screens/rider_tracking_screen.dart`. Rollback is literally those two lines.

## H) Asset changes (NEW today)

Car marker asset replaced (`assets/images/car_marker.png`) with a
transparent, near-square padded marker, still facing DOWN — compatible with
the kept +180 normalization (no code change needed for orientation). Old
`assets/images/app_icon.png` deleted; new icon present.

## Critical rollback guidance

Mixed-feature files (whole-file revert loses multiple features):
`rider_tracking_screen.dart` (follow + rotation gate + marker size),
`rider_active_ride_screen.dart` (follow + rotation gate + UI removals + marker
size), `driver_active_ride_screen.dart` (UI redesign + driver follow +
rotation gate), `driver_navigation_to_rider_screen.dart` (UI redesign +
driver follow + rotation gate). Safe method: export a patch first
(`git diff <file> > <file>.patch`); for rotation-only revert use
`git checkout -p -- <file>` (interactive hunk revert).

Rotation-only clean files: `driver_home_screen.dart`,
`rider_home_screen.dart`, `rider_pickup_location_screen.dart`,
`rider_dropoff_location_screen.dart`.

## Test plan (today's scope)

Splash: cold start white + big logo ≥2s → circular reveal; slow device, no
flash / no double-screen; permissions path works. Auth: login + register white
background, no black header; keyboard scroll/visibility ok; validations and
network calls unchanged. Driver (UI + follow + rotation): nav-to-rider
follow/pause/recenter/30s resume, arrived overlay = no camera moves;
active-ride initial driver+destination fit, my_location toggle unchanged,
recenter works; rotation stop-at-light = no snap. Rider (follow + UI +
rotation): tracking follow/pause/recenter/30s resume, reconnect refit behavior
observed; active ride follow now exists, no missing critical info;
pickup/dropoff/home maps no snap. Car marker asset quality: crispness on
multiple densities (low/high DPI), no rectangle background visible anywhere.
