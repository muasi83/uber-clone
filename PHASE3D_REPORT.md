# Phase 3D — Rider Driver-Card Enrichment (REST + WS verified independently)

Status: **COMPLETE — Flutter-only. Backend untouched.** Date: 2026-08-02.

## Scope delivered
1. **`lib/models/ride_model.dart`** — `Ride` now surfaces the enriched driver-vehicle fields from the nested `driver` map returned by `GET /api/rides/{id}`:
   - `driverVehiclePhotoUrl` ← `driver.vehiclePhotoUrl`
   - `driverVehicleType` ← `driver.vehicleType`
   - `driverVehicleNumber` ← `driver.vehicleNumber`
   - `driverVehicleModel` ← `driver.vehicleModel`
   - `driverVehicleColor` ← `driver.vehicleColor`
   - (existing: `driver.photoUrl`, `driver.averageRating` via `driverAverageRating`)
   - All parsed null-safely when absent; round-trips through `toJson`.

2. **New `lib/utils/driver_card_data.dart`** — pure-Dart, unit-testable normalizer that both the WS `ride_accepted` path and the REST path feed into:
   - `DriverCardData.fromMap` reads WS keys (`driverName`, `driverPhotoUrl`, `driverVehiclePhotoUrl`, `driverVehicleType`, `driverVehicleNumber`, `driverVehicleModel`, `driverVehicleColor`, `driverRating`, plus `licensePlate` alias and `fullName`/`averageRating` REST fallbacks) **and** REST-style keys.
   - Blank/empty strings are sanitized to `null` — **no empty placeholder strings survive**.
   - `DriverCardData.fromRide(Ride)` maps the REST ride payload.
   - `toPayloadMap()` emits only non-null values under canonical WS-style keys (used to build the poll-fallback `driverData`).
   - `vehicleSummary` composes `type model color • number`.

3. **`lib/screens/rider_searching_driver_screen.dart`** — REST-poll fallback (`_checkRideStatus`) no longer hardcodes `vehicleColor: ''`, `vehicleModel: ''`, `licensePlate: ''` or a fake `averageRating: 4.0`. It now builds the `driverData` payload from real ride data via `DriverCardData.fromRide(ride)` + the ride location/address fields. WS path passes the enriched WS payload through unchanged.

4. **`lib/screens/rider_tracking_screen.dart`** — driver card enriched:
   - Avatar = `UserAvatar` with `PhotoService.resolvePhotoUrl(photoUrl)` (photo; letter-initial fallback).
   - Vehicle line = `DriverCardData.vehicleSummary` (vehicle type/model/color • number).
   - Rating stars render from a nullable `rating` (no fake 5/4.0 baseline).
   - Vehicle-photo thumbnail (`CachedNetworkImage` + car-icon fallback).
   - `_applyCard(incoming)` merges enriched fields and setStates **only when something changed**; applied from the WS/REST `driverData` on load, from `DriverCardData.fromRide` on **reconnect**, and on every **status poll** (REST fallback keeps the card filled without photo loss).

5. **`lib/screens/rider_active_ride_screen.dart`** — driver row uses `UserAvatar` (photo) + `vehicleSummary` sub-line; `_fetchDriverInfo` and reconnect repopulate `_cardData` from the ride.

## Verification (four independent paths)
| # | Path | How proven | Result |
|---|------|-----------|--------|
| 1 | **REST payload** | `DriverCardData.fromRide(Ride.fromJson(real enriched payload))` + `Ride.fromJson` enriched-field parse/round-trip tests; DB confirms real data (ride 258/driver 7: `ABC-123` ECONOMY Toyota White, rating 5) | ✅ |
| 2 | **WebSocket `ride_accepted`** | `DriverCardData.fromMap` with exact WS keys (`driverPhotoUrl`, `driverVehiclePhotoUrl`, `driverRating`, `vehicleNumber`) | ✅ |
| 3 | **Reconnect** | `_applyCard` merge (reconnect + status poll) preserves/updates photo, vehicle photo, vehicle info, rating without wiping | ✅ |
| 4 | **REST-poll fallback** | `_checkRideStatus` builds payload from `DriverCardData.fromRide` — no hardcoded placeholders; blank-string stripping + empty-map→empty-card tested | ✅ |

- `flutter analyze` → **0 errors**, 282 issues (baseline unchanged — no new warnings).
- `flutter test` → **42/42** passing (+15 in `test/phase3d_driver_card_test.dart`).
- `flutter build apk --debug` → **OK**.
- Live: `GET /api/rides/258` live (403 without auth — route present, auth-protected); enriched data confirmed in DB (read-only). Full UI regression requires an authenticated rider (prior phases ran via app UI).

## Files changed (Flutter only)
| File | Change |
|------|--------|
| `lib/models/ride_model.dart` | +5 enriched driver-vehicle fields (parse/toJson, null-safe) |
| `lib/utils/driver_card_data.dart` | **new** — `DriverCardData` normalizer |
| `lib/screens/rider_searching_driver_screen.dart` | poll fallback uses real ride data (placeholders removed) |
| `lib/screens/rider_tracking_screen.dart` | `UserAvatar` photo, vehicle summary, real rating, vehicle-photo thumb, `_applyCard` on load/reconnect/poll |
| `lib/screens/rider_active_ride_screen.dart` | `UserAvatar` photo + `vehicleSummary` in driver row |
| `test/phase3d_driver_card_test.dart` | **new** — 15 tests |
| `PHASE3_PLAN.md` | 3D marked complete |

## Notes
- `cancel_ride_dialog`/`event_recorder_service` unused-import warnings in `rider_active_ride_screen.dart` are pre-existing (imports unchanged; baseline 282 issues identical).
- Next per execution order: **3E — admin screens enrichment** (awaiting approval).
