# Phase 3A Report — Models + Avatar Foundation

**Status: COMPLETE (awaiting approval before 3B).**
**Date:** 2026-08-02
**Backend frozen throughout — zero backend source changes (verified via git on `chatserver`; all listed backend diffs are prior-phase work).**

## Scope delivered
1. **`image_picker ^1.2.3`** added to `pubspec.yaml` (line 71) via `flutter pub add image_picker`. Lockfile updated; platform plugin registrants (linux/macos/windows) regenerated automatically by the build — expected consequence of adding the dependency.
2. **`User.photoUrl`** added to `lib/models/models.dart` (`String?`, default null) — parsed in `fromJson` (null-safe, additive), serialized in `toJson`.
3. **`DriverProfile`** enriched in `lib/models/ride_model.dart` with 5 new additive nullable fields:
   - `photoUrl` (`String?`)
   - `vehiclePhotoUrl` (`String?`)
   - `vehicleYear` (`int?`)
   - `verificationStatus` (`String?`)
   - `verifiedAt` (`DateTime?`, parsed via `DateTime.tryParse`, null-safe)
   All wired through `fromJson`/`toJson` with no change to existing required fields.
4. **`lib/widgets/user_avatar.dart`** (new, shared): `UserAvatar` widget — renders `photoUrl` via `CachedNetworkImage` inside a `CircleAvatar` with letter-initial fallback. Fallback triggers when: `photoUrl == null`, `photoUrl` empty/whitespace, still loading (`placeholder`), or network image fails (`errorWidget`). Deterministic avatar color derived from name; overridable `radius`, `backgroundColor`, `foregroundColor`.

No UI screens were migrated to the widget, no rider/driver/admin functionality changed. Scope strictly 3A.

## Verification matrix
| Check | Result |
|---|---|
| `flutter pub get` | ✅ Succeeded (image_picker 1.2.3 resolved) |
| `flutter analyze` | ✅ 0 errors — 286 issues, exactly the documented pre-3A baseline (0 errors, infos/warnings unchanged); the single new lint introduced by 3A was fixed before final run |
| Debug build `flutter build apk --debug` | ✅ `app-debug.apk` built (401s; only plugin KGP warnings, pre-existing) |
| Backward-compat parsing (new keys absent) | ✅ Verified by tests (below) |
| Avatar fallback `photoUrl == null` | ✅ Shows initial letter |
| Avatar fallback `photoUrl == ""` | ✅ Shows initial letter |
| Avatar fallback `photoUrl == "   "` (whitespace) | ✅ Shows initial letter |
| Avatar fallback on network image failure | ✅ `errorWidget` → initial letter (test uses unreachable URL) |

## Tests added — `test/phase3a_models_avatar_test.dart` (11 tests, all passing)
- `User.fromJson` parses when `photoUrl` absent (backward compatible) and when present.
- `User.toJson` round-trips `photoUrl`.
- `DriverProfile.fromJson` parses when all 5 new keys absent (legacy payload) and when present.
- `DriverProfile.toJson` round-trips new keys.
- `UserAvatar` renders initial for null / empty / whitespace `photoUrl`, falls back to initial on network failure, and uses first character of name.

`flutter test test/phase3a_models_avatar_test.dart` → `All 11 tests passed`.

## Files changed (Flutter only)
| File | Change |
|---|---|
| `pubspec.yaml` | + `image_picker: ^1.2.3` |
| `pubspec.lock` | regenerated (image_picker + transitive deps) |
| `lib/models/models.dart` | `User.photoUrl` (field, ctor, fromJson, toJson) |
| `lib/models/ride_model.dart` | `DriverProfile` + 5 fields (field, ctor, fromJson, toJson) |
| `lib/widgets/user_avatar.dart` | **new** shared avatar widget |
| `test/phase3a_models_avatar_test.dart` | **new** verification tests |
| `linux/macos/windows/flutter/generated_plugin*` | auto-regenerated (image_picker platform plugins) |

## Backend
- **Frozen.** No source edits this phase. No API contract changes.

## Next step
Await approval of this report, then begin **Phase 3B — Rider profile photo + full profile update** (`image_picker` camera/gallery, `PhotoService.uploadPhoto`, avatar refresh, `_save` countryCode + password change, avatar adoption in account/settings/chat).
