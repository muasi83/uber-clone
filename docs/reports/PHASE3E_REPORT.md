# Phase 3E — Admin Screens Enrichment

Status: **COMPLETE — Flutter-only. Backend untouched.** Date: 2026-08-02.

## Scope delivered
1. **`lib/screens/admin_driver_details_screen.dart`**
   - Profile avatar: person icon → `UserAvatar` (`photoUrl` via `PhotoService.resolvePhotoUrl`, letter-initial fallback).
   - New rows: `phoneNumber`, `licenseNumber` (both guarded on presence).
   - Vehicle card: new `vehicleYear` row + `vehiclePhotoUrl` thumbnail (`CachedNetworkImage` 56×44, car-icon fallback).

2. **`lib/screens/admin_rider_details_screen.dart`**
   - Profile avatar: person icon → `UserAvatar` (`photoUrl`). Phone was already displayed.

3. **`lib/screens/admin_trip_details_screen.dart`**
   - Driver card: letter avatar → `UserAvatar` (`driver.photoUrl`); added `driver.vehiclePhotoUrl` thumbnail (48×40); vehicle info line (color/model • number) and rating kept.
   - Rider card: letter avatar → `UserAvatar` (trip rider payload has no `photoUrl` on frozen backend → initial fallback).

4. **`lib/screens/admin_driver_list_screen.dart` / `admin_rider_list_screen.dart`**
   - Person-icon avatars → `UserAvatar` with resolved `photoUrl`. List summaries (`AdminDriverSummary`/`AdminRiderSummary`) carry no `photoUrl` on the frozen backend, so these render initial avatars today and will auto-show photos if the backend ever adds the field.

5. **`lib/screens/admin_home_screen.dart` / `admin_earnings_dashboard_screen.dart`** — no avatar widgets and no photo-capable payloads; left unchanged (noted, out of the scoped "avatar where appropriate" set).

6. **L10n** — new key `vehicleYear` added to `app_en.arb`, `app_ar.arb`, `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ar.dart`.

## Backend contract consumed (read-only, frozen)
- `GET /api/admin/drivers/{id}` → `AdminDriverDetail`: `photoUrl`, `phoneNumber`, `licenseNumber`, `vehicleModel/Color/Number/Type`, `vehicleYear`, `vehiclePhotoUrl`, plus existing fields (`AdminController.java` ~308–337).
- `GET /api/admin/riders/{id}` → `AdminRiderDetail`: `photoUrl`, `phoneNumber` (`AdminController.java` ~526–540).
- `GET /api/admin/trips/{id}` → `AdminTripDetail.DriverInfo`: `photoUrl`, `vehicleModel/Color/Number`, `vehiclePhotoUrl`, `averageRating` (`AdminController.java` ~1113–1124; `country`/`city` not set → guarded in UI).
- Admin **list** summaries (`toAdminDriverSummary`/`toAdminRiderSummary`) do **not** include `photoUrl` — list avatars are initial-fallback (UserAvatar handles null photo).

## Verification
- `flutter analyze` → **0 errors**, 282 issues (baseline unchanged).
- `flutter test` → **42/42** passing.
- `flutter build apk --debug` → **OK**.
- Live routes present + auth-gated: `GET /api/admin/drivers/13`, `/api/admin/riders/20`, `/api/admin/trips/286` all return **403** without an admin token.
- Real data confirmed (read-only DB) for every new rendered field:
  | Screen | Data |
  |--------|------|
  | Driver detail | driver 13 (APPROVED, Toyota Camry White 2022, license dl55654, rating 5), 22 (Honda Accord Black 2019, DL333444, phone 055555333), 23 (Kia Cerato Silver 2020, DL555666, phone 055555444), 18 (ABC-123 Toyota White, LIC12345, phone 5559999) |
  | Driver vehicle photo | driver 18 `/uploads/documents/18/18_0a4a3d50….png` (only driver with a VEHICLE_PHOTO doc) |
  | Rider detail | rider 20 `phase2brider@test.com` photo `/uploads/photos/20_9e….png`, phone 555010222 |
  | Trip detail | ride 286: driver 18 (vehicle photo + ABC-123 Toyota White + rating 5), rider 20 (photo) |
- **Live UI walkthrough limitation:** the interactive admin screens require a logged-in admin session. The admin password for `muasi@yahoo.com` (user 1) is not stored/known in this environment and the backend is frozen (cannot reset), so the on-device visual pass must be done in the app under the admin account — consistent with prior phases, where live regression ran via app UI. No API-contract issue was found (verified read-only), so no STOP-and-report condition triggered.

## Files changed (Flutter only)
| File | Change |
|------|--------|
| `lib/screens/admin_driver_details_screen.dart` | UserAvatar photo, phone + license rows, vehicle year + vehicle-photo thumbnail |
| `lib/screens/admin_rider_details_screen.dart` | UserAvatar photo |
| `lib/screens/admin_trip_details_screen.dart` | UserAvatar driver/rider, vehicle-photo thumbnail |
| `lib/screens/admin_driver_list_screen.dart` | UserAvatar avatar |
| `lib/screens/admin_rider_list_screen.dart` | UserAvatar avatar |
| `lib/l10n/app_en.arb`, `app_ar.arb`, `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ar.dart` | `vehicleYear` key |
| `PHASE3_PLAN.md` | 3E marked complete |

## Next
Per execution order, **3E½ — compatibility / null-state regression** (photoUrl null, vehiclePhotoUrl null, verificationStatus missing, older payloads, network-image failure, cancelled uploads) — **awaiting approval.**
