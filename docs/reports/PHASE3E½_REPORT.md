# Phase 3E½ — Compatibility / Null-State Regression

Status: **COMPLETE — Flutter-only. Backend untouched.** Date: 2026-08-03.

## Purpose
A dedicated regression that the app degrades gracefully (no crashes, no red screens, no permanently stuck loading indicators) when the frozen backend delivers null/whitespace values, omits the new keys entirely (older payloads), or fails/cancels at the image layer.

## Scope delivered

### 1. Null / whitespace photo & vehicle-photo URLs
- `PhotoService.resolvePhotoUrl` returns `null` for null, `''`, `'   '`, tab, newline, and non-breaking-space inputs (no `!` crash on blank values).
- `DriverCardData.fromRide` now sanitizes blank/whitespace strings to `null` for `name`, `photoUrl`, `vehiclePhotoUrl`, `vehicleType`, `vehicleNumber`, `vehicleModel`, `vehicleColor` — matching the existing `fromMap` behaviour (small resilience fix in `lib/utils/driver_card_data.dart`). All card-rendering sites feed these through `CachedNetworkImage`/`UserAvatar`, which fall back to initials/icons when the value is null.
- `UserAvatar` already renders the letter-initial fallback for null/empty/blank URLs (verified in 3A tests).

### 2. Missing / null `verificationStatus`
- `driverVerificationInfo(status)` is a total function: `null`, `''`, `' '`, and unknown values all map to the neutral **Draft** banner (label/color/icon) — verified no-crash for `null`, `''`, `' '`, and unknown strings.
- `DriverProfile.fromJson` parses old payloads with `verificationStatus`/`vehicleYear`/`photoUrl`/`vehiclePhotoUrl`/`verifiedAt` all absent → nulls, no throw.
- `_buildVerificationBanner` / `_needsVerificationAction` / `DriverCardData` all null-safe on that null status.

### 3. Older payloads omitting the new keys (additive parsing)
- `Ride.fromJson`: absent `driver` object → all enriched fields (`driverVehiclePhotoUrl/Type/Number/Model/Color`, `driverAverageRating`, `driverLatitude`, `driverLongitude`) null; absent `rider` → `Unknown User` fallback; no throw.
- `Ride.fromJson`: `driver` present but without photo/vehicle keys → nulls, no throw.
- `DriverDocument.fromJson({})` → `id 0`, all optional fields null; `{id: 7}` → `id 7`, rest null.
- `DocumentCompleteness.fromJson({})` → `required 0`, `uploaded 0`, `missing []`, `readyForSubmission false`; tolerates `missing: null` and non-list `missing` → `[]`.
- `driverDocumentTypeLabel(null)` → `'Document'`; unknown type → returns the type string itself.
- `DriverProfile.fromJson` old payload (no new keys) → all new fields null (re-verified).

### 4. Network-image failure
- All `CachedNetworkImage` errorWidgets (UserAvatar, admin driver/trip details, driver-home vehicle card, rider-tracking vehicle thumb) render a fallback (initial letter / car icon) — no crash, no red screen, no stuck spinner.
- **New widget test** drives a real load failure deterministically via a stubbed `CacheManager` (returns a `Stream.error`) and asserts the car-icon fallback renders with `takeException() == null`.
- The 3A `UserAvatar` network-failure test (placeholder/errorWidget both show the initial) also re-confirms graceful loading.

### 5. Cancelled image / document upload — no stuck state
- **Rider profile** `_pickPhoto`/`_removePhoto` (code-inspected): null result from `ImagePicker.pickImage` (user cancels) returns before `_isUploading = true`; every success/catch path resets `_isUploading = false`. No path leaves the spinner mounted.
- **Documents panel** `_pickAndUpload` (code-inspected): cancelled source selection (`_chooseSource()` → null) or cancelled `ImagePicker.pickImage` (null) returns before `_uploading[type] = true`; both success and catch paths reset `_uploading[type]`. `DriverService.uploadDriverDocument` never throws (try/catch → null).
- `PhotoService.uploadPhoto`/`deletePhoto` and `DriverService` document methods all wrap in try/catch and return null/safe values — a failing/cancelled upload cannot throw into the UI.
- **Widget test** proves the panel cannot stay stuck: with a failing backend (400 mock), it starts with a spinner, then `pumpAndSettle` completes with the spinner gone and `takeException() == null`.

### 6. Compatibility hardening change
- `DriverCardData.fromRide` (see §1) — the only production change this phase; everything else was verification-only.

## Verification
- `flutter test` → **57/57** passing (42 prior + 15 new in `test/phase3e_hy_compat_test.dart`).
- `flutter analyze` → **0 errors**, 282 issues (baseline unchanged; restored after cleaning the 5 new infos the test file introduced — added `flutter_cache_manager` to dev_dependencies, const fixes).
- `flutter pub get` → OK.
- Backend untouched: `git status` shows only Flutter files + generated plugin registrants (pub get/build artifacts); no chatserver/src changes.
- New test coverage (`test/phase3e_hy_compat_test.dart`, 15 tests):
  | Area | Tests |
  |------|-------|
  | Old payloads omit new fields | `Ride.fromJson` (driver absent / driver without photo-vehicle / rider absent), `DriverDocument` (no keys / id-only), `DocumentCompleteness` (no keys / null+non-list missing), `driverDocumentTypeLabel` fallbacks |
  | Null/whitespace URLs | `resolvePhotoUrl` (tab/newline/NBSP), `DriverCardData.fromRide` blank-stripping, `fromRide` real-values intact |
  | Missing verificationStatus | `' '` → Draft, `DriverProfile` old payload → null status → Draft |
  | Network-image failure | vehicle-photo `CachedNetworkImage` errorWidget renders car icon (deterministic failing `CacheManager`), no exception |
  | No stuck loading | documents panel with failing backend: spinner → resolved, no `CircularProgressIndicator` remains, no exception |

## Files changed (Flutter only)
| File | Change |
|------|--------|
| `lib/utils/driver_card_data.dart` | `fromRide` now strips blank/whitespace strings to null (matches `fromMap`) |
| `test/phase3e_hy_compat_test.dart` | new — 15 compatibility/resilience tests (models, utils, widgets) |
| `pubspec.yaml` / `pubspec.lock` | `flutter_cache_manager` added to dev_dependencies (for deterministic network-failure widget test) |
| `PHASE3_PLAN.md` | 3E½ marked complete |

## Notes / limitations
- Cancelled-picker paths are verified by **code inspection** (they return before any loading flag is set) because `ImagePicker` is constructed inline and cannot be injected/mocked in widget tests; the no-stuck-state property is covered end-to-end by the failing-backend panel test.
- No API-contract issue was discovered, so no STOP-and-report condition triggered. Backend remains frozen.

## Next
Per execution order, **3F — end-to-end validation** (register → photo → docs → submit → admin approve → online → ride → driver card on WS/REST → admin detail) — **awaiting approval.**
