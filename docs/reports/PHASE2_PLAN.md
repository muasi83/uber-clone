# Phase 2 Implementation Plan (Proposed — awaiting implementation)

Status: **Phase 2A COMPLETE + FROZEN (approved 2026-08-02). Phase 2B COMPLETE + FROZEN (approved 2026-08-02, report: PHASE2B_REPORT.md). Phase 2C COMPLETE + FROZEN (approved 2026-08-02, report: PHASE2C_REPORT.md). Phase 3 (Flutter) PENDING.**

Incorporates all GPT corrections from both review rounds:
- Private document serving; mandatory docs before activation; grandfather existing approved drivers; dual `verified`/`isVerified`; audit trail; rider driver-card via REST+WS; scoped regression per sub-phase.
- **FINAL adjustments:** NO `users.photo_url` (profile_photos stays single source of truth); NO `vehiclePhotoUrl` in DriverProfile (derived from documents at DTO build time); `issueDate`/`expiryDate`/`documentNumber` on DriverDocument now; backend document-completeness endpoint; registration **DRAFT** state with explicit submit.

Execution order: **2A → regression → 2B → regression → 2C → regression → Phase 3 Flutter**. Backend contract is fully stable before Flutter consumes it.

**Phase 1 remains frozen.** Sub-phases consume Phase 1's API; never modify Phase 1 files.

---

## Phase 2A — Driver Documents Infrastructure (backend only)

### Objective
Private document subsystem: upload, list, download, delete, admin review, audit trail, per-type replacement, completeness endpoint. Registration gating is 2B.

### New Backend Files
| File | Purpose |
|------|---------|
| `entity/DriverDocument.java` | `id, driverId, documentType, fileName, fileUrl, fileSize, mimeType, status, adminNote, **issueDate, expiryDate, documentNumber**, uploadedAt, reviewedAt, reviewedBy` |
| `entity/DocumentStatus.java` | `PENDING, APPROVED, REJECTED, REUPLOAD_REQUESTED, EXPIRED` |
| `entity/DocumentType.java` | `PROFILE_PHOTO, LICENSE, VEHICLE_REGISTRATION, VEHICLE_PHOTO, INSURANCE, NATIONAL_ID` (required set = the 5 minus VEHICLE_PHOTO) |
| `repository/DriverDocumentRepository.java` | `findByDriverId`, `findByDriverIdAndId`, `findByDriverIdAndDocumentType`, `findByDriverIdOrderByUploadedAtDesc` |
| `service/DriverDocumentService.java` | Upload validation (extension allowlist, magic bytes for images, 10MB cap, server-generated filename into `uploads/documents/{driverId}/`), **replacement** (same-type new upload deletes old row + disk), list, getFile, delete (row + disk), admin status transitions, **completeness calculation** |
| `controller/DriverDocumentController.java` | Driver-owner endpoints |
| `dto/DriverDocumentResponse.java` | `id, documentType, fileName, fileUrl, fileSize, mimeType, status, adminNote, issueDate, expiryDate, documentNumber, uploadedAt, reviewedAt, reviewedBy` |
| `dto/DocumentReviewRequest.java` | `adminNote` |
| `dto/DocumentCompletenessResponse.java` | `required (5), uploaded, missing[] (e.g. ["INSURANCE"]), readyForSubmission` |

### Modified Backend Files
- `config/SecurityConfig.java` — **`/uploads/documents/**` must NOT be permitAll.** Documents served only through authenticated owner/admin endpoints.
- `config/StaticResourceConfig.java` — restrict static mapping so only `/uploads/photos/**` is exposed; document files must NOT be reachable via static resource handling (all doc access via authenticated controller endpoints). **[Added by explicit user decision 2026-08-02 — must not break Phase 1: photo URLs keep working exactly as before.]**
- `config/RateLimitingFilter.java` — add `/api/drivers/documents` upload rule (5/60s), mirroring the photo-upload rule. **[Added by explicit user decision 2026-08-02.]**
- `application.yml` — reuse multipart 10MB limit; add `rate-limit.doc-upload.*` (max 5, window 60). **[Added by explicit user decision 2026-08-02.]**

### New Endpoints
- `POST /api/drivers/documents` (multipart `file` + `documentType` + optional `issueDate/expiryDate/documentNumber`) — owner-only; rate-limited 5/min.
- `GET /api/drivers/documents` — owner-only; list own docs.
- `GET /api/drivers/documents/status` — owner-only; returns `DocumentCompletenessResponse` (Flutter just displays it — no client business rules).
- `GET /api/drivers/documents/{documentId}/file` — owner-only; streams file bytes (private).
- `DELETE /api/drivers/documents/{documentId}` — owner-only; deletes row + disk file.
- **Non-owner access policy (user decision 2026-08-02):** cross-user access to a driver document returns **404**, not 403. Ownership is enforced by repository queries scoped to the requester's userId (`findByDriverIdAndId`), and resource existence is intentionally not disclosed to other users.
- `GET /api/admin/drivers/{driverId}/documents` — admin-only; list with status.
- `GET /api/admin/drivers/{driverId}/documents/{documentId}/file` — admin-only; file/thumbnail bytes.
- `POST /api/admin/drivers/{driverId}/documents/{documentId}/approve`
- `POST /api/admin/drivers/{driverId}/documents/{documentId}/reject`
- `POST /api/admin/drivers/{driverId}/documents/{documentId}/request-reupload`
- `POST /api/admin/drivers/{driverId}/documents/{documentId}/expire`

### Audit Trail
Every admin doc action → `auditEventService.logEvent` with driverId, documentType, action, adminNote (reason), reviewedBy, reviewedAt. Example: driver 17, LICENSE, REJECTED, "Expired licence", Mustafa, timestamp.

### Regression Scope (2A)
- Touched: SecurityConfig, application.yml, new doc files/endpoints.
- Contract consumers: photo upload rate-limiter pattern (unchanged), admin auth (`extractAdminId`), `/uploads/photos/**` permitAll (unchanged).
- Verify Phase 1 endpoints still pass: register/login, photo upload/delete/serve, `GET /api/users/17` photoUrl.

---

## Phase 2B — Registration Workflow: Draft → Pending → Approval (backend only)

### Objective
Mandatory-docs registration with a **resumable draft**: `fill data → upload docs → submit → PENDING → admin approve → driver can go online`. If the app crashes mid-registration, the draft survives.

### Required Documents (validated at submit, not at account creation)
1. PROFILE_PHOTO · 2. LICENSE · 3. VEHICLE_REGISTRATION · 4. INSURANCE · 5. NATIONAL_ID

### Registration State Machine
`verificationStatus` enum on DriverProfile: **DRAFT → PENDING → APPROVED / REJECTED**

**Explicit Rider → Driver lifecycle (must be documented as the exact transition):**

```
Existing user account (any role: RIDER/SUPERUSER/ADMIN)
        ↓
create DriverProfile → verificationStatus = DRAFT     (registerAsDriver)
        ↓
upload required documents (5) + edit profile          (incremental, resumable on crash)
        ↓
POST /api/drivers/submit                              (completeness check)
        ↓
verificationStatus = PENDING
        ↓
admin approves  → APPROVED (isVerified=true)   OR   admin rejects → REJECTED (adminNote)
        ↓
driver can go online / accept rides                     (REJECTED can fix + resubmit → PENDING)
```

- `registerAsDriver` creates the profile in **DRAFT** (no docs required yet; driver fills data + uploads incrementally).
- `POST /api/drivers/submit` — validates all 5 required docs present (via `DriverDocumentService.completeness`); on success → PENDING; on failure → 400 with `DocumentCompletenessResponse` body.
- Admin `approve` → APPROVED + `isVerified=true` + audit. Admin `reject` → REJECTED + adminNote + audit. (Driver can resubmit from REJECTED → PENDING after fixing docs.)
- **Grandfather (rule, not fixed IDs — user decision 2026-08-02):** any existing `driver_profiles` row with `is_verified=true` is backfilled to `verification_status=APPROVED`; rows with `is_verified=false` are backfilled to `DRAFT` (so they can upload docs + resubmit). Applied via one-time SQL during the 2B DB step, **not** hardcoded to specific user IDs. This covers the actual verified drivers in the live DB (currently 13/14); the plan's earlier "(id 16, 17)" was incorrect (those are RIDERs with no driver profile).
- **Note:** a user who is already a RIDER and becomes a driver starts the same DRAFT lifecycle; `registerAsDriver` is the single entry point for the RIDER→DRIVER role transition and must not auto-activate the profile.

### Modified Backend Files
- `entity/DriverProfile.java` — add `verificationStatus` enum (`DriverVerificationStatus`: DRAFT/PENDING/APPROVED/REJECTED). Keep `isVerified` in sync (`true` ⟺ APPROVED) — enforced centrally in `setVerificationStatus`.
- `entity/DriverVerificationStatus.java` — **new enum (added during 2B).** NOTE: named `DriverVerificationStatus` (not `VerificationStatus`) because a pre-existing (uncommitted) trip-verification feature already owns `entity/VerificationStatus` (VERIFIED/SUSPICIOUS/FAILED); the name was changed during 2B to avoid collision.
- `controller/DriverController.java` — `registerAsDriver` → DRAFT (isVerified=false); new `POST /api/drivers/submit`; gate `goOnline` on APPROVED else 403 `{"error":"Driver not verified"}`.
- `controller/AdminController.java` — `POST /api/admin/drivers/{driverId}/approve`, `.../reject`; **also keep legacy `PATCH .../verify` consistent** (maps verified=true→APPROVED, false→DRAFT) to preserve the isVerified ⟺ APPROVED invariant.
- `dto/AdminDriverDetail.java` — add `verificationStatus`, `requiredDocsPresent`, `List<DriverDocumentResponse> documents`.
- `service/RideService.java` + `controller/RideController.java` — **acceptRide gate on APPROVED** else 403 (SecurityException already handled by controller catch; added to acceptRide's catch clause).
- `service/ScheduledRideService.java` + `controller/ScheduledRideController.java` — **[user decision 2026-08-02]** enforce the pending/draft skip here (the plan listed RideWebSocketService, but assignment/claim logic actually lives in ScheduledRideService.assignRide + getNearbyPendingScheduledRides): non-APPROVED drivers get 403 on assign and on nearby discovery. `RideWebSocketService` broadcast already filters verified drivers — no change needed there.

### API Contract Changes
- `registerAsDriver` → returns `verificationStatus=DRAFT`. **Contract change — flagged and tested.**
- New: submit, admin approve/reject driver.

### Regression Scope (2B)
- Touched: DriverProfile, DriverController, AdminController (driver approve/reject + legacy verify sync), AdminDriverDetail, RideService/RideController (acceptRide gate), ScheduledRideService/ScheduledRideController (assign + nearby gates). `RideWebSocketService` was **not** modified (confirmed during 2B — it only broadcasts; gating lives in the services listed).
- Contract consumers: driver online/accept flow, admin driver detail screen (`verified` key preserved via AdminDriverDetail.verified), scheduled-ride assignment.
- Verify grandfathering: all existing `is_verified=true` drivers remain APPROVED and can still go online (verified against live DB, currently 13/14).

---

## Phase 2C — Profile Completeness + Payload Enrichment (backend only)

### Objective
User/DriverProfile = single source of truth for profile fields; users edit exactly what's allowed (not verification status/docs/driverId); rider sees full driver card on accept over REST + WS (works on reconnect).

### Single-Source-of-Truth Rule (GPT adjustment — no duplication)
- **NO `users.photo_url`.** Profile photos live only in `profile_photos`. DTOs ask `PhotoService.getPhotoUrl(userId)` — exactly what Phase 1 established.
- **NO `vehiclePhotoUrl` in DriverProfile.** Derived at DTO build time from the driver's `VEHICLE_PHOTO` document (via `DriverDocumentService`); null if absent. The payload key exists; the storage does not.

### Modified Backend Files
- `entity/User.java` — **temporary dual-key (compatibility migration)**: keep `getVerified()` (emits `verified`) AND add `@JsonProperty("isVerified")` getter (emits `isVerified`). This is a **temporary** measure so raw-entity serializations keep working for both consumers during the transition. **Follow-up debt (tracked, not done now):** once Flutter and any other consumers migrate off `verified`, remove the legacy key and expose only one canonical field (`isVerified`). No photo column.
- `entity/DriverProfile.java` — add `vehicleYear` only (vehicle photo derived, not stored).
- `controller/UserController.java` — `PUT /api/users/{id}`:
  - Editable: `fullName`, `phoneNumber` (+`countryCode`, recompute `normalizedPhone`, reset `phoneVerified=false`, uniqueness enforced), `email` (re-issue JWT), `gender`.
  - Photo editable via existing photo-upload endpoint → `profile_photos` (NOT a writable field here).
  - **Not editable:** `verified`, `phoneVerified`, `role`, `id`.
  - Password: `currentPassword` → validate → `newPassword` → `confirmPassword` match.
  - Returns `UserResponse`.
- `dto/AuthResponse.java` + `controller/AuthController.java` — add `photoUrl` populated via `PhotoService.getPhotoUrl` at register/login.
- `controller/DriverController.java` — `GET/PUT /api/drivers/profile`:
  - Editable: `fullName`, `phoneNumber`, `email`, `vehicleModel`, `vehicleColor`, `vehicleYear`, `vehicleNumber`, `licenseNumber`.
  - **Not editable:** `verificationStatus`, documents, driverId.
  - Response adds `photoUrl` (PhotoService), `vehiclePhotoUrl` (derived), `vehicleYear`, `verifiedAt`.
- `controller/RideController.java` — `buildRideResponse`/`buildUserInfo`: add `driver.photoUrl`, `driver.vehiclePhotoUrl`, `driver.vehicleType`, `driver.averageRating`, `driver.fullName` to accepted-ride payload.
- `service/RideWebSocketService.java` — `notifyRideAccepted`: add `driverPhotoUrl`, `driverVehiclePhotoUrl`, `driverName`, `driverRating`, `vehicleModel`, `vehicleColor`, `vehicleNumber` (keep `licensePlate` alias); `notifyScheduledRideAssigned`: add `driverPhotoUrl`.
- `dto/AdminDriverDetail.java` — add `photoUrl`, `phoneNumber`, `licenseNumber`, `vehicleYear`, `vehiclePhotoUrl` (derived).
- `dto/AdminRiderDetail.java` — add `photoUrl`.
- `dto/AdminTripDetail.java` — `DriverInfo`: add `photoUrl`, `vehiclePhotoUrl`.

### Regression Scope (2C)
- Touched: User, DriverProfile, UserController, DriverController, AuthController/AuthResponse, RideController, RideWebSocketService, 3 admin DTOs.
- Contract consumers: Flutter `User.fromJson` (reads `isVerified` — now also on raw entity), `Ride.fromJson` (ignores unknown keys), WS handlers (additive keys + `licensePlate` preserved), `PUT /api/users/{id}` response shape (ad-hoc map → `UserResponse`; verify `rider_profile_screen._save`), account_screen `GET /api/users/{id}`.
- Verify no removed keys.

---

## Cross-Cutting Decisions (final)

| Decision | Resolution |
|----------|------------|
| Document serving | **Private.** `/uploads/documents/**` NEVER permitAll. `/uploads/photos/**` stays public (frozen). |
| Photo source of truth | `profile_photos` only. **No `users.photo_url`.** DTOs use `PhotoService.getPhotoUrl`. |
| Vehicle photo source of truth | Derived from `VEHICLE_PHOTO` document at build time. **No column in DriverProfile.** |
| Registration blocking | Mandatory docs validated at **submit** → PENDING → admin approve → online. DRAFT state resumable. Grandfather verified drivers. |
| Doc fields | `issueDate`, `expiryDate`, `documentNumber` on DriverDocument **now**. |
| Completeness | Backend `GET /api/drivers/documents/status`; Flutter only displays. |
| DB migration | `ddl-auto: update`. |
| Doc rate limit | Reuse 5/60s pattern. |
| `verified`/`isVerified` | Expose both keys on raw `User` temporarily — **documented as a temporary compatibility migration**; collapse to one canonical field (`isVerified`) in a tracked follow-up. |
| Replacement | New same-type upload deletes old row + disk (no orphans). |
| Audit | Every admin doc/driver action logged (driverId, type, action, reason, admin, time). |

## Database Changes (all via `ddl-auto: update`)
- `users`: **no changes** (photo stays in `profile_photos`).
- `driver_profiles`: add `vehicle_year INT`, `verification_status VARCHAR`.
- New table `driver_documents` (with issue/expiry/documentNumber columns).

**Production migration note (not a blocker):** `ddl-auto: update` is acceptable for development, but the project should migrate to **versioned migrations (Flyway or Liquibase) before production** so schema history is manageable. This is a future infrastructure milestone, tracked here so it isn't forgotten.

## Verification Checklist (per sub-phase, scoped)
1. `mvn -q compile` EXIT=0.
2. `flutter analyze` → 0 errors (no Flutter files changed; baseline 286 lints).
3. Live suite for touched modules + direct consumers (listed per sub-phase).
4. DB checks for new columns/table.

**Phase 2A static/security checks (user decision 2026-08-02):**
- ✅ Anonymous access to `/uploads/photos/**` still works.
- ✅ Direct access to `/uploads/documents/**` is no longer possible (static handler restricted to photos only).
- ✅ Owner can access documents through the controller.
- ✅ Admin can access documents through the controller.
- ✅ Other authenticated users receive **404** (not 403) through the controller — ownership enforced by scoped repository queries; resource existence intentionally not disclosed.

## Rollback Plan
- Revert the specific sub-phase files.
- `ALTER TABLE driver_profiles DROP COLUMN ...`; `DROP TABLE driver_documents;`; delete `uploads/documents/**`.
- Recompile + restart; re-run touched-module regression, then Phase 1 suite to confirm frozen contract restored.
- Mid-phase regression → STOP and report before continuing.

## Open Questions — resolved by GPT review
1. **Submit semantics:** explicit `POST /api/drivers/submit` (DRAFT→PENDING) — confirmed. ✅
2. **Scheduled rides & pending drivers:** skip pending/draft drivers at assignment — confirmed. ✅
3. **Admin thumbnails:** serve original file bytes (Flutter renders private URL); no server image dependency in 2A — confirmed. ✅
4. **Vehicle photo source:** derived from `VEHICLE_PHOTO` document; `vehiclePhotoUrl` remains a payload-only key — confirmed. ✅

## Remaining pre-code confirmation
Plan is approved pending your go-ahead to start **Phase 2A** and my re-verification that Phase 1 files are untouched and the build is green before the first 2A edit.
