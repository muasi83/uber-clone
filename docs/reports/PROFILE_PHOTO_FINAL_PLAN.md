# Profile, Avatar & Driver-Document System — Final Integrated Implementation Plan

**Status:** DESIGN ONLY — NO CODE, NO DB CHANGES
**Date:** 2026-08-01
**Scope:** One integrated feature: rider profile + driver profile + avatar system + driver documents + driver photo throughout the app + all profile fixes. All parts work together.
**Constraint:** ZERO regression. Auth, registration, trip flow, ride request/accept/completion, settlement, fraud verification, wallet, payments, notifications, chat, WebSocket, maps, history, admin — none may break.

---

## PART 1 — CURRENT SYSTEM AUDIT

### 1.1 Photo pipeline (exists, unsafe, unwired)

| Piece | Location | State |
|---|---|---|
| Upload endpoint | `PhotoController.java:21-38` `POST /api/photos/upload` | Works; any role; field `file`; fully buffered; **no type/size validation; path-traversal via client filename** |
| Photo service | `PhotoService.java:27-61` | Writes `uploads/photos/`; filename `userId_UUID.<ext>` from client filename (`:33-35`); deletes old DB row but **not old file** (`:40`); no allowlist (`:58-61`) |
| Photo entity/table | `ProfilePhoto.java` / `profile_photos` (id, user_id, photo_url, uploaded_at) | No unique constraint; no document-type; no fileName/contentType |
| Metadata read | `PhotoController.java:40-49` `GET /api/photos/{userId}` | **No ownership check**; any authenticated user can read any user's photo URL |
| Static serving | `StaticResourceConfig.java:12-13` `/uploads/**` → `file:uploads/` | **Behind auth** (`SecurityConfig.java:58`) → browser `<img>`/`Image.network` fails |
| Flutter client | `photo_service.dart:8-46` | Exists (upload/get) but **never called anywhere** (dead code) |
| Picker | none | `image_picker`/`file_picker` absent; `cached_network_image:^3.3.1` declared but unused (`pubspec.yaml:53`) |
| UI | `rider_profile_screen.dart:110-126` | Camera/gallery = snackbar stubs; "Remove photo" does nothing |
| Size cap | `application.yml:35-36` 10MB | Oversize → **500** (no 413 handler) |

### 1.2 Rider profile (bugs A–N)

- **A.** Stale UI after edit — `account_screen.dart:33-59` loads once in `initState`; const child of `IndexedStack` (`rider_home_screen.dart:861`); never re-fetched after save.
- **B.** Phone edit updates only `phoneNumber` (`UserController.java:147-149`) — never `normalizedPhone`, `countryCode`, `phoneVerified`.
- **C/F.** Email change never re-issues JWT (`UserController.java:139-146`); JWT subject = email (`JwtUtil.java:40`) → stale subject up to 24h.
- **D.** `normalized_phone` unique is entity-only (`User.java:49`); DB has no constraint; enforced only at registration.
- **E.** `isVerified` JSON key mismatch — getter `getVerified()` (`User.java:95`) serializes `"verified"`; Flutter reads `json['isVerified']` (`models.dart:47`) → always false.
- **G.** Email/phone verification screens dead stubs — `email_verification_screen.dart:36`, `phone_verification_screen.dart:63,75`.
- **H.** `_save()` swallows errors + false-success snackbar — `rider_profile_screen.dart:79-85`.
- **I.** fullName/email/phone never persisted locally (`storage_service.dart:11-15`); save writes only token+gender (`rider_profile_screen.dart:72-77`).
- **J.** countryCode not editable — no PUT branch, not in save body (`rider_profile_screen.dart:62-67`).
- **K.** Photo feature dead (see 1.1).
- **L.** `GET /api/users/{id}` returns full entity → PII leak (`UserController.java:106-117`; `User.java:23,44,47,50`).
- **41.** Account header edit icon not tappable (`account_screen.dart:285-288`); fake rating `4.8` (`:269`).

### 1.3 Driver profile (incomplete)

- Profile = read-only overlay (`driver_home_screen.dart:2121-2199`) showing only fullName, rating, totalRides, vehicle **model**.
- Hidden from driver: license number, plate, vehicle type/color, phone, email, gender, verified/active status, photo, documents.
- `PUT /api/drivers/profile` (`DriverController.java:185-214`) + `PUT /api/users/{id}` exist but **no driver UI calls them** (dead from driver app).
- `vehicleYear` **does not exist** anywhere.
- `verifiedAt` never set (always null); `isVerified=true` hard-coded at registration (`DriverController.java:66`).
- `isOnline` duplicated (`users.is_online` + `driver_profiles.is_online`) with sync bug.
- `lastSeenAt` dropped by Flutter model; not stamped on going offline.
- Fake email default `'unknown@test.com'` in Flutter model (`models.dart:39`).
- Overlay avatar uses `username[0]` not name/photo (`driver_home_screen.dart:2154-2155`).

### 1.4 Registration flows

- Rider: JSON `POST /api/auth/register` (`auth_screen.dart:156-175` → `AuthController.java:45-170`) creates users row; no photo.
- Driver: 3-step wizard → JSON `POST /api/drivers/register` (`driver_service.dart:33-39` → `DriverController.java:34-92`) creates driver_profiles row; no photo/docs.
- **Half-registered risk:** users row committed (`AuthController.java:142`), driver_profiles row separate request (`DriverController.java:74`). Failure → `registerAsDriver` swallows → returns false → **still navigates to DriverHome** (`driver_registration_screen.dart:128-143`).
- **No resume:** wizard state in-memory; role=DRIVER always routes to DriverHome on restart/login (`splash_screen.dart:123-133`, `auth_screen.dart:275-279`).
- `/api/drivers/register` not rate-limited.

### 1.5 Driver info shown to rider (every display point)

| Location | Fields shown | Avatar |
|---|---|---|
| `rider_searching_driver_screen.dart:153-168` | poll-fallback map (vehicle fields **hard-coded `''`**) | none |
| `rider_searching_driver_screen.dart:734-784` "Driver Found!" | nothing (checkmark only) | none |
| `rider_tracking_screen.dart:670-844` (Driver Arriving) | name, rating, vehicle `color model • plate` | letter CircleAvatar `:801-813` |
| `rider_tracking_screen.dart:519-521` | map marker title = name | none |
| `rider_active_ride_screen.dart:995-1049` | **name only** (no rating/vehicle/plate) | letter CircleAvatar `:1005-1014` |
| `rider_ride_completed_screen.dart:236-297` | name, rating | letter CircleAvatar `:249-262` |
| `trip_history_screen.dart:304-316` | **name only** | `Icons.person` |
| `scheduled_ride_detail_screen.dart:235-259` | name, phone | `Icons.person` |
| `rider_home_screen.dart:231-243` / pickup/dropoff map markers | name, `model • color` | map marker |
| `chat_screen.dart:401-413` | receiver name + online dot | letter CircleAvatar |
| Admin screens (list below) | name/email/vehicle/rating | letter initials or `Icons.person` |

**No `photoUrl` anywhere on the wire or in models.** WS payload (`RideWebSocketService.java:86-110`) uses `driverName`/`licensePlate`; HTTP (`RideController.java:312-350`) uses `fullName`/`vehicleNumber` (key inconsistency).

### 1.6 Admin

- No photo/document anywhere. `verify` = blind boolean toggle (`AdminController.java:634-661`). No doc audit. Driver phone/license not in `AdminDriverDetail`. Trip "verification" is GPS fraud scoring — unrelated to documents.

### 1.7 Security (critical, pre-existing)

- Self-register ADMIN (`AuthController.java:113` accepts client role).
- Default JWT secret fallback (`application.yml:39`).
- PII IDOR: `GET /api/users/{id}` (`UserController.java:106-117`).
- Raw-entity nearby-driver leak (`RideController.java:379`).
- Path traversal in photo upload (`PhotoService.java:33-35`).
- Logout IDOR, ride-cancel no ownership, chat history IDOR, WS identity spoofing, raw `List<Ride>` leak, committed secrets.

---

## PART 2 — MISSING FUNCTIONALITY

1. Rider: upload/replace/delete profile photo; correct phone update; refresh everywhere; honest save feedback.
2. Driver: full profile view/edit screen; all fields exposed; verification/approval status visible.
3. Driver documents: profile photo + car registration + car insurance + driving licence + passport/ID — entity, table, upload/replace/delete, review, expiry, audit.
4. Driver photo shown consistently to rider (Ride Accepted, Driver Arriving, Active Ride, Trip Details, Trip History, chat, admin).
5. `vehicleYear`; `vehiclePhotoUrl` (future-ready); `verifiedAt` population.
6. `photoUrl` on User/DriverProfile/Ride models + DTOs + payloads.
7. In-app password change (scope Q4).
8. Functional email/phone verification (scope Q6).
9. 413 handling; upload validation; delete endpoint; orphan cleanup; ownership checks; rate limits.
10. Localization (AR + EN) for all new labels.

---

## PART 3 — EXISTING BUGS (exact list)

Full inventory is in Parts 1.2–1.7 above (bugs A–N rider, 1–20 driver, 8–17 registration, 18–28 photo, 29–37 security, 38–41 UI). All will be addressed in the integrated plan; only the ones in approved scope (see Open Questions) are fixed now.

---

## PART 4 — EXISTING LIMITATIONS

- No shared avatar widget; 13+ duplicated letter-initial `CircleAvatar`s.
- No `Image.network`/`CachedNetworkImage` usage at all; `/uploads/**` behind auth blocks image rendering.
- No image compression/resizing (10MB raw buffers in memory).
- No Flyway (schema via Hibernate `ddl-auto: update`; V002/V003 inert).
- `uploads/` not gitignored.
- No refresh-token/revocation mechanism; email change token staleness.
- No shared user/DTO layer — raw entities serialized in places.
- No auth headers on image fetches; no URL builder helper.

---

## PART 5 — COMPLETE IMPLEMENTATION ARCHITECTURE

**One integrated feature, delivered in 4 coordinated build phases (all one design):**

- **Avatars = public** (`/uploads/photos/**` permitAll, unguessable UUID filenames). Rendered via `CachedNetworkImage` (already a dependency).
- **Documents = private** (dedicated `driver_documents` entity, `Option B`), stored `uploads/documents/<driverId>/`, served only via owner-or-admin authenticated controller. Never under the public path.
- **One avatar widget** (`UserAvatar`) replaces all 13+ letter-initial copies; takes `photoUrl` + fallback initial; uses `CachedNetworkImage` with graceful placeholder.
- **One photo client** (`PhotoService` wired to upload/delete/fetch); **one document service** on backend + `DriverService` document methods on Flutter.
- **Ride payloads**: additive `driver.photoUrl` (HTTP) + `driverPhotoUrl` (WS, dual-emit existing keys) so riders get driver photo everywhere with zero ride-flow change.
- **Profile refresh**: `await Navigator.push(...)` then re-fetch on return + `StorageService` persistence of identity fields → no stale values, no restart.
- **One verification state machine** on driver documents (PENDING→APPROVED/REJECTED/EXPIRED/SUPERSEDED) that feeds `isVerified` (admin-driven).

**Dependency order (each verifiable, all part of the same feature):**
1. **Core (backend security + avatar infra):** fix role allowlist, user DTO sanitization, upload validation, 413, delete, orphan cleanup, `/uploads/photos/**` permitAll, avatar widget + photo_service wiring + picker.
2. **Domain (backend profile + documents):** User.photoUrl, DriverProfile.vehicleYear/vehiclePhotoUrl/verifiedAt, isVerified key fix, phone normalization, email JWT re-issue, driver PUT personal fields, `DriverDocument` + admin review endpoints + audit, ride-acceptance payload additions.
3. **Flutter surfaces:** rider profile fixes, driver profile screen, driver registration docs, driver photo in all rider screens + history, admin review UI, localization.
4. **Data:** Flyway (or Hibernate+backfill) for new schema; `.gitignore`.

---

## PART 6 — BACKEND PLAN

### Phase 1 — Security & avatar infrastructure
**Files modified:**
- `chatserver/src/main/java/com/example/chatserver/controller/AuthController.java` — role allowlist (only RIDER/DRIVER from client; ADMIN via bootstrap only) at `:113`.
- `chatserver/src/main/java/com/example/chatserver/controller/UserController.java` — `GET /api/users/{id}` → sanitized `UserResponse` DTO (drop normalizedPhone/PII; add photoUrl; fix isVerified key); ownership check.
- `chatserver/src/main/java/com/example/chatserver/service/PhotoService.java` — server-generated filenames (no client input), extension allowlist {jpg,jpeg,png,webp}, magic-byte check, delete old file on replace, canonical path assert.
- `chatserver/src/main/java/com/example/chatserver/controller/PhotoController.java` — add `DELETE /api/photos` (self); ownership rule on metadata read; size validation.
- `chatserver/src/main/java/com/example/chatserver/controller/GlobalExceptionHandler.java` — `MaxUploadSizeExceededException` → 413.
- `chatserver/src/main/java/com/example/chatserver/config/SecurityConfig.java` — permitAll `/uploads/photos/**` (exact prefix only; never `/uploads/**` broad).
- `chatserver/src/main/java/com/example/chatserver/config/RateLimitingFilter.java` — add photo-upload rate limit.
- `chatserver/.gitignore` — add `uploads/`.

**New files:** `dto/UserResponse.java`, `util/PhoneNormalizer.java` (extracted from `AuthController.normalizePhone`).

**APIs:** `POST /api/photos/upload` (hardened), `DELETE /api/photos` (new), `GET /api/photos/{userId}` (ownership rule), `/uploads/photos/**` (permitAll).

### Phase 2 — Profile + documents domain
**Files modified:**
- `chatserver/.../entity/User.java` — add `photoUrl`; `@JsonProperty("isVerified")` on `getVerified()`.
- `chatserver/.../entity/DriverProfile.java` — add `vehicleYear`, `vehiclePhotoUrl`; populate `verifiedAt` in register.
- `chatserver/.../controller/UserController.java` — phone branch (recompute normalizedPhone + countryCode + phoneVerified reset + uniqueness), email→JWT re-issue, optional password, response → UserResponse.
- `chatserver/.../controller/DriverController.java` — extend `PUT /api/drivers/profile` (personal + vehicleYear); `GET /api/drivers/profile` returns photoUrl/vehicleYear/verifiedAt/phone/email(owner); register validation hook for mandatory docs.
- `chatserver/.../controller/AuthController.java` + `dto/AuthResponse.java` — additive `photoUrl`.
- `chatserver/.../controller/RideController.java` — `buildRideResponse` add `driver.photoUrl` + `vehicleType`; `buildUserInfo` add `photoUrl`.
- `chatserver/.../service/RideWebSocketService.java` — add `driverPhotoUrl` to `ride_accepted` (`:86-110`) and scheduled-assigned (`:284-315`); dual-emit alias keys.

**New files:** `entity/DriverDocument.java`, `repository/DriverDocumentRepository.java`, `service/DriverDocumentService.java`, `controller/DriverDocumentController.java`, `dto/DriverDocumentResponse.java`.

**New APIs:** `POST /api/drivers/documents`, `GET /api/drivers/documents`, `GET /api/driver-documents/{driverId}/{documentId}/file`, `DELETE /api/drivers/documents/{documentId}`, `GET /api/admin/drivers/{driverId}/documents`, `POST .../documents/{id}/approve|reject|request-reupload|expire`, `GET .../documents/{documentId}/file`.

**Admin:** `AdminController.java` doc endpoints + audit events; `AdminDriverDetail` add photoUrl/phone/licenseNumber/documents; `AdminRiderDetail` add photoUrl; `AdminTripDetail.DriverInfo` add photoUrl.

---

## PART 7 — FLUTTER PLAN

### Phase 3 — Flutter surfaces
**New files:** `lib/widgets/user_avatar.dart`, `lib/screens/driver_profile_screen.dart`, `lib/screens/admin_document_review_screen.dart`, `lib/models/driver_document.dart`, `lib/services/user_service.dart`.

**Modified models:** `models.dart` (User.photoUrl, isVerified key fix, remove fake email default), `ride_model.dart` (DriverProfile: photoUrl/vehicleYear/vehiclePhotoUrl/verifiedAt/lastSeenAt; Ride: parse driver photoUrl + vehicle fields).

**Modified services:** `photo_service.dart` (add delete + fetch; make it the sole photo client), `driver_service.dart` (updateProfile, personal info, document methods), `ride_recovery_service.dart` (vehicle/photo/coords), `storage_service.dart` (persist fullName/email/phone/photoUrl).

**Modified screens:**
- `rider_profile_screen.dart` — real avatar pick/upload/replace/delete via `UserAvatar`+`PhotoService`; honest save errors; countryCode editable; refresh on return.
- `account_screen.dart` — await-push re-fetch, tappable edit icon, `UserAvatar`, isVerified fix, remove fake rating.
- `settings_screen.dart` — storage-backed name; `UserAvatar`.
- `driver_home_screen.dart` — menu entry to `DriverProfileScreen`; `UserAvatar` in overlay + rider cards; overlay refresh on return.
- `driver_registration_screen.dart` — mandatory photo + 4 document upload steps; failure handling (no nav on fail); resume.
- `rider_tracking_screen.dart:801-813` — `UserAvatar` w/ driverPhotoUrl; vehicle line populated end-to-end.
- `rider_searching_driver_screen.dart:153-168` — populate vehicle + photo from ride model (no hard-coded `''`).
- `rider_active_ride_screen.dart:995-1049` — add driver photo/rating/vehicle.
- `rider_ride_completed_screen.dart:249-262` — add driver photo.
- `trip_history_screen.dart:304-316` — driver photo/vehicle/rating from history payload.
- `ride_preview_screen.dart:420-432` — rider photo param (future).
- `chat_screen.dart:401-413` — `UserAvatar` w/ receiver photo.
- Admin screens: `admin_driver_details_screen`, `admin_driver_list_screen`, `admin_rider_details_screen`, `admin_rider_list_screen`, `admin_trip_details_screen` — `UserAvatar` + document review entry; new `admin_document_review_screen`.

**Widgets:** `driver_info_card.dart` — add optional `photoUrl` (currently unused; extend or retire).

**Dependencies:** add `image_picker`; wire `cached_network_image`.

---

## PART 8 — DATABASE PLAN (minimum safe schema; NOT applied yet)

**New table — `driver_documents`:**
```sql
CREATE TABLE driver_documents (
  id BIGSERIAL PRIMARY KEY,
  driver_id BIGINT NOT NULL REFERENCES driver_profiles(id),
  user_id BIGINT NOT NULL REFERENCES users(id),
  document_type VARCHAR(32) NOT NULL, -- CAR_REGISTRATION|CAR_INSURANCE|DRIVING_LICENCE|PASSPORT_ID
  file_path VARCHAR(512) NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  content_type VARCHAR(128) NOT NULL,
  file_size BIGINT NOT NULL,
  verification_status VARCHAR(16) NOT NULL DEFAULT 'PENDING', -- PENDING|APPROVED|REJECTED|EXPIRED|SUPERSEDED
  admin_note VARCHAR(512),
  expires_at TIMESTAMP,
  uploaded_at TIMESTAMP NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMP,
  reviewed_by BIGINT REFERENCES users(id)
);
CREATE UNIQUE INDEX uq_driver_documents_active
  ON driver_documents(driver_id, document_type)
  WHERE verification_status <> 'SUPERSEDED';
CREATE INDEX ix_driver_documents_driver ON driver_documents(driver_id);
```

**New columns:**
| Table | Column | Type |
|---|---|---|
| `users` | `photo_url` | VARCHAR |
| `driver_profiles` | `vehicle_year` | INTEGER |
| `driver_profiles` | `vehicle_photo_url` | VARCHAR |

**New constraints:** (recommended) unique on `users.normalized_phone`.

**Migration strategy:** Recommend Flyway (`V004__profile_photo_chapter.sql`) + `ddl-auto=validate`; fallback = Hibernate auto-add + manual psql index. `uploads/` gitignored.

---

## PART 9 — SECURITY REVIEW

| Area | Decision |
|---|---|
| Auth | JWT unchanged; role allowlist at registration; verify role vs DB on admin routes |
| Ownership | Photo upload/delete self (from token); photo metadata read public-for-avatar; document read/write owner-or-admin; user GET/PUT self-or-admin |
| Upload limits | 10MB avatars, 8MB documents; per-user quota; rate limit |
| Content type | Extension allowlist {jpg,jpeg,png,webp} + magic-byte validation (docs also pdf if approved) |
| Filename | Server-generated only; no client path components; canonicalize + assert `startsWith(uploadRoot)` |
| Directory traversal | Eliminated by server-generated names + allowlist + canonical-path assert |
| Replacement | Old physical file deleted; prior row SUPERSEDED (history kept) |
| Deletion | Avatar delete self; document delete owner(PENDING)/admin; file removed |
| Public URLs | Only `/uploads/photos/**` (avatars, unguessable UUIDs) |
| Private URLs | Documents via owner-or-admin controller only; never static-served; never permitAll |
| Critical pre-existing | Role allowlist + user-DTO sanitization + upload hardening fixed in this chapter (scope Q7); WS spoofing/IDORs/secrets tracked separately unless expanded |

---

## PART 10 — REGRESSION ANALYSIS

| Feature | Risk | Why / mitigation |
|---|---|---|
| Authentication | **Medium** | Role allowlist changes register; JWT claims unchanged. Verify admin bootstrap + existing admins; test register both roles |
| Registration (rider) | **Medium** | Response gains `photoUrl` (additive). DTO change only if register response shape altered — keep additive |
| Driver approval | **Medium** | `isVerified` becomes pending until admin approves docs (Q2). Existing drivers unaffected (backfill APPROVED); new drivers gated |
| Rider registration | **Low** | Photo upload after account creation (Option B) — no endpoint change |
| Trip flow (request) | Unaffected | Request path untouched |
| Ride acceptance | **Low** | Payload gains keys only (dual-emit); accept transaction unchanged |
| Ride completion | Unaffected | untouched |
| Settlement | Unaffected | untouched (baseline byte-identical each phase) |
| Fraud verification | Unaffected | untouched |
| Wallet | Unaffected | untouched |
| Payments | Unaffected | untouched |
| Notifications | Unaffected | untouched |
| Chat | Unaffected | untouched |
| WebSocket | **Low** | payloads additive; dual-emit preserves consumers |
| Maps | Unaffected | untouched |
| History | **Low** | history payload gains driver.photoUrl (additive); Flutter model updated atomically |
| Admin | **Low** | AdminDTO fields additive; new endpoints only |
| `GET /api/users/{id}` shape | **Medium** | Must ship UserResponse + Flutter model + all readers in same change; include every key `User.fromJson` reads |
| `isVerified` key | **Medium** | Backend key fix + Flutter model change must be atomic |
| SecurityConfig permitAll | **Low** | Exact `/uploads/photos/**` prefix only; verify `/uploads/documents/**` still 403 |

---

## PART 11 — TESTING PLAN (per build phase, gate before advancing)

1. **Compile:** `mvn -q compile` EXIT=0; `flutter analyze` 0 errors (baseline 286 info/warnings unchanged).
2. **API tests (curl, admin token at `$env:TEMP\opencode\admin_token.txt`):** per-endpoint status + exact JSON shape.
3. **Database verification:** psql (`C:\Program Files\PostgreSQL\18\bin\psql.exe`, db `chat_db`) — columns/indexes/uniqueness/audit rows/file cleanup.
4. **Manual Flutter:** run vs localhost:8080; exercise every changed screen on both roles.
5. **Regression suite:** settlement baseline byte-identical (30-day window: cards 7.27/1.94/52.31/90.55, totals 58/4/20/34, driver 13 = 37 trips, detail = 13,058 bytes); verification payloads (rides 282/285) unchanged; ride lifecycle; chat; WS.
6. **Report** after each phase with evidence before advancing.

---

## PART 12 — EXACT FILE LIST (complete)

**Backend modified (Phase 1):** `AuthController.java`, `UserController.java`, `PhotoService.java`, `PhotoController.java`, `GlobalExceptionHandler.java`, `SecurityConfig.java`, `RateLimitingFilter.java`, `.gitignore`
**Backend new (Phase 1):** `dto/UserResponse.java`, `util/PhoneNormalizer.java`
**Backend modified (Phase 2):** `entity/User.java`, `entity/DriverProfile.java`, `DriverController.java`, `AuthController.java`, `dto/AuthResponse.java`, `RideController.java`, `service/RideWebSocketService.java`, `AdminController.java`, `dto/AdminDriverDetail.java`, `dto/AdminRiderDetail.java`, `dto/AdminTripDetail.java`
**Backend new (Phase 2):** `entity/DriverDocument.java`, `repository/DriverDocumentRepository.java`, `service/DriverDocumentService.java`, `controller/DriverDocumentController.java`, `dto/DriverDocumentResponse.java`, `resources/db/migration/V004__profile_photo_chapter.sql`

**Flutter modified (Phase 3):** `pubspec.yaml`, `models/models.dart`, `models/ride_model.dart`, `services/photo_service.dart`, `services/driver_service.dart`, `services/ride_recovery_service.dart`, `services/storage_service.dart`, `screens/rider_profile_screen.dart`, `screens/account_screen.dart`, `screens/settings_screen.dart`, `screens/driver_home_screen.dart`, `screens/driver_registration_screen.dart`, `screens/rider_tracking_screen.dart`, `screens/rider_searching_driver_screen.dart`, `screens/rider_active_ride_screen.dart`, `screens/rider_ride_completed_screen.dart`, `screens/trip_history_screen.dart`, `screens/ride_preview_screen.dart`, `screens/chat_screen.dart`, `screens/admin_driver_details_screen.dart`, `screens/admin_driver_list_screen.dart`, `screens/admin_rider_details_screen.dart`, `screens/admin_rider_list_screen.dart`, `screens/admin_trip_details_screen.dart`, `widgets/driver_info_card.dart`, `l10n/app_en.arb`, `l10n/app_ar.arb`
**Flutter new (Phase 3):** `widgets/user_avatar.dart`, `screens/driver_profile_screen.dart`, `screens/admin_document_review_screen.dart`, `models/driver_document.dart`, `services/user_service.dart`

---

## PART 13 — QUESTIONS REQUIRING YOUR DECISION (STOP — awaiting answers)

1. **Driver registration photo timing:** Is the rider photo uploaded **at registration** (requires changing `AuthController.register` from JSON `@RequestBody` to multipart `@RequestPart` — a breaking API change) or **immediately after account creation** via the existing `POST /api/photos/upload` (zero backend change, token already saved)? **Recommendation: after account creation (Option B)** — safer, no breaking change, existing pipeline.
2. **Driver document requirement:** Are all 5 driver items (profile photo + car registration + car insurance + driving licence + passport/ID) **hard-required to complete driver onboarding**, or uploadable later with a `PENDING` state and going-online blocked until approved? **Recommendation: mandatory at registration wizard.**
3. **Verification gating:** Should `isVerified` change from hard-coded `true` to **pending until admin approves documents**, and should unverified drivers be excluded from ride matching? **Recommendation: yes** (existing drivers backfilled APPROVED).
4. **Vehicle photo:** Implement now or leave `vehicle_photo_url` future-ready only? **Recommendation: future-ready only.**
5. **Password change:** Include in-app change-password (current+new) in this feature? **Recommendation: yes, small addition.**
6. **Email/phone verification screens:** Wire to real backend OTP/email flows, or hide/clear the stubs until backend support exists? **Recommendation: hide stubs this release (out of scope), fix the `isVerified` key display only.**
7. **Security scope:** Fix only the minimum in-chapter (role allowlist, user-DTO sanitization, upload hardening, ownership on photo/doc, 413, rate limit) or also fix WS spoofing, logout/ride/chat IDORs, JWT secret, committed secrets? **Recommendation: minimum in-chapter; remainder tracked separately.**
8. **Migration tooling:** Introduce Flyway for versioned schema, or keep Hibernate `ddl-auto` + manual SQL? **Recommendation: Flyway.**
9. **WS key alignment:** Dual-emit alias keys (`driverPhotoUrl` + existing `driverName`/`licensePlate`) for backward compatibility, or standardize to one key set (requires coordinated Flutter change)? **Recommendation: dual-emit.**
10. **Trip history driver info:** Add driver photo/vehicle/rating to the history card (`trip_history_screen.dart:304-316`), or keep history name-only for now? **Recommendation: add photo + vehicle + rating (requirement 5 lists Trip History).**
11. **Admin document review UI:** Full approve/reject/request-reupload/expire + zoom/download in this release, or view-only first pass? **Recommendation: full workflow (requirement: admin visibility).**

**No code has been written. Awaiting your answers to Parts 13 (1–11) before implementation begins.**
