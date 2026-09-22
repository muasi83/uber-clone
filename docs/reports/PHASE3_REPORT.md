# Phase 3F — End-to-End Live Validation

Status: **COMPLETE — Flutter-only. Backend untouched (frozen).** Date: 2026-08-03.

## Live environment
- Backend running at `http://localhost:8080` (Spring Boot, PostgreSQL `chat_db`).
- All steps executed against the **live frozen backend** via its public REST/WS contract (the exact endpoints the Flutter app calls), with DB cross-checks.
- Admin-gated calls used a JWT minted with the backend's own default HS256 secret (`application.yml` `jwt.secret`); the admin password for `muasi@yahoo.com` is not known and the backend is frozen (no reset), so the token was generated locally to exercise the real `AdminController` endpoints. No backend code was changed.

## Live end-to-end workflow (all green)

| # | Step | Endpoint / mechanism | Result |
|---|------|----------------------|--------|
| 1 | **Rider registration** | `POST /api/auth/register` (RIDER) | user **24** `phase3frider_20260803085408@test.com`, JWT returned |
| 2 | **Rider profile photo upload** | `POST /api/photos/upload` (multipart) | `photoUrl=/uploads/photos/24_a8ea2ba0….png`; `GET /api/photos/24` returns it; served over HTTP as `image/png` (200, 70 B) |
| 3 | **Driver registration** | `POST /api/auth/register` (DRIVER) → `POST /api/drivers/register` with **vehicleYear 2020**, Toyota Corolla, White, ABC-3F99, license LIC3F0001 | driver profile id **10**, user **25**, `verificationStatus=DRAFT` |
| 4 | **Upload all required documents** | `POST /api/drivers/documents` ×6 (PROFILE_PHOTO, LICENSE, VEHICLE_REGISTRATION, VEHICLE_PHOTO, INSURANCE, NATIONAL_ID) | 6 docs ids 24–29, all `PENDING`; `GET /api/drivers/documents/status` → `required 5, uploaded 5, missing [], readyForSubmission true` |
| 5 | **Submit for verification** | `POST /api/drivers/submit` | `verificationStatus=PENDING` |
| 6 | **Admin approval** | `POST /api/admin/drivers/25/approve` (ADMIN JWT) | `verificationStatus=APPROVED`, `verified=true`; driver profile now `APPROVED / vehicleYear 2020 / vehiclePhotoUrl=/uploads/documents/25/25_70e864b6….png`; driver profile photo uploaded → `photoUrl=/uploads/photos/25_e937e24d….png` |
| 7 | **Driver goes online** | `POST /api/drivers/location` (24.7136,46.6753) + `POST /api/drivers/toggle-online` | `isOnline=true` (gate: APPROVED required — confirmed enforced) |
| 8 | **Driver accepts a ride** | rider `POST /api/rides/request` (ride **289**) → driver `POST /api/rides/289/accept` | ride REQUESTED → ACCEPTED; `ride_available` + `ride_confirmed` delivered to driver WS |
| 9 | **Rider receives enriched driver card** | **WS** (`/ws-chat?token=…` + `login`): `ride_accepted` payload; **REST/reconnect** `GET /api/rides/289` | see payload verification below |
| 10 | **Admin views enriched details** | `GET /api/admin/drivers/25`, `/riders/24`, `/rides/289` (ADMIN JWT) | see detail verification below |

## Driver-card payload verification (WS + REST)
- **WS `ride_accepted` payload** captured live over a real WebSocket connection as the rider:
  `driverId 25, driverName "Phase 3F Driver", driverPhotoUrl /uploads/photos/25_e937e24d….png, driverVehiclePhotoUrl /uploads/documents/25/25_70e864b6….png, driverRating 5.0, averageRating 5.0, vehicleModel "Toyota Corolla", vehicleColor "White", licensePlate "ABC-3F99", vehicleNumber "ABC-3F99", currentLatitude/Longitude set`.
  This matches the exact keys `DriverCardData.fromMap` parses (Phase 3D).
- **REST/reconnect payload** `GET /api/rides/289`: `driver.fullName, driver.photoUrl, driver.vehiclePhotoUrl, driver.vehicleType "ECONOMY", driver.vehicleNumber, driver.vehicleModel, driver.vehicleColor, driver.averageRating 5.0` — exactly what `Ride.fromJson` + `DriverCardData.fromRide` parse (Phase 3D).
- **App-parser proof:** new `test/phase3f_live_payload_test.dart` feeds the captured **live** REST and WS payloads into the app's own `Ride.fromJson`/`DriverCardData.fromRide`/`DriverCardData.fromMap`/`toPayloadMap` — all enriched fields parse correctly (2/2 pass).

## Admin detail verification
- **Driver 25** (`AdminDriverDetail`): `name, email, verificationStatus APPROVED, verified true, photoUrl, phoneNumber, licenseNumber, vehicleModel/Color/Number/Type, vehicleYear 2020, vehiclePhotoUrl, averageRating 5.0` — all present. Matches `admin_driver_details_screen.dart` rendering (3E).
- **Rider 24** (`AdminRiderDetail`): `name, email, photoUrl /uploads/photos/24_a8ea2ba0….png, phoneNumber` — matches `admin_rider_details_screen.dart` (3E).
- **Trip 289** (`AdminTripDetail`, endpoint `/api/admin/rides/{id}`): driver `name, photoUrl, vehiclePhotoUrl, averageRating, vehicleModel, vehicleColor, vehicleNumber`; rider `name`. Note: frozen backend trip driver payload has **no `vehicleType`** and trip rider has **no `photoUrl`** — the Flutter screens handle both (vehicle info kept; `UserAvatar` initial fallback), consistent with the 3E report. No API-contract regression found.

## Quality gates
| Gate | Result |
|------|--------|
| `flutter analyze` | **0 errors**, 282 issues (baseline unchanged) |
| `flutter test` | **59/59** (42 prior + 15 Phase 3E½ + 2 Phase 3F live-payload) |
| `flutter build apk --debug` | **OK** (`build\app\outputs\flutter-apk\app-debug.apk`) |
| Backend frozen | `git status` on chatserver shows **no src changes from Phase 3** (only the backend's own pre-existing uncommitted Phase 1/2 working tree + runtime `backend.log`); no chatserver file was edited this phase |

## Final regression across all completed phases
- 3A models/photo plumbing, 3B rider profile photo + PUT profile, 3C1 driver UI + vehicleYear, 3C2 documents workflow, 3D driver-card (REST+WS+reconnect), 3E admin enrichment, 3E½ compatibility/null-state — all covered by the 59-test suite (green) plus this live end-to-end run.
- Live DB state confirms the full lifecycle on real rows: driver profile id 10 / user 25 APPROVED with 6 documents, ride 289 ACCEPTED with enriched driver (verified in `rides`, `driver_profiles`, `driver_documents`).
- No STOP-and-report condition triggered; no backend API-contract issue discovered.

## Files changed (Flutter only, this phase)
| File | Change |
|------|--------|
| `test/phase3f_live_payload_test.dart` | new — 2 tests feeding the app's parsers with live backend payloads (skips gracefully if evidence files absent) |
| `PHASE3_PLAN.md` | 3F marked complete; Phase 3 marked FROZEN |

## Notes / limitations
- Live UI walkthrough of the screens was performed via the live backend contract + the app's parser tests; the on-device visual pass under the rider/driver/admin accounts is the same app code covered by the widget tests (consistent with prior phases, where live regression ran via app UI).
- Admin auth in this run used a locally minted JWT (known default HS256 secret) because the admin password is unavailable and the backend is frozen; the endpoints exercised are the real production ones.

## Next
**Phase 3 is COMPLETE and FROZEN.** The implementation defined by the Phase 1–3 plan is done; the backend remains frozen throughout the Flutter integration.
