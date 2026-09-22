# Phase 3 — Flutter Integration (frontend only)

Status: **PHASE 3 COMPLETE AND FROZEN (2026-08-03). All sub-phases 3A ✅ 3B ✅ 3C1 ✅ 3C2 ✅ 3D ✅ 3E ✅ 3E½ ✅ 3F ✅. Reports: PHASE3A_REPORT.md, PHASE3B_REPORT.md, PHASE3C1_REPORT.md, PHASE3C2_REPORT.md, PHASE3D_REPORT.md, PHASE3E_REPORT.md, PHASE3E½_REPORT.md, PHASE3_REPORT.md. Backend Phases 1/2A/2B/2C remain FROZEN. The Phase 1–3 implementation is complete; no further Phase 3 work is planned.**

## Guardrails (from user, 2026-08-02)
- Backend Phases 1/2A/2B/2C stay **frozen** — Flutter-only edits.
- If a backend API-contract issue is discovered, **STOP and report** before changing any backend code.
- Complete Flutter in **small, verifiable sub-phases**: compile → regression → report → approval between each.
- No opportunistic refactoring or cleanup outside the approved sub-phase scope.

## Objective
Consume the frozen backend contract (photos, vehicle photo, vehicleYear, driver verification status, enriched ride/WS/admin payloads, new PUT /users/{id} contract) so the rider profile, driver onboarding → documents → verification workflow, rider driver-card, and admin screens all reflect the new fields.

## Backend contract consumed (frozen, from Phase 2C report)
- `GET/PUT /api/drivers/profile` → `photoUrl`, `vehiclePhotoUrl` (derived), `vehicleYear`, `verifiedAt`, `verificationStatus`, plus `user` sub-object (`email`, `phoneNumber`, `countryCode`).
- `PUT /api/users/{id}` → editable `fullName`, `phoneNumber`+`countryCode`, `email`, `gender`, password change; returns `UserResponse` (adds `photoUrl`, `isOnline`, `isVerified`, `phoneVerified`, optional `token`).
- Register/login/verify-otp → `photoUrl`.
- Ride REST payload → `driver.photoUrl`, `driver.vehiclePhotoUrl`, `driver.vehicleType`, `driver.averageRating`, `driver.fullName`.
- WS `ride_accepted` → `driverPhotoUrl`, `driverVehiclePhotoUrl`, `driverRating`, `vehicleNumber` (keeps `licensePlate`).
- Admin detail → `photoUrl`, `vehiclePhotoUrl`, `vehicleYear`, `phoneNumber`, `licenseNumber`.
- Documents: `POST /api/drivers/documents`, `GET /api/drivers/documents/status`, `POST /api/drivers/submit`.

## Survey findings driving scope (2026-08-02)
- `image_picker` **not in pubspec**; `cached_network_image ^3.3.1` declared but **unused**; `PhotoService` exists but is **dead code** (zero call sites).
- `User` model has **no `photoUrl`**; `DriverProfile` model lacks `photoUrl`/`vehiclePhotoUrl`/`vehicleYear`/`verificationStatus`/`verifiedAt`.
- Driver onboarding (`driver_registration_screen.dart`) never uploads docs or submits; goes straight to `DriverHomeScreen` with no verification status display.
- Rider driver card: `rider_searching_driver_screen.dart` hardcodes empty vehicle fields on poll fallback; `rider_tracking_screen.dart` shows letter-initial avatar, no photo.
- WS `scheduled_ride_assigned` not handled (not in Phase 3 core scope; note only).
- Admin screens don't parse the new photo/vehicle-year/phone/license fields.
- `rider_profile_screen.dart` photo options are stubs ("requires image_picker"); avatar is initial-letter; `_save` doesn't send `countryCode` or support password change.

## Sub-Phase Plan (each ends with compile + scoped regression + report + approval)

### 3A — Models + photo plumbing (foundation) ✅ COMPLETE (2026-08-02, PHASE3A_REPORT.md)
- `pubspec.yaml`: `image_picker ^1.2.3` added.
- `lib/models/models.dart`: `User.photoUrl` added.
- `lib/models/ride_model.dart`: `DriverProfile` + `photoUrl`, `vehiclePhotoUrl`, `vehicleYear`, `verificationStatus`, `verifiedAt`.
- New shared widget `lib/widgets/user_avatar.dart` created (`CachedNetworkImage` + letter-initial fallback for null/empty/loading/failure).
- Verified: pub get ✅, analyze 0 errors (286 baseline) ✅, debug APK ✅, backward-compat parsing ✅, fallback ✅ (11 tests in `test/phase3a_models_avatar_test.dart`).
- No UI screens migrated yet (per approved scope).

### 3B — Rider profile photo + full profile update ✅ COMPLETE (2026-08-02, PHASE3B_REPORT.md)
- `lib/screens/rider_profile_screen.dart`: photo-option stubs replaced with `image_picker` camera/gallery; upload via `PhotoService.uploadPhoto`; remove-photo via new `PhotoService.deletePhoto`; avatar = `UserAvatar` with resolved photoUrl.
- `_save` sends `countryCode`; adds password-change fields (`currentPassword`/`newPassword`/`confirmPassword`) per new PUT contract; persists returned `token` (JWT refresh) / `gender` / `photoUrl`; surfaces backend 400 messages.
- `PhotoService` extended: `deletePhoto`, `resolvePhotoUrl` (relative→absolute).
- `lib/screens/account_screen.dart`: `UserAvatar` header + reload after profile edit. (`settings_screen`/`chat_screen` avatars deferred — no photoUrl source yet; documented in report.)
- Compile + live regression: photo upload/delete, PUT countryCode, password change (+revert), gender→token reissue all verified against live backend.

### 3C1 — Driver profile UI (registration/display only, no documents) ✅
- `lib/models/ride_model.dart` `DriverProfile`: `vehicleYear`, `verificationStatus`, `verifiedAt` already added in 3A — expose and render here.
- `lib/screens/driver_registration_screen.dart`: add `vehicleYear` field to Step 2 (vehicleInfo) and review step; send it in `POST /api/drivers/register` via `DriverService.registerAsDriver`.
- `lib/screens/driver_home_screen.dart`: profile overlay shows `verificationStatus` (DRAFT/PENDING/APPROVED/REJECTED), driver `photoUrl`, `vehiclePhotoUrl`, `vehicleYear`; online toggle stays backend-gated (APPROVED only — already enforced).
- `lib/services/driver_service.dart`: thread `vehicleYear` through `registerAsDriver`; expose parsed status in `getDriverProfile`.
- Compile + regression: register a fresh driver with vehicleYear; status banner + profile overlay render correct status/fields against live backend. → **PHASE3C1_REPORT.md; 19/19 tests, 0 errors, live regression passed; awaiting approval.**

### 3C2 — Driver document workflow ✅
- `lib/services/driver_service.dart`: add `uploadDocument` (→ `POST /api/drivers/documents`), `getDocumentsStatus` (→ `GET /api/drivers/documents/status`), `submitDriver` (→ `POST /api/drivers/submit`).
- `lib/screens/driver_registration_screen.dart`: add document-upload step (PROFILE_PHOTO, LICENSE, VEHICLE_REGISTRATION, VEHICLE_PHOTO, INSURANCE, NATIONAL_ID) with `image_picker`/`file_picker` (image + PDF); show completeness from `getDocumentsStatus`; submit step → `submitDriver`; DRAFT→PENDING flow.
- `lib/screens/driver_home_screen.dart`: reflect PENDING/APPROVED/REJECTED states after submission (status banner already from 3C1); allow resubmission path when REJECTED.
- Compile + live regression: full DRAFT → upload six docs → completeness ready → submit (PENDING) → (admin approves) → driver can go online. Verify each gate with a fresh test driver. → **PHASE3C2_REPORT.md; 27/27 tests, 0 errors, live end-to-end (DRAFT→PENDING, REJECTED→resubmit) passed; awaiting approval.**

### 3D — Rider driver-card enrichment (REST + WS verified independently) ✅
- `lib/models/ride_model.dart`: `Ride` now surfaces `driverVehiclePhotoUrl`, `driverVehicleType`, `driverVehicleNumber`, `driverVehicleModel`, `driverVehicleColor` from the nested `driver` map (alongside existing `driver.photoUrl`/`averageRating`).
- New `lib/utils/driver_card_data.dart`: pure-Dart normalizer `DriverCardData` — reads WS keys (`driverPhotoUrl`, `driverVehiclePhotoUrl`, `driverRating`, `vehicleNumber`) or REST keys (`photoUrl`, `vehiclePhotoUrl`, `averageRating`, `vehicleType`); strips empty-string placeholders; `fromRide`/`toPayloadMap`/`vehicleSummary`.
- `lib/screens/rider_searching_driver_screen.dart`: REST-poll fallback now builds the `driverData` payload from real ride data via `DriverCardData.fromRide` (hardcoded empty `vehicleColor`/`vehicleModel`/`licensePlate` and fake `4.0` rating removed).
- `lib/screens/rider_tracking_screen.dart`: driver card uses `UserAvatar` (photo), `DriverCardData.vehicleSummary` (type/model/color • number), real rating stars (nullable), vehicle-photo thumbnail; `_applyCard` merge repopulates on reconnect AND status poll (REST fallback) without photo loss.
- `lib/screens/rider_active_ride_screen.dart`: driver row uses `UserAvatar` (photo) + `vehicleSummary` line; `_fetchDriverInfo`/reconnect populate `_cardData` from ride.
- Verification (four paths independent): REST payload → `DriverCardData.fromRide` test; WS `ride_accepted` keys → `fromMap` test; reconnect → `_applyCard` merge test; REST-poll fallback → no-placeholder payload test (blank-string stripping + empty-map→empty-card).
- Compile: `flutter analyze` 0 errors / 282 issues (baseline unchanged); `flutter test` **42/42** (+15 Phase 3D); debug APK ✅. Live: endpoint live (403 without auth), DB confirms ride 258/driver 7 real enriched data (ABC-123 ECONOMY Toyota White rating 5). → **PHASE3D_REPORT.md; awaiting approval.**

### 3E — Admin screens enrichment ✅
- `lib/screens/admin_driver_details_screen.dart`: profile avatar = `UserAvatar` (photo via `photoUrl`, initial fallback); added `phoneNumber` + `licenseNumber` rows; vehicle card adds `vehicleYear` row + `vehiclePhotoUrl` thumbnail (`CachedNetworkImage` + car-icon fallback).
- `lib/screens/admin_rider_details_screen.dart`: profile avatar = `UserAvatar` (photo via `photoUrl`); phone already displayed.
- `lib/screens/admin_trip_details_screen.dart`: driver card = `UserAvatar` (photo via `driver.photoUrl`), `vehiclePhotoUrl` thumbnail, vehicle info (color/model/number) kept; rider card = `UserAvatar` (rider payload has no photo → initial fallback).
- `lib/screens/admin_driver_list_screen.dart` / `admin_rider_list_screen.dart`: person-icon avatars → `UserAvatar` (list summaries carry no `photoUrl` on frozen backend → initial avatar now, auto-photo if added later).
- `admin_home_screen.dart` / earnings dashboard: no avatar widgets or photo-capable payloads — left unchanged (documented).
- New l10n key `vehicleYear` (en/ar + generated localizations).
- Compile: `flutter analyze` 0 errors / 282 issues (baseline unchanged); `flutter test` **42/42**; debug APK ✅.
- Regression: backend contract confirmed read-only (`AdminDriverDetail`/`AdminRiderDetail`/`AdminTripDetail.DriverInfo` fields); live routes 403 without admin token; DB real data verified (rider 20 photo, driver 18 vehicle photo + vehicle info, driver 13/22/23 vehicle year/license/phone, ride 286 driver 18/rider 20). Interactive UI walkthrough needs logged-in admin session (admin password unknown; prior phases ran live regression via app UI). → **PHASE3E_REPORT.md; awaiting approval.**

### 3E½ — Compatibility / null-state regression ✅
Dedicated check that the app degrades gracefully when:
- `photoUrl = null` (letter-initial avatar, no error)
- `vehiclePhotoUrl = null` (card renders without image)
- `verificationStatus` missing (banner hides/neutral)
- older backend payloads omit the new keys entirely (additive-parsing safe)
- network image fails to load (CachedNetworkImage errorBuilder → fallback, no crash)
- image upload cancelled by user (no stuck loading state)
- document upload cancelled by user (no stuck loading state)
- Compile + regression: all null/cancelled/failure paths behave, no red screens.
- Status: **COMPLETE (2026-08-03, PHASE3E½_REPORT.md)** — `DriverCardData.fromRide` blank-stripping hardening; 15 new compat/resilience tests (`test/phase3e_hy_compat_test.dart`, incl. deterministic network-failure widget test via stubbed `CacheManager` and failing-backend no-stuck-spinner panel test); `flutter analyze` 0 errors / 282 issues (baseline restored); `flutter test` **57/57**; backend untouched; awaiting approval.

### 3F — End-to-end validation + report ✅
- Full live workflow validated against the frozen backend: rider register → photo upload; driver register (vehicleYear 2020) → 6 docs → submit (PENDING) → admin approve (APPROVED) → driver online → ride request/accept → rider receives enriched driver card on **both** WS (`ride_accepted`) and REST/reconnect (`GET /api/rides/{id}`) paths → admin views enriched driver (25) / rider (24) / trip (289) details. App parsers proven against the **live** payloads (`test/phase3f_live_payload_test.dart`).
- Quality gates: `flutter analyze` 0 errors / 282 issues (baseline unchanged); `flutter test` **59/59**; `flutter build apk --debug` OK; backend untouched (frozen). → **PHASE3_REPORT.md; Phase 3 marked COMPLETE and FROZEN.**

## Out of scope (noted, not done)
- WS `scheduled_ride_assigned` handling (new feature; tracked separately unless requested).
- Removing legacy `verified` key reliance (backend dual-key follow-up debt — backend frozen).
- `driver_info_card.dart` widget refactor (currently unused).
- Any backend changes unless an API-contract regression is discovered (then STOP and report).

## Execution Order (approved)
**3A → 3B → 3C1 → 3C2 → 3D → 3E → 3E½ → 3F** — each with compile → regression → report → approval gate. 3C1 (UI) is intentionally split from 3C2 (documents) to isolate registration UI risk from the workflow changes; 3D verifies REST, WS, reconnect, and fallback paths independently; 3E½ is a mandatory null/compat/cancellation regression before end-to-end 3F. **All sub-phases complete; Phase 3 FROZEN (2026-08-03).**

## Verification Checklist (per sub-phase)
1. `flutter pub get` succeeds; `flutter analyze` → 0 errors.
2. `flutter build apk --debug` (or `flutter run -d <device>`) succeeds.
3. Live regression for touched modules against frozen backend (localhost:8080).
4. Backend untouched (git status on chatserver shows only expected build artifacts; no src changes).

## Rollback Plan
- Revert the specific sub-phase Flutter files; `flutter pub get` re-sync if pubspec changed.
- Re-run `flutter analyze` + prior-sub-phase regression.
- Mid-phase regression → STOP and report before continuing.
