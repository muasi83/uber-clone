# Phase 3C1 Report — Driver Profile UI (registration/display, no documents)

**Status: COMPLETE (awaiting approval before 3C2).**
**Date:** 2026-08-02
**Backend frozen throughout — zero backend source changes (99 `.java` files tracked, same set as the 3B snapshot).**

## Scope delivered (Flutter only)
1. **`vehicleYear` in registration UI** (`lib/screens/driver_registration_screen.dart`):
   - New "Vehicle Year" field in the Vehicle Information step (numeric keyboard, max 4 digits).
   - Validation on Next: required, integer, 1980..currentYear+1 (shows "Please enter a valid vehicle year").
   - Review step shows Vehicle Year; disposed properly.
2. **`vehicleYear` threaded through registration** (`lib/services/driver_service.dart`):
   - `registerAsDriver` gains `int? vehicleYear`, included in the `POST /api/drivers/register` body (`'vehicleYear': vehicleYear`).
3. **Driver profile model/UI updates** (`lib/screens/driver_home_screen.dart`):
   - Profile overlay avatar → shared `UserAvatar` (driver `photoUrl`, letter fallback).
   - **Verification status banner** (DRAFT / PENDING / APPROVED / REJECTED) below the name.
   - Stats now include Vehicle (**model • year**), Vehicle Type (from `vehicleType`), and a **Vehicle Photo** card (from `vehiclePhotoUrl`, `CachedNetworkImage` with placeholder/error fallback).
4. **Toggle online surfaces the gate** (`driver_service.dart` + `driver_home_screen.dart`):
   - `toggleOnlineStatus` returns `({bool online, String? message})` and now surfaces the backend 403 message (`Driver not verified`) instead of silently staying offline — reads both `message` and `error` response keys.
5. **Testable mapping** (`lib/utils/driver_verification.dart`, new): `driverVerificationInfo(status)` → label/color/icon for the banner.

## Out of scope (per 3C1)
- **No** document upload, completeness checks, `POST /api/drivers/submit`, or DRAFT→PENDING flow — reserved for 3C2.

## Verification matrix
| Check | Result |
|---|---|
| `flutter analyze` | ✅ **0 errors** — 283 issues (down from 284; all pre-existing infos) |
| `flutter build apk --debug` | ✅ built |
| `flutter test` | ✅ **19/19** (added 3C1: verification mapping + vehicle/verification parse round-trip) |
| Backend frozen | ✅ git `.java` file set unchanged (99, same as 3B) |

## Live backend regression (localhost:8080)
| # | Check | Result |
|---|---|---|
| 1 | Register fresh user 22 (`phase3c1_driver`, RIDER) | ✅ 200, token |
| 2 | `POST /api/drivers/register` with `vehicleYear: 2019` | ✅ 200 → `profileId:8, verificationStatus:"DRAFT"` |
| 3 | `GET /api/drivers/profile` (new driver) | ✅ 200 → `vehicleYear:2019`, `verificationStatus:"DRAFT"`, `photoUrl:null`, `vehiclePhotoUrl:null`, `verifiedAt:null` (all parsed by `DriverProfile.fromJson`) |
| 4 | `POST /api/drivers/toggle-online` while DRAFT | ✅ 403 `{"error":"Driver not verified"}` — message now surfaced in-app (discovered `error` key; service reads both `message`/`error`) |
| 5 | `GET /api/drivers/profile` (driver 13, APPROVED) | ✅ 200 → `verificationStatus:"APPROVED"`, `isVerified:true`, `vehicleYear:2022`, `vehicleModel:"Toyota Camry"` → banner shows "Approved", vehicle "Toyota Camry • 2022" |

## Test-data note
- New DB rows from this phase: user 22 `phase3c1_driver` + driver profile 8 (DRAFT, vehicleYear 2019) — kept as test data (consistent with prior phases). Driver 13 unchanged (APPROVED, offline).

## Files changed (Flutter only)
| File | Change |
|---|---|
| `lib/screens/driver_registration_screen.dart` | vehicle year field, validation, review row, threading, dispose |
| `lib/services/driver_service.dart` | `registerAsDriver` +`vehicleYear`; `toggleOnlineStatus` → `(online, message)` record, reads `message`/`error` |
| `lib/screens/driver_home_screen.dart` | `UserAvatar`, verification banner, vehicle/year/type stats, vehicle-photo card, toggle error surfacing |
| `lib/utils/driver_verification.dart` | **new** banner label/color/icon mapping |
| `test/phase3a_models_avatar_test.dart` | +3C1 mapping + parse round-trip tests |

## Next step
Await approval, then begin **Phase 3C2 — Driver document workflow** (image/PDF picker, six document uploads, completeness, submit, DRAFT→PENDING).
