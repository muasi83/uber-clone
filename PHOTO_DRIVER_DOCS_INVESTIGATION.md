# Photo Picker + Driver Documents + Profile System — Complete Investigation & Design (Phase A Freeze)

**Status:** Investigation & Design Freeze — NO CODE, NO DB CHANGES
**Date:** 2026-08-01
**Scope:** Rider profile, Driver profile, Registration flows, Photo system, Driver documents, Admin review, Ride-acceptance driver info, Security, UI consistency.
**Constraint:** Zero regression on ride flow, payment, wallet, chat, WebSocket, verification, settlement.

---

## 1. EXECUTIVE SUMMARY

- **Photo pipeline exists but is dead, unsafe, and document-less.** A generic `profile_photos` table + `POST /api/photos/upload` + `GET /api/photos/{userId}` + `/uploads/**` static serving exist (`PhotoController.java:21-49`, `PhotoService.java:27-56`, `StaticResourceConfig.java:12-13`), but Flutter `PhotoService` (`photo_service.dart:8-46`) is **never called**, no `image_picker` is installed, every avatar is a letter-initial `CircleAvatar`, and the camera/gallery buttons are SnackBar stubs (`rider_profile_screen.dart:110-126`).
- **Driver documents do not exist as a concept.** No `DriverDocument` entity, no table, no endpoint. Only `licenseNumber` string + `isVerified`/`isActive` booleans, hard-coded `isVerified(true)` at registration (`DriverController.java:66`). `verifiedAt` is never set (always `null`).
- **Driver profile is read-only in the app.** `_buildProfileOverlay()` (`driver_home_screen.dart:2121-2199`) shows only name, rating, rides, vehicle **model**; there is no driver-side edit screen; `PUT /api/drivers/profile` and `PUT /api/users/{id}` are dead endpoints from the driver app's perspective.
- **Rider phone edit is broken.** `PUT /api/users/{id}` updates only `phoneNumber` (`UserController.java:147-149`) — never `normalizedPhone`, `countryCode`, or `phoneVerified`; Flutter swallows errors and shows success anyway (`rider_profile_screen.dart:79-85`); `AccountScreen` never re-fetches (const child of `IndexedStack`, initState-only load).
- **Multiple critical security holes** that must be closed as part of this work: self-registration with client-supplied role including `ADMIN` (`AuthController.java:113`), PII IDOR on `GET /api/users/{id}` (`UserController.java:106-117`), raw-entity nearby-driver leak (`RideController.java:379`), path traversal in photo upload (`PhotoService.java:33-35`), WS identity spoofing, default JWT secret.
- **Recommended architecture:** dedicated `DriverDocument` entity + separate private file-serving endpoint (Option B); public avatars served via a controlled static path; driver documents **never** under public `/uploads/**`; admin document review workflow.

---

## 2. EXISTING IMPLEMENTATION

### 2.1 Rider data flow (field lifecycle)

| Field | Created | Stored | Displayed (Flutter) | Editable | DB update works? | UI refresh? | Local storage? | Verdict |
|---|---|---|---|---|---|---|---|---|
| fullName | `AuthController.java:130` | `users.full_name` (`User.java:29-30`) | account header `account_screen.dart:220`; profile `rider_profile_screen.dart:191`; driver overlay `driver_home_screen.dart:2166` | PUT `/api/users/{id}` `UserController.java:136-138` | **Yes** | **No** — AccountScreen stale (IndexedStack) | **No** — never persisted | **BUG (A): stale UI** |
| username | auto `AuthController.java:103-110` | `users.username` unique (`User.java:19-20`) | `account_screen.dart:110`, `settings_screen.dart:200-221` | No endpoint | — | — | saved only at auth | Not editable (by design) |
| email | `AuthController.java:128` | `users.email` unique (`User.java:22-23`) | `rider_profile_screen.dart:193`; admin detail | PUT `UserController.java:139-146` | Yes, sets `isVerified(false)` | **No** | **No** | **BUG (C/E/F): JWT subject = old email; verified flag mismatch** |
| phoneNumber | `AuthController.java:136` | `users.phone_number` (`User.java:46-47`) | `rider_profile_screen.dart:195` | PUT `UserController.java:147-149` | **Partial** — only phoneNumber, NOT normalizedPhone/countryCode/phoneVerified | **No** | **No** | **BUG (B): normalization stale, uniqueness not enforced** |
| countryCode | `AuthController.java:135` | `users.country_code` (`User.java:43-44`) | read-only `rider_profile_screen.dart:196-202` | **No** — PUT has no branch, save body omits it | — | — | — | **BUG (J): frozen** |
| normalizedPhone | `AuthController.java:82,137` | `users.normalized_phone` (`User.java:49-50`) | never displayed | **No** — never updated after register | — | — | — | **BUG (B/D): stale forever** |
| phoneVerified | default false `User.java:52-54` | `users.phone_verified` | account menu `account_screen.dart:153-156` | **No endpoint can ever set true** | — | — | — | **BUG (G): non-functional** |
| gender | `AuthController.java:116-124,132` | `users.gender` (`User.java:65-68`) | SegmentedButton `rider_profile_screen.dart:213-227` | PUT `UserController.java:152-163` | Yes; re-issues JWT if changed (`:178-181`) | Partial (local screen only) | **Yes** `saveGender` `rider_profile_screen.dart:76` | **PARTIAL**: works but new token can carry stale email subject |
| password | `AuthController.java:129` (BCrypt 12) | `users.password` (`User.java:25-27`, @JsonIgnore) | never | **No change-while-logged-in endpoint**; only forgot-password OTP `AuthController.java:390-540` | via `/reset-password` `:529` | — | — | **MISSING: in-app password change** |
| photoUrl | not on User entity; `ProfilePhoto.java:22` | `profile_photos.photo_url` | **nowhere** — initials only | `POST /api/photos/upload` exists, **no UI calls it** | only via unwired raw API | — | — | **BUG (K): dead feature** |
| role | `AuthController.java:113,131` | `users.role` | auth routing; account subtitle | **No** | — | — | saved at auth | Not editable (by design) |
| isVerified (email) | register `true` `AuthController.java:133`; reset false on email change `UserController.java:145` | `users.is_verified` (`User.java:37`) | account menu `account_screen.dart:141-144` | No | only reset-to-false | — | — | **BUG (E): JSON key `verified` vs Flutter reads `isVerified` → always false** |

### 2.2 Driver data flow

| # | Field | Created | Stored | Shown (Flutter) | Editable | Verdict |
|---|---|---|---|---|---|---|
| 1 | personal photo | `PhotoService.java:38` | `profile_photos` | **nowhere** | API exists, no UI | **HIDDEN/BROKEN** |
| 2 | fullName | `AuthController.java:130` | `users.full_name` | overlay `driver_home_screen.dart:2166` | PUT `/api/users/{id}` — no driver UI | editable only in theory |
| 3 | username | `AuthController.java:103-110` | `users.username` | overlay initial `driver_home_screen.dart:2154-2155` | No | **BUG: avatar uses username[0]** |
| 4 | phone | `AuthController.java:136` | `users.phone_number` | **nowhere in driver UI** | PUT users — no driver UI | **HIDDEN** |
| 5 | email | `AuthController.java:128` | `users.email` | admin only `admin_driver_details_screen.dart:161` | PUT users — no driver UI | **HIDDEN from driver** |
| 6 | gender | `AuthController.java:116-124` | `users.gender` | **nowhere in driver UI** | PUT users — no driver UI | **HIDDEN** |
| 7 | licenseNumber | `DriverController.java:61` | `driver_profiles.license_number` (`DriverProfile.java:22-23`) | **not shown (driver or admin)** | PUT drivers/profile — no driver UI | **HIDDEN** |
| 8 | vehicleNumber (plate) | `DriverController.java:62` | `driver_profiles.vehicle_number` | admin only `admin_driver_details_screen.dart:241,269` | PUT drivers — no driver UI | **HIDDEN in driver UI** |
| 9 | vehicleType | `DriverController.java:63` | `driver_profiles.vehicle_type` | admin only | PUT drivers — no driver UI | **HIDDEN in driver UI** |
| 10 | vehicleModel | `DriverController.java:64` | `driver_profiles.vehicle_model` | overlay stat `driver_home_screen.dart:2191` | PUT drivers — no driver UI | shown, read-only |
| 11 | vehicleColor | `DriverController.java:65` | `driver_profiles.vehicle_color` | admin only | PUT drivers — no driver UI | **HIDDEN in driver UI** |
| 12 | **vehicleYear** | **does not exist anywhere** | — | — | — | **MISSING** |
| 13 | isVerified | **hard-coded true** `DriverController.java:66` | `driver_profiles.is_verified` | admin chip only | PATCH admin verify `AdminController.java:634-661` | **HIDDEN + auto-verified BUG** |
| 14 | isActive | hard-coded true `DriverController.java:67` | `driver_profiles.is_active` | admin only | PATCH admin block `AdminController.java:663-689` | **HIDDEN from driver** |
| 15 | averageRating | hard-coded 5.0 `DriverController.java:68` | `driver_profiles.average_rating` | overlay `driver_home_screen.dart:2179` | No | shown read-only |
| 16 | totalRides | hard-coded 0 `DriverController.java:69` | `driver_profiles.total_rides` | overlay `driver_home_screen.dart:2185` | No | shown read-only |
| 17 | isOnline | **duplicated** `driver_profiles.is_online` + `users.is_online` | both | toggle UI | toggle-online | **DUPLICATE + sync bug** |
| 18 | lastSeenAt | updated only on location `DriverController.java:136` / online `:166` | `driver_profiles.last_seen_at` | **dropped by Flutter model** | — | **HIDDEN + model gap** |
| 19 | createdAt | `DriverController.java:71` | `driver_profiles.created_at` | **not in API response** | — | **HIDDEN** |
| 20 | verifiedAt | **never set** | `driver_profiles.verified_at` | not in API | — | **BROKEN (always null)** |

### 2.3 Photo system today

- **Upload:** `POST /api/photos/upload`, Bearer token, field `file`, any role (`PhotoController.java:21-38`). Fully buffered (`file.getBytes()`, `PhotoService.java:36`). Filename `userId_UUID.<ext>`; extension from client filename, **no allowlist** (`PhotoService.java:33-35,58-61`). Old DB row deleted, **old file never deleted** (`PhotoService.java:40`).
- **Download:** `/uploads/**` → `file:uploads/` (`StaticResourceConfig.java:12-13`). **NOT permitAll** → falls under `anyRequest().authenticated()` (`SecurityConfig.java:58`). A browser `<img>` / `Image.network` without a Bearer header fails. No `Image.network` usage exists anywhere.
- **Storage:** `uploads/photos/` relative to CWD (`PhotoService.java:24`); table `profile_photos` (id, user_id, photo_url, uploaded_at) (`ProfilePhoto.java:8-25`); no unique constraint; `uploads/` **not gitignored** (only `/target/`).
- **Metadata:** `GET /api/photos/{userId}` returns URL — **no ownership check** (`PhotoController.java:40-49`), any authenticated user can read anyone's photo URL.
- **Cache:** `cached_network_image: ^3.3.1` in `pubspec.yaml:53` but **never used**.
- **Delete:** **no delete endpoint**; Flutter "Remove photo" does nothing (`rider_profile_screen.dart:127-133`).
- **Compression:** **none** (no image library in `pom.xml`; no picker/compress package in Flutter).
- **Max size:** 10MB (`application.yml:35-36`); oversize → **500**, not 413 (`GlobalExceptionHandler.java:31-35`).
- **Formats:** **any file type** accepted (`.html`, `.svg`, `.exe`).
- **Camera/Gallery:** **no** `image_picker`/`file_picker` package; buttons are stubs (`rider_profile_screen.dart:110-126`).

### 2.4 Registration flows

**Rider (`auth_screen.dart` → `AuthController.java:45-170`):**
1. Collects fullName, email, password, countryCode, phone, gender, role (`auth_screen.dart:690-839`).
2. `POST /api/auth/register` (`auth_screen.dart:156-175`).
3. Backend validates email/password/phone duplicates (`AuthController.java:56-100`), generates username, builds `User` (isVerified=true, phoneVerified=false), **saves users row** (`AuthController.java:142`), mints JWT, returns `{token,userId,username,role,gender,message}` (`AuthResponse.java:9-14`).
4. Flutter saves token/userId/username/role/gender; role DRIVER → `/driver-registration` (`auth_screen.dart:196-200`).
5. **No photo, no documents, no profile photo in rider registration.**

**Driver (`driver_registration_screen.dart` → `DriverController.java:34-92`):**
1. 3-step wizard: license number (step 1), vehicle number/type/model/color (step 2), review (step 3) (`driver_registration_screen.dart:359-477`).
2. `POST /api/drivers/register` with JSON `{licenseNumber, vehicleNumber, vehicleType, vehicleModel, vehicleColor}` (`driver_service.dart:33-39`).
3. Backend: checks existing profile, builds `DriverProfile` with **hard-coded** isVerified=true/isActive=true/rating 5.0/rides 0 (`DriverController.java:59-72`), saves (`:74`), re-sets `users.role=DRIVER` (`:77`), returns `{message, profileId}`.
4. **No photo, no document upload anywhere.**
5. **Half-registered risk:** users row committed at step A, driver_profiles row in a separate request (`AuthController.java:142` vs `DriverController.java:74`). Failure/network-drop → `DriverService.registerAsDriver` swallows exception → returns false → **still navigates to DriverHomeScreen** (`driver_registration_screen.dart:128-143`) → driver with no profile.
6. **No resume:** wizard state in-memory only; restart/login routes role=DRIVER straight to DriverHome (`splash_screen.dart:123-133`, `auth_screen.dart:275-279`).

### 2.5 Ride-acceptance driver info

| Hop | fullName | rating | vehicleModel | vehicleColor | plate | **photoUrl** | vehicle photo |
|---|---|---|---|---|---|---|---|
| A: accept HTTP resp `buildRideResponse` (`RideController.java:312-350`) | ✅ | ✅ | ✅ | ✅ | ✅ (`vehicleNumber`) | ❌ | ❌ |
| B: WS `ride_accepted` payload (`RideWebSocketService.java:86-110`) | ✅ (`driverName`) | ✅ | ✅ | ✅ | ✅ (`licensePlate`) | ❌ | ❌ |
| C: rider poll fallback (`rider_searching_driver_screen.dart:153-168`) | ✅ | ✅ | **hard-coded `''`** | **hard-coded `''`** | **hard-coded `''`** | ❌ | ❌ |
| D: tracking render (`rider_tracking_screen.dart`) | ✅ | ✅ | shows but often blank | blank | blank | ❌ (letter avatar `:801-813`) | ❌ |

Key inconsistencies: WS uses `driverName`/`licensePlate`, HTTP uses `fullName`/`vehicleNumber`. Recovery path omits vehicle + live coords (`ride_recovery_service.dart:42-58`).

### 2.6 Admin capabilities (photo/document)

| Capability | Admin today? | Evidence |
|---|---|---|
| View driver photo | **NO** | no photoUrl in `AdminDriverDetail.java` |
| View rider photo | **NO** | `AdminRiderDetail.java:16-28` |
| View documents | **NO** | no document entity/table/endpoint exists |
| Download/zoom | **NO** | no image widget, no media endpoint |
| Approve/reject documents | **NO** | `toggleVerify` flips boolean only (`AdminController.java:644`) |
| Request re-upload | **NO** | nothing |
| See upload dates | **NO** | `uploadedAt` exists (`ProfilePhoto.java:25`) but never exposed |
| See driver phone | **NO** | not in `AdminDriverDetail` |
| See driver license | **NO** | `licenseNumber` never in AdminDTO |
| Audit history (trips) | **YES** | `/rides/{rideId}/events` + timeline UI |
| Audit history (photo/doc) | **NO** | photo uploads unlogged |
| "Verification" | trip-fraud GPS only (`TripVerificationService`) — **unrelated to documents** | |

---

## 3. EVERYTHING MISSING

1. Driver documents: car registration, car insurance, driving licence, passport/ID — entity, table, upload/replace/delete, review, status, expiry.
2. Personal photo on both rider and driver (pipeline exists but unwired).
3. Vehicle photo field (future-ready requirement).
4. `vehicleYear` field.
5. `photoUrl` on `User` entity/model/DTOs and on `DriverProfile` response/model.
6. Photo upload UI: image_picker package, camera/gallery, avatar display, replace, remove.
7. Driver profile edit screen + functional `PUT /api/drivers/profile` client call + personal fields (name/phone/email/gender) on the PUT.
8. Rider: fixed phone update (normalizedPhone/countryCode/phoneVerified), refresh propagation, error handling, local persistence of fullName/email/phone.
9. In-app password change.
10. Functional email/phone verification screens.
11. Admin document review UI + endpoints + audit events.
12. `verifiedAt` population; driver verification workflow (pending/under-review states).
13. 413 handling for oversize uploads; content-type/extension validation; delete endpoint; orphan-file cleanup; ownership checks; rate limiting on uploads.
14. Photo URL + vehicle fields in ride-accept WS payload, HTTP response, poll fallback, recovery path; avatar rendering in tracking screen.
15. `/uploads/**` serving strategy (public avatars) vs private documents.
16. `isOnline` de-duplication and sync fix.
17. Localization for all new labels (AR + EN).

---

## 4. BUGS FOUND (exact locations)

### Rider
- **A.** Stale UI after profile edit — `account_screen.dart:33-59` (initState only) + const in `IndexedStack` (`rider_home_screen.dart:861`).
- **B.** Phone change doesn't update normalizedPhone/countryCode/phoneVerified — `UserController.java:147-149`.
- **C.** JWT subject (email) not re-issued on email change — `UserController.java:139-146` vs `JwtUtil.java:40`.
- **D.** `normalized_phone` unique is entity-only (`User.java:49`); DB dump shows only `users_pkey`; enforced only at registration.
- **E.** `isVerified` JSON key mismatch — getter `getVerified()` (`User.java:95`) → key `"verified"`; Flutter reads `json['isVerified']` (`models.dart:47`) → always false.
- **F.** Gender-change token re-issue can embed stale email subject.
- **G.** Email/phone verification screens are dead stubs — `email_verification_screen.dart:36`, `phone_verification_screen.dart:63,75`; no backend path sets phoneVerified/verified(true).
- **H.** `_save()` swallows errors + false success snackbar — `rider_profile_screen.dart:79-85`.
- **I.** fullName/email/phone never persisted locally — `storage_service.dart:11-15`; save only writes token+gender (`rider_profile_screen.dart:72-77`).
- **J.** countryCode not editable — no PUT branch (`UserController.java:136-163`), not in save body (`rider_profile_screen.dart:62-67`).
- **K.** Photo feature dead — `rider_profile_screen.dart:110-133`; `PhotoService` never imported.
- **L.** `GET /api/users/{id}` leaks PII (email/phone/normalizedPhone/countryCode) to any caller — `UserController.java:106-117` + `User.java:23,44,47,50` not @JsonIgnore.
- **M.** Settings notification toggles inert — `settings_screen.dart:302,314,326`.

### Driver
- **1.** `verifiedAt` always null — declared `DriverProfile.java:63`, never set (register `DriverController.java:59-72`, admin verify `AdminController.java:644`).
- **2.** Auto-verified with no review/documents — `DriverController.java:66`.
- **3.** `isOnline` duplicated (users + driver_profiles) with sync bug — login sets users only (`AuthController.java:214`), toggle sets driver_profiles only (`DriverController.java:164-168`), logout sets both.
- **4.** Nearby-driver raw-entity PII leak — `RideController.java:379` returns raw `List<DriverProfile>` (email/phone/normalizedPhone/countryCode serialize).
- **5.** Fake email in Flutter driver model — `models.dart:39` defaults missing email to `'unknown@test.com'`.
- **6.** `lastSeenAt` not stamped on going offline — `DriverController.java:164-167`; dropped by Flutter model.
- **7.** Overlay avatar uses `username[0]` not name/photo — `driver_home_screen.dart:2154-2155`.

### Registration
- **8.** Two-step non-atomic registration; abandoned driver onboarding leaves role=DRIVER with no profile.
- **9.** `registerAsDriver` swallows all exceptions and returns false — `driver_service.dart:54-56`.
- **10.** False result still navigates to DriverHome — `driver_registration_screen.dart:128-143`.
- **11.** No wizard resume; role=DRIVER always → DriverHome on restart.
- **12.** No idempotency on `/api/auth/register`; retry after lost response → "Email already registered".
- **13.** TOCTOU on email/phone/username uniqueness checks.
- **14.** No backend validation on driver fields (null → 500) or fullName.
- **15.** Half-registered DRIVER can log in (block check only when profile exists).
- **16.** `_checkExistingProfile` treats any error as "no profile".
- **17.** `/api/drivers/register` not rate-limited (only `/api/auth/register`, keyed on IP only — `RateLimitingFilter.java:79-83,93-95`).

### Photo system
- **18.** Path traversal / arbitrary file write — `PhotoService.java:33-35` (extension from client filename, no sanitization, CWE-22).
- **19.** Arbitrary file types accepted — `PhotoService.java:58-61`.
- **20.** Orphan files on replace — `PhotoService.java:40`.
- **21.** No delete endpoint.
- **22.** No ownership check on photo read — `PhotoController.java:40-49`.
- **23.** Oversize → 500 not 413 — `GlobalExceptionHandler.java:31-35`.
- **24.** No upload rate limit / quota — `RateLimitingFilter.java:86-108`.
- **25.** `uploads/` not gitignored.
- **26.** Whole file buffered in memory.

### Admin
- **27.** No photo/document anywhere in admin surface; verify is blind boolean toggle; no audit for photos.

### Ride-acceptance
- **28.** No photoUrl in any ride payload; WS/HTTP key inconsistency (licensePlate vs vehicleNumber); poll fallback hard-codes empty vehicle fields; recovery path omits vehicle/live-coords.

### Security (CRITICAL)
- **29.** Client-supplied role accepted → self-register as ADMIN — `AuthController.java:113` + `JwtUtil.java:32` (role claim) + `SecurityConfig.java:57` (hasRole ADMIN from claim) + `AdminController.java:847-857` (claim-only check).
- **30.** Default JWT secret fallback — `application.yml:39`.
- **31.** Ride cancel without ownership — `RideService.java:226-252`.
- **32.** Logout IDOR (force-offline/cancel others' rides) — `UserController.java:59-104` (uses path `id`).
- **33.** Chat history IDOR — `ChatController.java:125-161`.
- **34.** WS identity spoofing — `ChatWebSocketHandler.java:224-227,316-333,367-389,420-474`; `RideWebSocketHandler.java:75-130` (payload IDs trusted, not session).
- **35.** Raw `List<Ride>` endpoint leaks PII — `RideController.java:385-393`.
- **36.** Committed secrets — `application.yml:8,24,58`.
- **37.** `GET /api/rides/{rideId}` no ownership — `RideController.java:244-251`.

### UI
- **38.** FCM notification tap → `/rider-tracking` missing `driverData` arg → error screen — `firebase_service.dart:132` vs `main.dart:327-341`.
- **39.** `/chat` named route doesn't exist — `firebase_service.dart:130` vs `main.dart` routes.
- **40.** Hardcoded fake data: account rating `4.8` (`account_screen.dart:269`), wallet `$45.20` (`payment_methods_screen.dart:16`), support contact info, social-login "Coming Soon".
- **41.** Account header edit icon not tappable — `account_screen.dart:285-288`.

---

## 5. RECOMMENDED ARCHITECTURE

### 5.1 Driver documents — Option B (dedicated `DriverDocument` entity)

**Compare:**

| Aspect | Option A: extend `ProfilePhoto` | Option B: dedicated `DriverDocument` (recommended) |
|---|---|---|
| Data model | Add `documentType`, `fileName`, `contentType` to one table | Own table: `id, driver_id, user_id, document_type, file_path, file_name, content_type, file_size, verification_status, admin_note, uploaded_at, reviewed_at, reviewed_by` |
| Ownership | `user_id` loose column, no FK | explicit `driver_id` FK + `user_id` |
| Status lifecycle | none (would need new columns) | built-in PENDING/APPROVED/REJECTED/EXPIRED + admin note + timestamps |
| Multi-document uniqueness | per `(user_id, document_type)` hack | natural unique index `(driver_id, document_type)` where active |
| Audit | none | every state change logged |
| Serving | shares public avatar path (dangerous) | separate private endpoint with owner/admin check |
| Expiry handling | awkward | `expires_at` column per document |
| Backwards compat | must preserve old rows | clean slate, profile_photos untouched |
| Long-term | entangled avatars + sensitive docs | documents and avatars evolve independently |

**Recommendation: Option B.** Avatars (profile photos) stay in `profile_photos`/User; sensitive driver documents live in a new `driver_documents` table served only through an authenticated controller with an explicit owner-or-admin check. This keeps public avatars public and documents strictly private, gives a proper review/expiry lifecycle, and avoids polluting the generic photo path.

### 5.2 File serving model

- **Public avatars (non-sensitive):** keep `uploads/photos/**` but add explicit `.permitAll()` in `SecurityConfig` (unguessable UUID filenames, low sensitivity). Flutter renders via `Image.network`/`CachedNetworkImage`.
- **Private documents (sensitive):** **never** under `/uploads/**`. Store under `uploads/documents/<driverId>/` and serve via a new authenticated endpoint `GET /api/driver-documents/{driverId}/{documentId}/file` that enforces: caller is the document owner **or** `ROLE_ADMIN`. Uses an `AccessDecisionManager`-style check (owner-or-admin), streams bytes, sets correct Content-Type and Content-Disposition (inline for review, attachment for download).

### 5.3 Security posture (required before/with this feature)

| Issue | Fix direction |
|---|---|
| Self-register ADMIN | server-side role allowlist (RIDER/DRIVER only) at `AuthController.java:113`; `ADMIN` only via bootstrap; verify role against DB on admin routes |
| Default JWT secret | require `JWT_SECRET` env var; rotate; add issuer/audience |
| PII IDOR | `GET /api/users/{id}` → DTO (id, username, fullName, photoUrl, role, gender) or @JsonIgnore PII + ownership check |
| Raw nearby-driver leak | `RideController.java:379` → sanitized DTO (id, name, rating, vehicle, photo); drop license/GPS exposure |
| Path traversal upload | never use `originalFilename`; extension whitelist + magic-byte check; canonicalize path; assert startsWith uploadRoot |
| Upload abuse | rate limit + per-user storage quota; validate content-type; delete old file on replace |
| Oversize | 413 handler for `MaxUploadSizeExceededException` |
| WS spoofing | derive identity from handshake session only; reject payload IDs that mismatch |
| Ride/chat/logout IDOR | ownership checks (caller ∈ {participants}) |
| Committed secrets | env/secrets manager + rotation |

### 5.4 Admin document review

New admin surface: document list per driver (thumbnails, type, status, upload date, reviewer, note), approve/reject/request-re-upload actions, download, and zoom. All backed by endpoints under `/api/admin/drivers/{driverId}/documents` gated by `hasRole("ADMIN")`, each action logged as an audit event.

---

## 6. DATABASE CHANGES (DESIGN — NOT EXECUTED)

New table `driver_documents`:
```sql
driver_documents:
  id BIGSERIAL PK
  driver_id BIGINT NOT NULL (FK driver_profiles.id)
  user_id BIGINT NOT NULL (FK users.id)
  document_type VARCHAR(32) NOT NULL   -- CAR_REGISTRATION | CAR_INSURANCE | DRIVING_LICENCE | PASSPORT_ID
  file_path VARCHAR(512) NOT NULL
  file_name VARCHAR(255) NOT NULL
  content_type VARCHAR(128) NOT NULL
  file_size BIGINT NOT NULL
  verification_status VARCHAR(16) NOT NULL DEFAULT 'PENDING'  -- PENDING | APPROVED | REJECTED | EXPIRED
  admin_note VARCHAR(512)
  expires_at TIMESTAMP NULL
  uploaded_at TIMESTAMP NOT NULL DEFAULT now()
  reviewed_at TIMESTAMP NULL
  reviewed_by BIGINT NULL (FK users.id)
  UNIQUE (driver_id, document_type)   -- one active document per type
```

Alterations:
- `users`: add `photo_url` (avatar, non-sensitive) — or keep in `profile_photos` and expose via join. Recommend adding `photo_url` for simplicity + keep `profile_photos` as upload journal.
- `driver_profiles`: add `vehicle_year INTEGER`, `vehicle_photo_url VARCHAR` (future-ready), drop reliance on duplicated `is_online` (keep `driver_profiles.is_online` as source of truth; fix users sync).
- `driver_profiles.verified_at`: populate on admin verify.
- Add `document_type` awareness to photo upload (or keep avatar path separate).

Migration strategy: since the project uses Hibernate `ddl-auto: update` (no Flyway wired), either (a) add entities and let Hibernate create columns/tables, then manually backfill, or (b) introduce Flyway properly for versioned migration. **Recommend (b) Flyway** for the production audit standard already flagged; table above is the target schema either way. `uploads/` must be added to `.gitignore`.

---

## 7. API CHANGES (DESIGN — NOT EXECUTED)

### Photos / avatars
- `POST /api/photos/upload` — harden: extension allowlist (jpg/png/webp), magic-byte check, size check, rate limit, delete old file, optional `documentType=PROFILE`.
- `GET /api/photos/{userId}` — add ownership-or-public rule.
- Add `DELETE /api/photos` (self-only).
- Add 413 handler.

### Driver documents
- `POST /api/drivers/documents` (multipart: file + documentType) — owner-only; replaces prior active doc of that type (soft-delete old, keep history).
- `GET /api/drivers/documents` (self) — list own documents + statuses.
- `GET /api/driver-documents/{driverId}/{documentId}/file` — owner-or-admin, streams bytes.
- `DELETE /api/drivers/documents/{documentId}` — owner (PENDING only) or admin.
- Admin: `GET /api/admin/drivers/{driverId}/documents`, `POST .../documents/{id}/approve`, `POST .../reject`, `POST .../request-reupload`, `POST .../expire`. Each writes an audit event.

### Profile
- `PUT /api/users/{id}` — fix phone branch: recompute `normalizedPhone`, optionally update `countryCode`, reset `phoneVerified=false`, enforce normalized-phone uniqueness; re-issue JWT on email change; add `photoUrl` to response; add optional `password` change (current + new) branch.
- `PUT /api/drivers/profile` — extend to accept personal fields (fullName, email, phoneNumber, gender, vehicleYear) + photo/document links; return full profile with photoUrl.
- `GET /api/drivers/profile` — return photoUrl, vehicleYear, verified/active, phone/email (owner-only), verifiedAt, lastSeenAt.
- `GET /api/users/{id}` — return sanitized DTO with photoUrl (no raw PII to arbitrary callers).

### Ride acceptance (rider sees driver)
- `buildRideResponse` (`RideController.java:312-350`) — add `photoUrl` (+ `vehicleType`).
- `RideWebSocketService.notifyRideAccepted` (`:86-110`) — add `driverPhotoUrl`; align key names (driverName/fullName, licensePlate/vehicleNumber).
- `RideWebSocketService.notifyScheduledRideAssigned` (`:284-315`) — add driverPhotoUrl.
- Flutter poll fallback (`rider_searching_driver_screen.dart:153-168`) — populate vehicle + photo from ride model instead of hard-coded `''`.
- Recovery path (`ride_recovery_service.dart:42-58`) — add vehicle + live coords + photo.

---

## 8. FLUTTER CHANGES (DESIGN — NOT EXECUTED)

### Dependencies
- Add `image_picker` (+ `cached_network_image` already present, wire it up).

### Models
- `User` (`models.dart:3-76`): add `photoUrl` (parse/serialize).
- `DriverProfile` (`ride_model.dart:188-295`): add `photoUrl`, `vehicleYear`, `vehiclePhotoUrl`, `verifiedAt`, `lastSeenAt`.
- `Ride` (`ride_model.dart:5-186`): parse `vehicleModel`, `vehicleColor`, `vehicleNumber`, `photoUrl` from driver map.
- New `DriverDocument` model.

### Services
- `photo_service.dart`: make it used — upload (camera/gallery), get, remove; add document upload/replace/list/delete; auth headers on image fetch if needed.
- `driver_service.dart`: add `updateDriverProfile`, `updateDriverPersonalInfo`, document methods.
- `user_service.dart` (new): consolidate `GET/PUT /api/users/{id}`, phone/email/password update, with proper error surfacing.
- `ride_recovery_service.dart`: fill driver vehicle/photo/coords.

### Screens
- **Rider profile** (`rider_profile_screen.dart`): real avatar (pick → upload → preview via NetworkImage), fix `_save()` (surface errors, only show success on 200, persist fullName/email/phone to storage), make countryCode editable, add password-change section (optional), propagate changes back to AccountScreen.
- **Account** (`account_screen.dart`): refresh `_user` when returning from profile (e.g., await Navigator.push then re-fetch, or lift state); real avatar; fix `isVerified` key; make edit icon tappable; remove fake rating or source it.
- **Driver profile** (NEW screen replacing/augmenting `_buildProfileOverlay`): full read/edit — personal photo, name, phone, email, gender, license number, vehicle (number/type/model/color/year/photo), verified/active status, documents list + statuses, edit entry point in driver menu sheet (`driver_home_screen.dart:2279-2360`).
- **Driver registration** (`driver_registration_screen.dart`): add mandatory steps — personal photo, driving licence photo, passport/ID, car registration, car insurance (upload now; "must be sent along with registration" requirement). Add resume logic + proper failure handling (don't navigate on failure).
- **Rider tracking** (`rider_tracking_screen.dart:801-813`): render driver photo avatar; vehicle line now populated end-to-end.
- **Admin**: new document review screen + photo/avatar display in driver/rider list & detail; add phone + license to driver detail DTO/UI.
- **Verification screens**: wire email/phone verification to real endpoints or remove.

### State/refresh
- Introduce a simple refresh contract (e.g., `await Navigator.push(...)` then re-fetch, or a shared `UserController`/provider) so AccountScreen reflects edits. Update `StorageService` to persist fullName/email/phone/photoUrl.

---

## 9. MIGRATION STRATEGY

1. **Phase A (design):** this document.
2. **Phase B (backend hardening first):** close the critical security issues (role allowlist, JWT secret, PII IDOR, path traversal, upload validation, ownership checks, rate limiting, 413) — these gate everything.
3. **Phase C (backend domain):** `DriverDocument` entity + repo + service + controller + admin endpoints + photo hardening + profile update fixes + ride-acceptance payload additions + `verifiedAt`/vehicleYear/photoUrl columns. Compile + regression each step.
4. **Phase D (Flutter):** image_picker + avatar wiring + driver profile screen + registration document steps + rider profile fixes + tracking avatar/vehicle + admin review UI. `flutter gen-l10n` (new AR/EN keys) + `flutter analyze` (baseline 286 issues, 0 errors — keep at 0 errors).
5. **Phase E (data):** Flyway migration (or Hibernate update + manual backfill) for `driver_documents`, `users.photo_url`, `driver_profiles.vehicle_year/vehicle_photo_url`; add `uploads/` to `.gitignore`.
6. **Phase F (E2E regression):** ride request→accept→track→complete→pay→wallet; chat; WS events; verification; settlement; admin review; profile edit refresh on both roles.

---

## 10. REGRESSION ANALYSIS

**What must stay byte-identical after this work:**
- Settlement numbers/derivations (30-day baseline: cards 7.27/1.94/52.31/90.55, totals 58/4/20/34, driver 13 = 37 trips; driver-detail JSON = 13,058 bytes) — none of the proposed changes touch `SettlementService`/`SettlementReportRepository`.
- Trip verification scores/rules (5 rules 30/30/25/10/5, thresholds in `TripVerificationProperties`) — untouched.
- Payment/wallet math (`PaymentService.APP_PERCENTAGE`, `NET_RATE`, net_amount authoritative) — untouched.
- Chat/WS message flow — only additive payload fields.
- Async executor wiring (`tripVerificationExecutor`, `applicationTaskExecutor`) — untouched.

**Risk areas needing careful sequencing:**
- `SecurityConfig` changes (permitAll `/uploads/photos/**`) — must NOT accidentally expose `/uploads/documents/**`; use distinct prefixes.
- `User` entity additions (photoUrl) — serialization must remain backward-compatible with existing Flutter models during transition (additive fields are safe; removed fields are not).
- Fixing `isVerified` JSON key — must ship together with the Flutter model change (breaking otherwise).
- Role allowlist — verify admin bootstrap still works; test that existing admin accounts keep access.
- `GET /api/users/{id}` DTO sanitization — Flutter `AccountScreen` currently relies on full entity; must map all fields it reads.

**Test matrix after implementation:** registration (both roles, with/without docs, network-drop, resume), profile edit (both roles, every field, phone uniqueness), photo upload (valid/invalid/oversize/replace/delete/ownership), documents (upload/replace/review/expiry/admin actions), ride acceptance (WS payload, poll fallback, recovery), admin review, and full ride lifecycle regression.

---

## 11. PHASE-BY-PHASE IMPLEMENTATION PLAN

**Phase B — Security hardening (backend, gates everything):**
1. Role allowlist at registration; verify role vs DB on admin routes.
2. JWT secret via env; issuer/audience.
3. `GET /api/users/{id}` sanitized DTO; ownership checks on rides/chat/logout; WS identity from session.
4. Photo upload: extension whitelist, magic bytes, size, rate limit, orphan cleanup, 413 handler, delete endpoint, ownership on read.
5. Compile + regression (auth, rides, chat, WS).

**Phase C — Backend domain:**
6. `DriverDocument` entity/repo/service/controller (upload/list/file/delete) + owner-or-admin check.
7. Admin document review endpoints + audit events.
8. Photo/avatar integration: photoUrl on User, auth/register/driver profile responses.
9. Profile fixes: phone branch (normalizedPhone/countryCode/phoneVerified/uniqueness), email JWT re-issue, driver PUT personal fields, `verifiedAt`, `vehicleYear`, `vehiclePhotoUrl`.
10. Ride-acceptance payloads: photoUrl + vehicle fields + key alignment (WS + HTTP + scheduled).
11. Compile + regression per step; compare settlement/verification baselines.

**Phase D — Flutter:**
12. Add image_picker; wire photo_service (avatar pick/upload/display/remove).
13. Rider profile fixes (save/errors/persistence/refresh, countryCode, password section).
14. Driver profile screen (new) + menu entry; functional update calls.
15. Driver registration: mandatory photo + 4 documents + resume + failure handling.
16. Rider tracking avatar/vehicle; poll fallback + recovery fill.
17. Admin review UI + avatars/phone/license in admin screens.
18. Localization (AR/EN) + `flutter gen-l10n` + `flutter analyze` (0 errors).

**Phase E — Data:**
19. Flyway (or Hibernate+backfill) for new schema; `.gitignore` for uploads.

**Phase F — E2E regression:** full matrix (Section 10).

---

## 12. DECISIONS NEEDED FROM YOU

1. **Document requirement timing:** make all 5 driver items (personal photo + licence + passport/ID + car registration + car insurance) **hard-required** to complete driver onboarding? Or allow "upload later" with PENDING status and block going-online until approved?
2. **Verification gating:** should `isVerified` become `PENDING` until admin approves documents (removing the hard-coded `true`), and should unverified drivers be blocked from matching? (Recommended: yes.)
3. **Vehicle photo:** include now or leave future-ready field only? (Requirement says future-ready is fine.)
4. **Password change UI:** add in-app change-password (current+new) in the same release?
5. **Admin review scope:** full document review (approve/reject/request-reupload/expiry/audit) in this release?
6. **Email/phone verification screens:** wire them to real OTP/email flows or hide them until backend support exists?
7. **Scope of security fixes:** the security audit found critical issues beyond photos/profiles (admin self-registration, PII IDOR, WS spoofing, committed secrets). Should they be included in this work or tracked separately? (Recommended: include the role-allowlist + PII + upload fixes; the rest tracked separately.)

No code has been changed. Awaiting your decisions before any implementation.
