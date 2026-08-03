# Profile & Photo Chapter — Complete Engineering Implementation Plan (DESIGN REVIEW)

**Status:** Design Review — NO CODE, NO DB CHANGES
**Source of truth:** `PHOTO_DRIVER_DOCS_INVESTIGATION.md` (434 lines) + verified file reads
**Date:** 2026-08-01
**Constraint:** Zero regression on ride flow, payment, wallet, chat, WebSocket, verification, settlement.
**Execution contract:** One phase at a time. Compile + analyze + regression before advancing. No silent behavior changes. No work outside approved scope.

---

## 0. ORDERING RATIONALE

The phases are ordered so that each step leaves the system in a working state and later steps build on verified foundations:

1. **Phase A (backend photo hardening)** first because it fixes path traversal (a live vulnerability), establishes the upload contract (allowlist, size, 413, delete), and creates the reusable file-serving pattern. Everything else (avatars, documents) depends on it.
2. **Phase B (profile model)** makes `User` and `DriverProfile` complete (photoUrl, vehicleYear, verified fields) so all response builders can start exposing them.
3. **Phase C (driver documents)** adds the new domain (entity, upload, review, serving) — independent of profiles, built on Phase A's serving pattern.
4. **Phase D (driver profile)** gives the driver a full view/edit screen, consuming Phases B+C.
5. **Phase E (rider profile)** fixes all rider bugs, consumes Phase B.
6. **Phase F (trip acceptance)** adds driver photo + vehicle to ride payloads (additive only, zero ride-flow impact).
7. **Phase G (admin)** adds admin visibility, consuming B+C.

Each phase is independently testable and reversible.

---

## PHASE A — PHOTO INFRASTRUCTURE

### Why it exists
The current photo pipeline (`PhotoController.java:21-49`, `PhotoService.java:27-61`) is unsafe (path traversal via client filename, `PhotoService.java:33-35`; any file type, `:58-61`), incomplete (no delete, orphan files on replace, `:40`), and unintegrated (Flutter `PhotoService` `photo_service.dart:8-46` never called). Before avatars and documents can be built, the upload path must be hardened and the serve path must be defined.

### Current architecture
- `POST /api/photos/upload` (`PhotoController.java:21-38`): Bearer auth, any role, field `file`, fully buffered (`file.getBytes()`, `PhotoService.java:36`), filename `userId_UUID.<ext>` from client filename, writes to `uploads/photos/` relative to CWD.
- `GET /api/photos/{userId}` (`PhotoController.java:40-49`): no ownership check; returns URL string.
- Serving: `StaticResourceConfig.java:12-13` maps `/uploads/**` → `file:uploads/`; **not permitAll** (`SecurityConfig.java:58` → `anyRequest().authenticated()`), so browser `<img>`/`Image.network` cannot load without a Bearer header.
- Storage: `profile_photos` table (id, user_id, photo_url, uploaded_at) (`ProfilePhoto.java:8-25`); 10MB multipart cap (`application.yml:35-36`); oversize → 500 (`GlobalExceptionHandler.java:31-35`).
- Flutter: `image_picker` NOT installed; camera/gallery are snackbar stubs (`rider_profile_screen.dart:110-126`); `cached_network_image` declared but unused (`pubspec.yaml:53`); zero `Image.network` usage.

### Weaknesses found
- **CWE-22 path traversal:** extension taken from `originalFilename` after last `.` and concatenated into the resolved path (`PhotoService.java:33-35,58-61`).
- **CWE-434 arbitrary upload:** no content-type/extension whitelist (`.html`, `.exe` accepted).
- No delete endpoint; old physical file never deleted on replace (orphan accumulation).
- No ownership check on metadata read.
- Oversize → 500 not 413.
- No upload rate limiting (`RateLimitingFilter.java:86-108` doesn't cover photos).
- `uploads/` not gitignored (`.gitignore` has only `/target/`).
- Whole file buffered in memory.
- `/uploads/**` behind auth breaks `<img>` rendering.

### Proposed final architecture
- **Avatar serving = public:** add `.permitAll()` for `/uploads/photos/**` only (UUID filenames are unguessable; avatars are non-sensitive). Flutter renders via `CachedNetworkImage`.
- **Private documents = separate controller, never under `/uploads/photos/**`** (see Phase C).
- **Upload hardening:** server-generated filename (never client), extension allowlist {jpg,jpeg,png,webp}, magic-byte/content-type validation, per-user quota + rate limit, delete old file on replace, 413 handler, streaming-safe write, optional client-side compression.
- **Ownership:** photo metadata read self-only (or public for avatars); write always self (from token).

### Files to modify
| File | Why this is the correct place |
|---|---|
| `chatserver/src/main/java/com/example/chatserver/service/PhotoService.java` | All upload/storage/validation/cleanup logic lives here. |
| `chatserver/src/main/java/com/example/chatserver/controller/PhotoController.java` | Endpoint contract (upload/delete), ownership enforcement. |
| `chatserver/src/main/java/com/example/chatserver/config/SecurityConfig.java` | Add `/uploads/photos/**` permitAll; keep documents out of static path. |
| `chatserver/src/main/java/com/example/chatserver/controller/GlobalExceptionHandler.java` | Add `MaxUploadSizeExceededException` → 413. |
| `chatserver/src/main/java/com/example/chatserver/config/RateLimitingFilter.java` | Add upload rate-limit rule. |
| `chatserver/.gitignore` | Ignore `uploads/`. |
| `chat_app/lib/services/photo_service.dart` | Already wraps upload/get; add delete + image fetch headers; make it the only photo client. |
| `chat_app/pubspec.yaml` | Add `image_picker`. |
| `chat_app/lib/l10n/app_en.arb` + `app_ar.arb` | New labels (upload/delete errors, formats). |

### APIs — Phase A
- `POST /api/photos/upload` — **modified:** validate type/size; sanitize filename; delete prior file+row; optional `documentType=PROFILE` reserved for future.
- `DELETE /api/photos` — **added (self-only).**
- `GET /api/photos/{userId}` — **modified:** self-or-public rule.
- Serving `/uploads/photos/**` — **modified:** permitAll.
- 413 for oversize — **added.**

### Database — Phase A
- None required. `profile_photos` unchanged (journal of uploads). Filename changes only (new server-generated names).
- If the existing `profile_photos` rows exist with old names, they remain valid (already on disk).

### Flutter impact — Phase A
- `photo_service.dart` becomes the sole photo client (upload/delete/fetch).
- No screens change yet (wiring happens in D/E).
- `flutter analyze` must stay at 0 errors (baseline 286 issues).

### Regression risk — Phase A
- **Low-to-medium.** The only shared surface is `SecurityConfig`. Risk: accidentally exposing `/uploads/documents/**` when adding permitAll. Mitigation: use a distinct prefix `/uploads/photos/**` for avatars and never add `/uploads/**` broadly.
- `/api/photos/upload` is currently never called by any UI → changing its contract breaks nothing in-app.

### Verification — Phase A
- `mvn -q compile` (EXIT=0).
- curl: upload valid jpg/png/webp (200), upload .exe/.html (400), oversize (413), replace deletes old file (filesystem check), delete endpoint removes row+file, unauthenticated download of `/uploads/photos/...` (200 now).
- Confirm `/uploads/documents/**` is NOT served (403/404).
- Re-run settlement baseline (byte-identical) — proves SecurityConfig change didn't disturb admin/auth paths.

---

## PHASE B — PROFILE MODEL (Rider + Driver)

### Why it exists
`User` has no `photoUrl` (`User.java` fields end at gender `:65-68`); `DriverProfile` lacks `vehicleYear`, `vehiclePhotoUrl`, and never populates `verifiedAt`. These fields must exist before response builders, Flutter models, and screens can consume them. Also fixes the JSON key bug (`getVerified()` → `"verified"` vs Flutter `isVerified`, `models.dart:47`).

### Exactly which fields will exist (target)

**`User` entity additions** (`entity/User.java`):
- `photoUrl VARCHAR` (avatar path, non-sensitive) — nullable.
- (fix) serialize `isVerified` via `@JsonProperty("isVerified")` on `getVerified()` (`User.java:95`).

**`DriverProfile` entity additions** (`entity/DriverProfile.java`):
- `vehicleYear INTEGER` (nullable).
- `vehiclePhotoUrl VARCHAR` (nullable, future-ready).
- (fix) populate `verifiedAt` on register (`DriverController.java:71`) and on admin verify (`AdminController.java:644`).

**Complete per-role field matrix:**

| Field | Rider | Driver | Source |
|---|---|---|---|
| id, username, fullName, email, phoneNumber, countryCode, normalizedPhone, phoneVerified, gender, role | ✅ | ✅ | `User.java` |
| photoUrl | ✅ (new) | ✅ (new, same column) | `User.java` (new) |
| isVerified (email) | ✅ (key fixed) | ✅ | `User.java:95` |
| licenseNumber, vehicleNumber, vehicleType, vehicleModel, vehicleColor | — | ✅ | `DriverProfile.java:22-35` |
| vehicleYear | — | ✅ (new) | `DriverProfile.java` (new) |
| vehiclePhotoUrl | — | ✅ (new, future-ready) | `DriverProfile.java` (new) |
| isVerified (driver doc approval), isActive, averageRating, totalRides, isOnline, lastSeenAt, createdAt, verifiedAt | — | ✅ | `DriverProfile.java` |

### Exactly which APIs return them
- `GET /api/users/{id}` — **modified** to return sanitized DTO: `{id, username, fullName, email, phoneNumber, countryCode, gender, role, photoUrl, isVerified, phoneVerified}` (owner-or-admin; no `normalizedPhone`, no `password`/`deviceToken`).
- `PUT /api/users/{id}` — **modified** response same shape + `photoUrl`.
- `POST /api/auth/register` + `POST /api/auth/login` — **modified** to include `photoUrl` in `AuthResponse.java:9-14` (after upload wiring; additive).
- `GET /api/drivers/profile` (`DriverController.java:256-282`) — **modified** `buildDriverResponse` to add `photoUrl`, `vehicleYear`, `vehiclePhotoUrl`, `verifiedAt`, `lastSeenAt` (already sent), `phoneNumber`/`email` (owner-only).
- `PUT /api/drivers/profile` — **modified** to accept personal fields.
- `buildUserInfo` (`RideController.java:352-358`) — **modified** to add `photoUrl` (used by every ride response).

### Files to modify
- `chatserver/.../entity/User.java`, `entity/DriverProfile.java`
- `chatserver/.../controller/UserController.java`, `controller/DriverController.java`, `controller/AuthController.java`
- `chatserver/.../dto/AuthResponse.java`, `dto/UserResponse.java` (new)
- `chat_app/lib/models/models.dart` (User: add photoUrl, fix isVerified), `chat_app/lib/models/ride_model.dart` (DriverProfile: add photoUrl/vehicleYear/vehiclePhotoUrl/verifiedAt/lastSeenAt; fix fake-email default `models.dart:39`)

### Database — Phase B
- `users`: add `photo_url VARCHAR`.
- `driver_profiles`: add `vehicle_year INTEGER`, `vehicle_photo_url VARCHAR`.
- (No new index/constraint needed for these columns.)

### Regression risk — Phase B
- **Medium.** `GET /api/users/{id}` currently returns the raw entity; `account_screen.dart:38-59` and the rider profile read it. The DTO change must include every key the Flutter `User.fromJson` reads. Fix the `isVerified` key **in the same change** as the Flutter model update (otherwise UI breaks). `buildUserInfo` addition is purely additive → safe.

### Verification — Phase B
- `mvn -q compile`; backend restart; `GET /api/users/{id}` returns new shape (self + admin), no `normalizedPhone`/`password`.
- `flutter gen-l10n` (if new strings) + `flutter analyze` 0 errors.
- Rider profile loads with new model fields.
- Settlement + verification baselines byte-identical.

---

## PHASE C — DRIVER DOCUMENTS

### Why it exists
The core requirement: driver must submit **profile photo, driving licence, passport/National ID, car registration, car insurance** with registration. No document concept exists today (only `licenseNumber` string + auto-`isVerified(true)`, `DriverController.java:66`). **Option B (dedicated `DriverDocument` entity)** chosen over extending `ProfilePhoto` — rationale in investigation §5.1 (lifecycle/status/expiry/audit/serving separation).

### How each item is handled
| Item | Storage | Type | Mandatory? |
|---|---|---|---|
| Driver profile photo | `users.photo_url` (avatar, Phase B) — public | PROFILE | **Yes** (registration) |
| Driving licence | `driver_documents` row + file | DRIVING_LICENCE | **Yes** |
| Passport / National ID | `driver_documents` row + file | PASSPORT_ID | **Yes** |
| Car registration | `driver_documents` row + file | CAR_REGISTRATION | **Yes** |
| Car insurance | `driver_documents` row + file | CAR_INSURANCE | **Yes** |

### Storage
- Files on disk: `uploads/documents/<driverId>/<documentType>_<uuid>.<ext>` — **outside the public `/uploads/photos/**` prefix**, served only through an authenticated endpoint.
- Metadata: new `driver_documents` table (schema in §DATABASE).
- File bytes never in DB (only path + size + type).

### Replacement
- Upload of the same `documentType` **soft-deletes** the prior active row (sets `verification_status='SUPERSEDED'` or marks `replaced_by`), keeps history, physically deletes the old file. One active doc per `(driver_id, document_type)` via unique partial constraint.

### Retrieval
- `GET /api/drivers/documents` (self): list with statuses (no file bytes).
- `GET /api/driver-documents/{driverId}/{documentId}/file`: owner-or-ADMIN; streams bytes with correct `Content-Type` and `Content-Disposition: inline` (view) / `attachment` (download).
- Admin list/zoom/download via `/api/admin/drivers/{driverId}/documents*`.

### Security
- Every read: explicit check `callerId == driver.userId || role == ADMIN` (reject otherwise).
- No static serving for documents; no permitAll under documents path.
- Upload: owner-only (token userId must own the driver profile), type allowlist {jpg,jpeg,png,pdf,webp}, size cap, magic-byte check, rate limit, quota.
- Filename fully server-generated (no client input).

### Validation
- `documentType` must be one of the 4 enum values (400 otherwise).
- File present, non-empty, allowed type, ≤ size (e.g., 8MB), content-type matches extension.
- Owner must have a registered driver profile (400 if none).

### Mandatory vs optional
- **Mandatory at driver registration:** all 4 documents + profile photo (per requirement "must be sent along with his registration"). Backend: driver registration endpoint rejects if any mandatory document missing **or** create profile with `isVerified=false` + a `DRIVER_DOCS_PENDING` state until documents uploaded. → **Open Question Q1/Q2.**
- **Recommended default (if approved):** driver profile created with `isVerified=false`, documents uploaded immediately in the same wizard; matching/going-online blocked until admin approves all docs (ties into Q2).

### Files to modify
- **New:** `chatserver/.../entity/DriverDocument.java`, `repository/DriverDocumentRepository.java`, `service/DriverDocumentService.java`, `controller/DriverDocumentController.java`, `dto/DriverDocumentResponse.java`
- `chatserver/.../controller/AdminController.java` (admin doc endpoints + audit)
- `chatserver/.../controller/DriverController.java` (register validation hook)
- `chatserver/.../config/GlobalExceptionHandler.java` (doc-specific errors)
- `chat_app/lib/models/driver_document.dart` (new)
- `chat_app/lib/services/driver_service.dart` (document methods)
- `chat_app/lib/screens/driver_registration_screen.dart` (upload steps)
- `chat_app/lib/screens/driver_profile_screen.dart` (documents list/status)

### APIs — Phase C
- `POST /api/drivers/documents` (multipart: file, documentType) — **added, owner-only.**
- `GET /api/drivers/documents` — **added, self.**
- `GET /api/driver-documents/{driverId}/{documentId}/file` — **added, owner-or-admin.**
- `DELETE /api/drivers/documents/{documentId}` — **added, owner (PENDING only) or admin.**
- `GET /api/admin/drivers/{driverId}/documents` — **added, admin.**
- `POST /api/admin/drivers/{driverId}/documents/{documentId}/approve` | `/reject` | `/request-reupload` | `/expire` — **added, admin**, each writes an audit event.

### Database — Phase C
- New table `driver_documents` (§DATABASE) + partial unique index + FK to `driver_profiles.id`.

### Regression risk — Phase C
- **Low.** Entirely new domain; no existing endpoint modified. Audit events are additive. The only shared risk is `GlobalExceptionHandler` (additive handler) and `SecurityConfig` (must not expose documents path).

### Verification — Phase C
- `mvn -q compile`; upload each type (200), invalid type (400), wrong file type (400), oversize (413), replace (old file gone, new active), self-list, file fetch as owner (200) / other user (403) / admin (200), delete, admin approve/reject/request-reupload/expire + audit rows in `ride_audit_events`.

---

## PHASE D — DRIVER PROFILE

### Why it exists
Driver "profile" today is a read-only overlay (`driver_home_screen.dart:2121-2199`) showing only name/rating/rides/vehicle model; the driver cannot see or edit anything else. Requirement: driver must see and change all his data.

### Everything the driver can EDIT (through new `DriverProfileScreen`)
| Field | Via endpoint |
|---|---|
| fullName, email, phoneNumber (+countryCode), gender | `PUT /api/users/{id}` (fixed in Phase B/E) |
| profile photo (avatar) | `POST /api/photos/upload` + `DELETE /api/photos` |
| licenseNumber, vehicleNumber, vehicleType, vehicleModel, vehicleColor, vehicleYear | `PUT /api/drivers/profile` (extended) |
| vehicle photo (if Q3 = yes) | `POST /api/photos/upload?documentType=VEHICLE` or dedicated |
| documents (upload/replace/delete) | Phase C endpoints |

### Everything the driver can only VIEW
- `averageRating`, `totalRides`, `createdAt`, `lastSeenAt`, `verifiedAt`, `isVerified` (doc approval status), `isActive`.

### Everything requiring admin approval
- Document approval (per-type status PENDING→APPROVED/REJECTED).
- `isVerified=true` (drives ride matching if Q2 approved).
- `isActive` (block/unblock) — admin only (unchanged).

### How profile synchronization works
- `DriverProfileScreen` loads once from `GET /api/drivers/profile`, edits push back, then `await Navigator.push(...)` → re-fetch on return so `driver_home_screen.dart:127-144` profile overlay refreshes.
- Local: `StorageService` persists `fullName`, `phoneNumber`, `photoUrl` alongside existing token/userId/username/role/gender (`storage_service.dart:11-15`).
- Online-status de-dup fix: `driver_profiles.is_online` becomes source of truth; `users.is_online` kept in sync in `DriverController.toggle-online` (`:149-182`), `AuthController.login` (`:214`), logout (`UserController.java:85-93`).

### Files to modify
- `chat_app/lib/screens/driver_profile_screen.dart` (NEW — full edit screen)
- `chat_app/lib/screens/driver_home_screen.dart` — replace overlay content or add menu entry in `_showMenuSheet` (`:2279-2360`)
- `chat_app/lib/services/driver_service.dart` — add `updateDriverProfile`, `updatePersonalInfo`, document methods
- `chat_app/lib/services/photo_service.dart` — reuse for avatar
- `chatserver/.../controller/DriverController.java` — extend PUT + response
- `chatserver/.../controller/UserController.java` — personal fields path (Phase E)

### Database — Phase D
- None beyond Phases B+C.

### Regression risk — Phase D
- **Low-to-medium.** Touches driver home menu + overlay. The overlay is rendered conditionally (`driver_home_screen.dart:890`, nav index 2). Replacing it with a navigable screen must preserve the nav-destination behavior. Additive PUT fields only.

### Verification — Phase D
- `flutter analyze` 0 errors; `flutter gen-l10n`.
- Manual: driver logs in → profile screen shows all fields → edit each → DB confirms → re-open shows updated → documents visible with statuses → photo uploads/replaces/removes.
- Driver home still renders, toggle-online still works, `users.is_online` and `driver_profiles.is_online` in sync.

---

## PHASE E — RIDER PROFILE

### Every issue found (from investigation §4)
- **A.** Stale UI after edit — `account_screen.dart:33-59` initState-only + const in `IndexedStack` (`rider_home_screen.dart:861`).
- **B.** Phone edit doesn't recompute `normalizedPhone`/`countryCode`/`phoneVerified` — `UserController.java:147-149`.
- **C/F.** Email change doesn't re-issue JWT (subject=email, `JwtUtil.java:40`).
- **D.** `normalized_phone` unique constraint entity-only.
- **E.** `isVerified` JSON key mismatch — `User.java:95` vs `models.dart:47`.
- **G.** Email/phone verification screens are dead stubs (`email_verification_screen.dart:36`, `phone_verification_screen.dart:63,75`).
- **H.** `_save()` swallows errors + false success — `rider_profile_screen.dart:79-85`.
- **I.** fullName/email/phone never persisted locally.
- **J.** countryCode not editable.
- **K.** Photo feature dead — `rider_profile_screen.dart:110-133`.
- **L.** `GET /api/users/{id}` PII leak — `UserController.java:106-117`.
- **41.** Account header edit icon not tappable — `account_screen.dart:285-288`.

### Phone synchronization (fix)
- `PUT /api/users/{id}`: when `phoneNumber` or `countryCode` present → recompute `normalizedPhone` (reuse `AuthController.normalizePhone`, `:554-561` → extract to shared util), enforce normalized-phone uniqueness (400 on conflict), reset `phoneVerified=false`.
- Flutter sends `countryCode` + `phoneNumber` together.
- UI: phone-verified badge clears on change; re-verification flow (Q6) re-set.

### Storage synchronization (fix)
- Add `StorageService.saveFullName/saveEmail/savePhoneNumber/savePhotoUrl`; call after successful PUT; `AccountScreen` header + `SettingsScreen` name read from storage fallback to fetched user.
- Persist on register/login too.

### Photo synchronization (fix)
- `RiderProfileScreen` avatar: pick (camera/gallery via `image_picker`) → `PhotoService.uploadPhoto` → display `CachedNetworkImage(photoUrl)` → "Remove" calls `DELETE /api/photos` → initial fallback.
- After upload, update local `photoUrl` + propagate to `AccountScreen`.

### Refresh logic (fix)
- Change `account_screen.dart:128-137` navigation to `await Navigator.push(...); _loadUser();` (re-fetch on return). This alone fixes stale UI without adding state management.
- (Alternative if preferred: lift user into a `ChangeNotifier` — but minimal fix is await+refetch; **recommend minimal** to limit regression surface.)

### Validation (fix)
- `_save()`: only show success on 200; surface 400/network errors with localized messages; validate email/phone format client-side before PUT.

### Files to modify
- `chatserver/.../controller/UserController.java` (phone/countryCode/email/password branch, response)
- `chatserver/.../util/PhoneNormalizer.java` (NEW, extracted from `AuthController.normalizePhone`)
- `chatserver/.../dto/UserResponse.java` (NEW, sanitized user DTO)
- `chat_app/lib/screens/rider_profile_screen.dart`
- `chat_app/lib/screens/account_screen.dart`
- `chat_app/lib/screens/settings_screen.dart` (read storage-backed name)
- `chat_app/lib/services/storage_service.dart`
- `chat_app/lib/services/user_service.dart` (NEW — consolidate GET/PUT)
- `chat_app/lib/models/models.dart`

### APIs — Phase E
- `GET /api/users/{id}` — **modified** → `UserResponse` DTO (adds photoUrl, fixes isVerified key, removes normalizedPhone).
- `PUT /api/users/{id}` — **modified:** phone/countryCode normalization + uniqueness + phoneVerified reset; email change re-issues JWT; optional password branch; returns `UserResponse`.
- (Password-change UI → Q4.)

### Database — Phase E
- None beyond Phase B. (Optional: add real unique constraint on `users.normalized_phone` — see Q7/regression note; recommend adding via migration in Phase E.)

### Regression risk — Phase E
- **Medium.** `GET /api/users/{id}` shape change is consumed by `account_screen.dart`, `rider_profile_screen.dart`, and driver flows. Must update Flutter model + all readers in the same commit. `PUT` response shape change similarly. Fix `isVerified` key atomically with model.
- `UserResponse` must contain every key `User.fromJson` reads.

### Verification — Phase E
- `mvn -q compile`; curl: PUT phone (normalizedPhone updated in DB, uniqueness enforced, phoneVerified reset), PUT email (new token returned), PUT gender (token), PUT with duplicate phone (400).
- `flutter analyze` 0 errors.
- Manual: edit name/phone/email/gender/photo on rider → save → Account header + profile refresh immediately; wrong data shows real error, not false success; app restart persists.

---

## PHASE F — TRIP ACCEPTANCE (rider sees driver)

### Why it exists
Requirement: on ride acceptance the rider must immediately see driver **photo, full name, rating, vehicle model, vehicle color, plate number** (vehicle photo future-ready). Currently name/rating/model/color/plate exist but with key inconsistencies and empty poll fallback; **photo is entirely missing**.

### What will be delivered per hop (all additive)
| Hop | Change |
|---|---|
| A: `buildRideResponse` (`RideController.java:316-327`) | add `photoUrl` (driver avatar) + `vehicleType`; keep existing keys |
| B: WS `ride_accepted` (`RideWebSocketService.java:86-110`) | add `driverPhotoUrl`; **align keys:** keep `driverName`/`licensePlate` AND add `fullName`/`vehicleNumber` (backward-compatible dual emit) OR standardize — see Q. Recommend adding `driverPhotoUrl` + keeping existing keys to avoid breaking `rider_tracking_screen.dart:670-674,819-844` |
| C: rider poll fallback (`rider_searching_driver_screen.dart:153-168`) | replace hard-coded `''` with real values from `Ride.fromJson` (needs Phase B model fields) |
| D: tracking render (`rider_tracking_screen.dart:801-813`) | letter avatar → `CachedNetworkImage(driverPhotoUrl)` with letter fallback |
| Recovery (`ride_recovery_service.dart:42-58`) | add vehicle + live coords + photo to `driverData` |
| Scheduled rides (`RideWebSocketService.notifyScheduledRideAssigned :284-315`) | add `driverPhotoUrl` |

**Ride flow impact: NONE.** The accept transaction (`RideService.java:103-145`) is unchanged; only response/payload maps gain keys. `buildUserInfo` (`RideController.java:352-358`) gains `photoUrl` (additive, used by all ride responses).

### Files to modify
- `chatserver/.../controller/RideController.java` (buildRideResponse + buildUserInfo)
- `chatserver/.../service/RideWebSocketService.java` (inject ProfilePhotoRepository or reuse a shared `PhotoResolver`; add photo to accepted + scheduled payloads)
- `chat_app/lib/models/models.dart` (User.photoUrl — from Phase B)
- `chat_app/lib/models/ride_model.dart` (Ride driver-map parsing: photoUrl, vehicle fields)
- `chat_app/lib/screens/rider_tracking_screen.dart`
- `chat_app/lib/screens/rider_searching_driver_screen.dart`
- `chat_app/lib/services/ride_recovery_service.dart`
- `chat_app/lib/widgets/driver_info_card.dart` (optional photo param)

### APIs — Phase F
- No endpoint signature changes. Response/payload maps gain keys (additive).

### Database — Phase F
- None.

### Regression risk — Phase F
- **Low.** Additive map keys only. The main risk is WS key handling in Flutter — mitigated by dual-emit (add new keys, keep old) so tracking screen never regresses. Ride flow, payments, wallet untouched.

### Verification — Phase F
- `mvn -q compile`; WS payload includes `driverPhotoUrl`; HTTP accept response includes `photoUrl`.
- Flutter: accept a ride as driver with a photo → rider sees photo+name+rating+model+color+plate in tracking; test poll fallback (kill WS) → same info; test recovery path.
- Full ride lifecycle (request→accept→arrive→start→complete→pay) regression.

---

## PHASE G — ADMIN

### Why it exists
Admin must verify driver documents and see profile photos. Today the admin surface has zero photo/document visibility and `verify` is a blind boolean toggle (`AdminController.java:634-661`).

### What admin should see (and nothing more)
- **Driver list/detail:** photoUrl (avatar), phone, license number, vehicle fields, verification status, documents summary (per-type status + upload date).
- **Document review:** per-driver document list with thumbnails, type, status, upload date, reviewer, note; actions approve/reject/request-reupload/expire; view inline (zoom) + download.
- **Rider list/detail:** photoUrl + existing fields.
- Audit: new events (`ADMIN_VIEWED_DOCUMENTS`, `ADMIN_APPROVED_DOCUMENT`, `ADMIN_REJECTED_DOCUMENT`, `ADMIN_REQUESTED_REUPLOAD`, `ADMIN_EXPIRED_DOCUMENT`) written via `AuditEventService`.

### What admin should NOT see
- Other users' private data beyond existing scope. Driver `normalizedPhone` not surfaced (keep phoneNumber only). Documents gated to admin role only.

### Files to modify
- `chatserver/.../controller/AdminController.java` (doc endpoints + DTO additions)
- `chatserver/.../dto/AdminDriverDetail.java` (add photoUrl, phone, licenseNumber, documents)
- `chatserver/.../dto/AdminRiderDetail.java` (add photoUrl)
- `chat_app/lib/screens/admin_driver_details_screen.dart`
- `chat_app/lib/screens/admin_driver_list_screen.dart`
- `chat_app/lib/screens/admin_rider_details_screen.dart`
- `chat_app/lib/screens/admin_rider_list_screen.dart`
- `chat_app/lib/screens/admin_document_review_screen.dart` (NEW)
- `chat_app/lib/services/admin_drivers_service.dart`, `admin_riders_service.dart`

### APIs — Phase G
- `GET /api/admin/drivers/{driverId}/documents` — **added.**
- `POST /api/admin/drivers/{driverId}/documents/{id}/approve|reject|request-reupload|expire` — **added.**
- `GET /api/admin/drivers/{driverId}/documents/{documentId}/file` — **added (download/zoom).**
- `GET /api/admin/drivers/{driverId}` — **modified** (add photoUrl, phone, licenseNumber, documents summary).
- `GET /api/admin/riders/{riderId}` — **modified** (add photoUrl).

### Database — Phase G
- None beyond Phase C.

### Regression risk — Phase G
- **Low.** New admin endpoints are additive. Modifying `AdminDriverDetail` adds fields only (existing admin screens ignore unknown keys). Audit events additive.

### Verification — Phase G
- `mvn -q compile`; curl: admin fetches documents list + file (200), non-admin (403), approve/reject sets status + writes audit row; driver detail includes phone/license/photoUrl.
- `flutter analyze` 0 errors; manual admin review flow end-to-end.

---

## DATABASE

**New table — `driver_documents`:**
```sql
CREATE TABLE driver_documents (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT NOT NULL REFERENCES driver_profiles(id),
  user_id BIGINT NOT NULL REFERENCES users(id),
  document_type VARCHAR(32) NOT NULL,   -- CAR_REGISTRATION | CAR_INSURANCE | DRIVING_LICENCE | PASSPORT_ID
  file_path VARCHAR(512) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(128) NOT NULL,
  file_size BIGINT NOT NULL,
  verification_status VARCHAR(16) NOT NULL DEFAULT 'PENDING',  -- PENDING|APPROVED|REJECTED|EXPIRED|SUPERSEDED
  admin_note VARCHAR(512),
  expires_at TIMESTAMP,
  uploaded_at TIMESTAMP NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMP,
  reviewed_by BIGINT REFERENCES users(id)
);

-- One active document per type
CREATE UNIQUE INDEX uq_driver_documents_active
  ON driver_documents(driver_id, document_type)
  WHERE verification_status <> 'SUPERSEDED';
```

**New columns:**
| Table | Column | Type | Purpose |
|---|---|---|---|
| `users` | `photo_url` | VARCHAR | Avatar path (Phase B) |
| `driver_profiles` | `vehicle_year` | INTEGER | (Phase B) |
| `driver_profiles` | `vehicle_photo_url` | VARCHAR | Future-ready (Phase B) |

**New constraints/indexes:**
| Object | Type | Purpose |
|---|---|---|
| `uq_driver_documents_active` | unique partial index | one active doc per (driver, type) |
| `ix_driver_documents_driver` | index on `driver_id` | list/filter perf |
| (recommended) `uq_users_normalized_phone` | unique on `users.normalized_phone` | enforce phone uniqueness in DB (Phase E) |

**Migration strategy:** Project uses Hibernate `ddl-auto: update` (no Flyway wired; V002/V003 SQL inert). **Recommendation: introduce Flyway** (`flyway-core` + `spring.jpa.hibernate.ddl-auto=validate` after baseline) for versioned, auditable schema — consistent with the production-readiness standard already flagged. If approved, the four-change set above ships as `V004__profile_photo_chapter.sql`. **Fallback (if Flyway not approved):** let Hibernate add columns/table, then run the partial unique index manually via psql. `uploads/` added to `.gitignore`.

---

## API REVIEW (complete)

### Remain unchanged
- All `/api/admin/settlement/**` (settlement) — untouched.
- All `/api/admin/rides/{id}/verification`, `/verify`, `/verification/backfill` (trip fraud) — untouched.
- `/api/payments/**`, wallet/earnings endpoints, `/api/rides/{id}/accept|start|complete|arrive|cancel` request handling (logic) — untouched.
- `/api/chat/**`, notifications, ratings, locations, routes, scheduled-rides core — untouched (except additive payload keys where noted).
- `/api/drivers/toggle-online`, `/api/drivers/location` — logic unchanged (Phase D sync fix is internal consistency only).

### Modified
| Endpoint | Change |
|---|---|
| `POST /api/photos/upload` | type/size validation, sanitized filename, orphan cleanup, delete old file |
| `DELETE /api/photos` | **new** self-only delete |
| `GET /api/photos/{userId}` | self-or-public ownership rule |
| `GET /api/users/{id}` | → `UserResponse` DTO (adds photoUrl, fixes isVerified key, drops normalizedPhone/PII) |
| `PUT /api/users/{id}` | phone/countryCode normalization + uniqueness + phoneVerified reset; email→JWT re-issue; optional password; returns UserResponse |
| `GET /api/drivers/profile` | add photoUrl, vehicleYear, vehiclePhotoUrl, verifiedAt, phone/email (owner) |
| `PUT /api/drivers/profile` | accept personal fields + vehicleYear + vehicle photo |
| `POST /api/auth/register` | additive `photoUrl` in response (after wiring) |
| `POST /api/auth/login` | additive `photoUrl` in response |
| `GET /api/rides/{rideId}` + accept response (`buildRideResponse`) | additive `driver.photoUrl`, `driver.vehicleType` |
| WS `ride_accepted` / `ride_confirmed` / scheduled-assigned payloads | additive `driverPhotoUrl` (+ dual-emit alias keys) |
| `GET /api/admin/drivers/{driverId}` | add photoUrl, phone, licenseNumber, documents summary |
| `GET /api/admin/riders/{riderId}` | add photoUrl |

### Added
| Endpoint | Auth |
|---|---|
| `POST /api/drivers/documents` | owner |
| `GET /api/drivers/documents` | owner |
| `GET /api/driver-documents/{driverId}/{documentId}/file` | owner-or-admin |
| `DELETE /api/drivers/documents/{documentId}` | owner(PENDING)/admin |
| `GET /api/admin/drivers/{driverId}/documents` | admin |
| `POST /api/admin/drivers/{driverId}/documents/{id}/approve` | admin |
| `POST /api/admin/drivers/{driverId}/documents/{id}/reject` | admin |
| `POST /api/admin/drivers/{driverId}/documents/{id}/request-reupload` | admin |
| `POST /api/admin/drivers/{driverId}/documents/{id}/expire` | admin |
| `GET /api/admin/drivers/{driverId}/documents/{documentId}/file` | admin |

### Removed
- None. All existing endpoints preserved (additive-only principle).

---

## FLUTTER REVIEW

### New screens
- `lib/screens/driver_profile_screen.dart` (Phase D)
- `lib/screens/admin_document_review_screen.dart` (Phase G)

### Modified screens
| Screen | Phase | Change |
|---|---|---|
| `lib/screens/rider_profile_screen.dart` | E/A | avatar pick/upload/remove, save fixes, countryCode, photo display |
| `lib/screens/account_screen.dart` | E | await-push refetch, tappable edit icon, avatar, isVerified fix, remove fake rating |
| `lib/screens/settings_screen.dart` | E | storage-backed name |
| `lib/screens/driver_home_screen.dart` | D | menu entry to driver profile screen; overlay refresh on return |
| `lib/screens/driver_registration_screen.dart` | C | mandatory photo + 4 document upload steps; failure handling + resume |
| `lib/screens/rider_tracking_screen.dart` | F | driver photo avatar + vehicle line |
| `lib/screens/rider_searching_driver_screen.dart` | F | poll fallback populated |
| `lib/screens/admin_driver_details_screen.dart` | G | photo, phone, license, documents link |
| `lib/screens/admin_driver_list_screen.dart` | G | avatar |
| `lib/screens/admin_rider_details_screen.dart` / `_list_screen.dart` | G | avatar |

### New models
- `lib/models/driver_document.dart` (C)

### Modified models
- `lib/models/models.dart` (User: photoUrl, isVerified key fix, remove fake-email default) — B/E
- `lib/models/ride_model.dart` (DriverProfile: photoUrl/vehicleYear/vehiclePhotoUrl/verifiedAt/lastSeenAt; Ride: driver-map photoUrl+vehicle fields) — B/F

### New services
- `lib/services/user_service.dart` (E) — consolidate GET/PUT users, error surfacing

### Modified services
- `lib/services/photo_service.dart` (A) — delete + fetch-headers + compression hook
- `lib/services/driver_service.dart` (C/D) — document methods + updateProfile
- `lib/services/ride_recovery_service.dart` (F) — vehicle/photo/coords
- `lib/services/storage_service.dart` (E/D) — persist fullName/email/phone/photoUrl

---

## SECURITY REVIEW

| Concern | Decision |
|---|---|
| **Ownership validation** | Photo upload: self from token (existing). Photo delete: self. Document read: owner-or-ADMIN. Document upload: owner. User GET/PUT: self-or-admin (fix IDOR `UserController.java:106-117`). |
| **Upload validation** | Extension allowlist {jpg,jpeg,png,webp} (+pdf for docs if approved); content-type match; magic-byte check; non-empty. |
| **File size** | 10MB global (unchanged); documents ≤ 8MB (configurable); oversize → **413** (new handler). |
| **Duplicate uploads** | Same type re-upload = replace (soft-delete prior, unique partial index); duplicate name impossible (server-generated UUID names). |
| **Replacement** | Delete old physical file + mark prior row SUPERSEDED. |
| **Deletion** | Self avatar delete; document delete owner(PENDING)/admin; physical file removed. |
| **Access control** | Avatars public (`/uploads/photos/**` permitAll, unguessable UUIDs). Documents private (controller-gated owner-or-admin, never static-served, never permitAll). |
| **Public/private** | Public: avatar files. Private: all documents, phone/email/normalizedPhone (DTO-gated), live GPS, license numbers (matched-parties/admin only). |
| **Path traversal** | Server-generated filenames only; no client path components; canonicalize + `startsWith(uploadRoot)` assert. |
| **Rate/abuse** | Upload rate limit + per-user quota; documents quota. |
| **Critical pre-existing (scope Q7)** | Self-admin registration (`AuthController.java:113`), default JWT secret (`application.yml:39`), PII IDORs, WS spoofing, committed secrets. **Recommended minimum for this chapter:** role allowlist at registration + `GET /api/users/{id}` DTO sanitization + upload hardening. Larger fixes tracked separately unless you expand scope. |

---

## REGRESSION REVIEW

| Feature | Risk | Notes |
|---|---|---|
| Ride request | Unaffected | `RideController` request path untouched |
| Matching | Unaffected | `findByStatus`/`findByIsOnline...` untouched (Phase B adds fields only) |
| Driver online toggle | Low | Phase D sync fix touches `DriverController.toggle-online`; must keep both tables consistent |
| Navigation (main.dart routes) | Low | Only menu entry added; `/driver-home`, `/rider-home`, `/rider-tracking` route args unchanged (Phase F additive) |
| Maps / location updates | Unaffected | `/api/locations/update`, driver location path untouched |
| Tracking | Low | Phase F additive keys + avatar swap; poll fallback now populated (improvement) |
| Payments | Unaffected | `PaymentService` untouched |
| Wallet / earnings | Unaffected | untouched |
| Settlement | Unaffected | untouched (baseline byte-identical check each phase) |
| Fraud verification (trip) | Unaffected | untouched |
| Chat | Unaffected | untouched |
| Notifications | Unaffected | untouched (separate pre-existing bugs 38/39 remain out of scope unless approved) |
| History | Unaffected | untouched |
| WebSocket | Low | payloads gain keys only; dual-emit preserves consumers |
| Authentication | **Medium** | Role allowlist (Q7) + `GET /api/users/{id}` DTO change; verify admin bootstrap + existing admin accounts; test login/register both roles |
| Registration | **Medium** | Driver registration gains mandatory docs (Q1/Q2); failure/resume handling changed |
| Localization | Low | new keys added to en+ar; existing keys unchanged |

---

## TEST PLAN (per phase, gate before advancing)

1. **Compile:** `mvn -q compile` (backend EXIT=0) / `flutter analyze` (0 errors, baseline 286 info/warnings unchanged).
2. **API tests (curl with admin token at `$env:TEMP\opencode\admin_token.txt`):** per-phase endpoints; assert status codes + exact JSON shapes.
3. **Database verification:** psql (`C:\Program Files\PostgreSQL\18\bin\psql.exe`, db `chat_db`) — column/table existence, indexes, uniqueness, file cleanup on replace/delete, audit rows.
4. **Manual Flutter:** run app against localhost:8080; exercise each changed screen on both roles.
5. **Regression suite:** settlement summary/driver-detail baseline byte-identical (30-day window); verification payloads (rides 282/285) unchanged; ride lifecycle; chat; WS.
6. **Report** after every phase with results before starting the next.

---

## OPEN QUESTIONS (awaiting your decision — no assumptions)

1. **Document requirement timing:** Are all 5 driver items (profile photo + licence + passport/ID + car registration + car insurance) **hard-required to complete registration**, or uploadable with a `PENDING` state and going-online blocked until approved? (Recommendation: mandatory at registration wizard.)
2. **Verification gating:** Should `isVerified` become a pending-until-admin-approves state (removing hard-coded `true` at `DriverController.java:66`), and should unverified drivers be excluded from matching? (Recommendation: yes.)
3. **Vehicle photo:** include now (adds upload + display for vehicle) or leave the `vehicle_photo_url` field future-ready only? (Recommendation: future-ready only.)
4. **Password change:** include in-app change-password (current+new) in this release, or defer? 
5. **Admin review scope:** full approve/reject/request-reupload/expire/audit workflow in this release, or a simpler view-only first pass?
6. **Email/phone verification screens:** wire to real OTP/email flows (backend work) or hide/stub-clear until backend support exists?
7. **Security scope:** Include only the minimum needed (role allowlist, user-DTO sanitization, upload hardening) in this chapter, or also fix the other critical findings (WS spoofing, IDOR on logout/rides/chat, JWT secret, committed secrets)? (Recommendation: minimum in-chapter; remainder tracked separately.)
8. **Migration tooling:** Introduce Flyway for versioned schema, or keep Hibernate `ddl-auto` + manual SQL for this chapter? (Recommendation: Flyway.)
9. **WS key alignment:** Dual-emit alias keys (`driverPhotoUrl` + existing) for backward compatibility, or standardize to one key set (requires coordinated Flutter change)? (Recommendation: dual-emit.)

---

**No code has been written. Awaiting your decisions on the Open Questions before Phase A begins.**
