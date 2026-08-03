# Phase 2C — Profile Completeness + Payload Enrichment (backend only)

Status: **COMPLETE + FROZEN (2026-08-02).** Backend only; no Flutter files changed.

## Objective (from PHASE2_PLAN.md §2C)
User/DriverProfile = single source of truth for profile fields; users edit exactly what's allowed (not verification status/docs/driverId); rider sees full driver card on accept over REST + WS (works on reconnect).

Single-source-of-truth rules respected:
- **No `users.photo_url`.** Profile photos stay in `profile_photos`; DTOs use `PhotoService.getPhotoUrl(userId)`.
- **No `vehiclePhotoUrl` column.** Derived at DTO build time from the driver's `VEHICLE_PHOTO` document via `DriverDocumentService.getVehiclePhotoUrl(driverId)` (new helper); null if absent.

## Files Changed (all in chatserver backend)
| File | Change |
|------|--------|
| `entity/User.java` | **Temporary dual-key**: kept `getVerified()` (emits `verified`) AND added `@JsonProperty("isVerified")` getter (emits `isVerified`) on raw-entity serializations. **Tracked follow-up debt:** collapse to single `isVerified` once consumers migrate off `verified`. |
| `entity/DriverProfile.java` | Added `Integer vehicleYear` (+ getter/setter). |
| `controller/UserController.java` | Rewrote `PUT /api/users/{id}`: editable `fullName`, `phoneNumber`+`countryCode` (recompute `normalizedPhone` via `PhoneNormalizer`, reset `phoneVerified=false`, uniqueness enforced), `email` (uniqueness + re-issue JWT), `gender` (re-issue JWT on change). Password change: `currentPassword`/`newPassword`/`confirmPassword` validation. Returns `UserResponse`. Injected `PasswordEncoder`, `PhoneNormalizer`. |
| `dto/UserResponse.java` | Added nullable `token` field (populated on PUT when JWT re-issued; null elsewhere). Already had `photoUrl`. |
| `dto/AuthResponse.java` | Added `photoUrl` (+ getter/setter). |
| `controller/AuthController.java` | Injected `PhotoService`; `photoUrl` populated at register, login, verify-otp. |
| `dto/DriverProfileRequest.java` | Added `vehicleYear`. |
| `dto/DriverProfileUpdateRequest.java` | Added `fullName`, `phoneNumber`, `email`, `vehicleYear`. |
| `controller/DriverController.java` | `POST /register` persists `vehicleYear`. `PUT /api/drivers/profile`: editable `fullName`, `phoneNumber` (recompute normalized + uniqueness + reset phoneVerified), `email` (uniqueness), `licenseNumber`, `vehicleNumber`, `vehicleType`, `vehicleModel`, `vehicleColor`, `vehicleYear`. Not editable: `verificationStatus`, documents, driverId. GET & PUT response add `photoUrl`, `vehiclePhotoUrl`, `vehicleYear`, `verifiedAt`; `user` object adds `email`, `phoneNumber`, `countryCode`. |
| `controller/RideController.java` | Injected `PhotoService` + `DriverDocumentService`; `buildRideResponse` driver payload adds `photoUrl`, `vehiclePhotoUrl`, `vehicleType` (already had `fullName`, `averageRating`, model/color/number/lat/lng). |
| `service/RideWebSocketService.java` | Injected `PhotoService` + `DriverDocumentService`. `notifyRideAccepted` adds `driverPhotoUrl`, `driverVehiclePhotoUrl`, `driverRating` (alias of averageRating), `vehicleNumber` (keeps `licensePlate` alias). `notifyScheduledRideAssigned` adds `driverPhotoUrl`. |
| `service/DriverDocumentService.java` | Added `getVehiclePhotoUrl(Long driverId)` helper (read-only, returns Optional fileUrl for `VEHICLE_PHOTO`). |
| `dto/AdminDriverDetail.java` | Added `photoUrl`, `phoneNumber`, `licenseNumber`, `vehicleYear`, `vehiclePhotoUrl`. |
| `dto/AdminRiderDetail.java` | Added `photoUrl` (already had `phoneNumber`). |
| `dto/AdminTripDetail.java` | `DriverInfo` added `photoUrl`, `vehiclePhotoUrl`. |
| `controller/AdminController.java` | Injected `PhotoService`; populated new fields in `toAdminDriverDetail` (~L306), `toAdminRiderDetail` (~L519), `toAdminTripDetail` (~L1105). |

## API Contract Changes (additive only — no removed keys)
- `PUT /api/users/{id}` response shape: ad-hoc map → **`UserResponse`** (adds `isOnline`, `isVerified`, `phoneVerified`, `photoUrl`, `createdAt`; keeps `gender`, `role`, `email`, `fullName`, `phoneNumber`, `countryCode`, `username`, `id`). `token` present only when email/gender changed. Verified compatible with Flutter `rider_profile_screen._save` (reads `token`, `gender`).
- `GET /api/users` (admin, raw entities): `User` now emits both `verified` and `isVerified`.
- Register/login/verify-otp: add `photoUrl`.
- `GET/PUT /api/drivers/profile`: add `photoUrl`, `vehiclePhotoUrl`, `vehicleYear`, `verifiedAt`; PUT accepts user fields.
- Ride REST payload + WS `ride_accepted`: additive driver photo/rating/vehicle keys (`licensePlate` preserved).
- Admin driver/rider/trip detail: additive photo/phone/license/vehicleYear/vehiclePhotoUrl keys.
- DB: `driver_profiles.vehicle_year INTEGER` added via `ddl-auto: update` (verified in information_schema).

## Live Verification Matrix (2026-08-02, backend PID restarted)
All against `http://localhost:8080` (fresh 2C build, PID 8692).

| Test | Result |
|------|--------|
| Admin `GET /api/users` raw entity emits both `verified`+`isVerified` (user 13) | PASS (both True) |
| `GET /api/users/13` (UserResponse) emits `isVerified`, `photoUrl`, `token:null` | PASS |
| Login (user 20) returns `photoUrl` key | PASS |
| `PUT /api/users/20` fullName → 200, UserResponse, no token (no identity change) | PASS |
| `PUT /api/users/20` phone+countryCode → 200, `phoneVerified=false`, cc=+966, phone updated | PASS |
| `PUT /api/users/20` duplicate email (user 19's) → 400 "Email already in use" | PASS |
| `PUT /api/users/20` duplicate phone (user 18's) → 400 "Phone number already registered" | PASS |
| `PUT /api/users/20` gender MALE→FEMALE → 200, `token` re-issued; FEMALE→MALE → token re-issued | PASS |
| `PUT /api/users/20` bad currentPassword → 400 "Current password is incorrect" | PASS |
| `PUT /api/users/20` currentPassword ok + newPassword≠confirmPassword → 400 "New passwords do not match" | PASS |
| `PUT /api/users/20` change password → 200; old password login 400; new password login 200 | PASS |
| Photo upload (user 20) → `photoUrl` `/uploads/photos/20_...png`; login now returns it | PASS |
| `GET /api/drivers/profile` (driver 13) shows new keys (null when empty) | PASS |
| `PUT /api/drivers/profile` fullName+vehicleYear+model+color → 200, all persisted | PASS |
| `PUT /api/drivers/profile` email change + revert → 200 | PASS |
| Ride 286 payload (accepted by driver 18) → driver has `fullName`, `vehicleType`, `averageRating`, `vehiclePhotoUrl` (derived from doc), `photoUrl` | PASS |
| New ride 287 request → accept by driver 13 → driver payload fully enriched; ride then cancelled for cleanup | PASS |
| Admin driver detail 18 → `photoUrl`, `phoneNumber`, `licenseNumber`, `vehicleYear`, `vehiclePhotoUrl` | PASS |
| Admin rider detail 20 → `photoUrl` populated | PASS |
| Admin trip 286 detail → `driver.photoUrl`, `driver.vehiclePhotoUrl` | PASS |
| Fresh register (user 21) → 200, role RIDER, gender FEMALE, `photoUrl` key; duplicate → 400 "Email already registered" | PASS |
| Static photo serving `/uploads/photos/20_....png` → 200 | PASS |
| 2B gate spot checks: driver 13 (APPROVED) toggle-online → 200; driver 19 (REJECTED) → 403 "Driver not verified" | PASS |
| `driver_profiles.vehicle_year` column exists (integer) | PASS |
| `mvn -q compile` | EXIT=0 |

Cleanup performed: cancelled test ride 287; reverted driver 13 email/fullName; toggled driver 13 offline.

## Notes / Deviations
- `GET /api/users/{id}` (account_screen consumer) already returned `UserResponse`; unchanged. `PUT` now also returns `UserResponse` (was ad-hoc map).
- `driver_fullName`/`driverRating`/`driverVehiclePhotoUrl` are additive WS keys; existing `licensePlate`, `averageRating`, `vehicleModel`, `vehicleColor` preserved.
- WS payloads verified by code + compile (additive); REST ride payload exercising the same enrichment sources was verified live.
- `vehicleType` remains editable on driver profile (existing behavior preserved; plan's editable list was additive, not exhaustive).
- Backend log files / target artifacts show in git status as modified/untracked — pre-existing repo hygiene, out of scope for 2C.

## Next Steps
1. Await approval to freeze Phase 2C.
2. **Phase 3 (Flutter):** consume `photoUrl`/`vehiclePhotoUrl`/`vehicleYear`/`verifiedAt` in profile screens, driver card on accept (REST + WS), admin screens; remove reliance on legacy `verified` key (tracked follow-up debt).
