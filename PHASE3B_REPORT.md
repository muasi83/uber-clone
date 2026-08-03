# Phase 3B Report — Rider Profile Photo + Full Profile Update

**Status: COMPLETE (awaiting approval before 3C1).**
**Date:** 2026-08-02
**Backend frozen throughout — zero backend source changes (git file-set identical to the 3A snapshot).**

## Scope delivered (Flutter only)
1. **Rider profile photo upload/remove** (`lib/screens/rider_profile_screen.dart`):
   - Camera / gallery bottom-sheet stubs replaced with real `image_picker` actions (`ImageSource.camera` / `.gallery`), downscaled to 1024px @ q85 to stay well under the backend 10MB limit.
   - Upload via the existing **`PhotoService.uploadPhoto`** (`POST /api/photos/upload`, multipart `file`); `_isUploading` spinner on the avatar; success sets local `_photoUrl`, failure shows SnackBar.
   - Remove-photo only shown when a photo exists; calls **`PhotoService.deletePhoto`** (`DELETE /api/photos`), treats 404 (already gone) as success.
   - New shared `UserAvatar` now renders the profile photo with letter-initial fallback (null / empty / loading / failure).
2. **`PhotoService` integrated + extended** (`lib/services/photo_service.dart`):
   - Added `deletePhoto(token)` and `resolvePhotoUrl(path?)` (relative `/uploads/…` → absolute server URL; passes through absolute http(s); null-safe) — the missing plumbing that made the service dead code usable.
3. **Profile save flow extended** (`_save`):
   - Sends **`countryCode`** (+`phoneNumber`) → backend recomputes `normalizedPhone` and resets `phoneVerified=false`.
   - **Password change**: optional `currentPassword`/`newPassword`/`confirmPassword` sent only when any field is filled; backend 400 messages surfaced to the user ("Current password is incorrect", "New passwords do not match", "Password must be at least 6 characters", "Phone number already registered", "Email already in use").
   - **JWT refresh**: on success the returned `token` (present when gender changed or email in body) is stored via `StorageService.saveToken` AND held in a mutable `_token` state so subsequent saves use the refreshed token.
   - **photoUrl** from the response is adopted locally; gender persisted via `StorageService.saveGender`.
   - Proper error handling (no more swallowed exceptions / unconditional success snackbar).
   - UI: phone row now uses `CountryCodePicker` (matches auth screen) prefilled from the stored countryCode; added "Change Password" section with three `PremiumTextField`s; removed the stale read-only "Country Code:" text.
4. **`user_avatar.dart` adoption in account screens**:
   - `rider_profile_screen.dart` avatar (radius 48) + `account_screen.dart` profile header (radius 32) now use `UserAvatar` with resolved photoUrl.
   - `account_screen` reloads the user after returning from profile edit so the header photo/name refresh.

## Deliberately out of scope (noted)
- `settings_screen.dart` / `chat_screen.dart` avatars **not** adopted: neither has a `photoUrl` data source yet (settings shows `username` initial; chat shows `receiverName` initial). Adopting without a photo source would only change visuals with no functional gain. Candidate for 3E½/3D when photos flow to those surfaces.
- Driver onboarding, admin, driver-card — untouched (later sub-phases).

## Verification matrix
| Check | Result |
|---|---|
| `flutter pub get` | ✅ (no change; image_picker already resolved in 3A) |
| `flutter analyze` | ✅ **0 errors** — 284 issues (baseline was 286; removed 2 pre-existing lints while editing: unused `app_shadows.dart` import, unnecessary `const`) |
| `flutter build apk --debug` | ✅ built |
| `flutter test` (full suite) | ✅ **16/16** (11 from 3A + 5 new `PhotoService.resolvePhotoUrl` tests) |
| Backend frozen | ✅ git file-set identical to 3A snapshot; no `.java` content changes |

## Live backend regression (backend on localhost:8080, user 20)
| # | Check | Result |
|---|---|---|
| 1 | `POST /api/photos/upload` (multipart `file`) → `{photoUrl}` | ✅ 200 |
| 2 | `GET /api/photos/20` → photoUrl matches upload | ✅ 200 |
| 3 | `DELETE /api/photos` → `{message: Photo deleted}` | ✅ 200 |
| 4 | `GET /api/photos/20` after delete → `{}` (matches `PhotoService` expectations) | ✅ 200 |
| 5 | `PUT /api/users/20` fullName+phone+countryCode+gender (same values) → 200, countryCode `+966` kept, `phoneVerified:false`, `photoUrl` present | ✅ 200 |
| 6 | `PUT` with wrong `currentPassword` → 400 `"Current password is incorrect"` | ✅ 400 |
| 7 | Password change `phase2c-pw` → `phase2c-new` → 200; login with new password → 200 | ✅ |
| 8 | Revert password (password fields only) → 200; login `phase2c-pw` → 200 | ✅ |
| 9 | Gender MALE→FEMALE → token **reissued** (non-null), gender reflected | ✅ |
| 10 | Gender FEMALE→MALE → token reissued; saved to `token20c.txt` | ✅ |

## Contract observations (frozen backend, consumed as-is — flagged, not changed)
- **`email` in the PUT body resets `isVerified=false` and reissues a token even when the email is unchanged.** The Flutter `_save` always sends email, so every profile save from the app will (a) mark the account unverified and (b) return a fresh token. The app consumes this correctly (saves the token, no verification UI broken in 3B), but this is a UX consequence worth a future backend decision — flagged for the user, **not** modified per the freeze.
- Login/register/verify-otp responses include `photoUrl` (already the case from 2C).

## Test-account state after 3B (cleanup done)
- User 20 `phase2brider`: gender **MALE** (restored), password **phase2c-pw** (restored), `isVerified=true` (re-verified via psql after the email-reset observation), has a photo (`/uploads/photos/20_9e559568-….png`), token refreshed in `token20c.txt`.

## Files changed (Flutter only)
| File | Change |
|---|---|
| `lib/services/photo_service.dart` | + `deletePhoto`, + `resolvePhotoUrl` |
| `lib/screens/rider_profile_screen.dart` | photo picker/upload/remove, `UserAvatar`, country-code picker, password-change fields, full `_save` (countryCode/password/token/photoUrl), error surfacing |
| `lib/screens/account_screen.dart` | `UserAvatar` header, reload after profile edit |
| `test/phase3a_models_avatar_test.dart` | +5 `resolvePhotoUrl` tests |

## Next step
Await approval, then begin **Phase 3C1 — Driver profile UI** (vehicleYear field, verificationStatus banner on driver home, `DriverProfile` field rendering; no documents yet).
