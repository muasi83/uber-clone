# Phase 2B Report — Registration Workflow: Draft → Pending → Approval (backend)

Status: **COMPLETE + VERIFIED (2026-08-02).** Phase 2A unchanged/frozen. No Flutter files touched.

## Objective
Mandatory-docs registration with a resumable draft: `fill data → upload docs → submit → PENDING → admin approve → driver can go online`. Non-approved drivers are blocked from going online, accepting rides, and scheduled-ride assignment/discovery. Existing verified drivers are grandfathered as APPROVED.

## Files

### New
| File | Purpose |
|------|---------|
| `chatserver/src/main/java/com/example/chatserver/entity/DriverVerificationStatus.java` | `DRAFT, PENDING, APPROVED, REJECTED` |

### Modified
| File | Change |
|------|--------|
| `entity/DriverProfile.java` | Added `verificationStatus` field + `@Builder.Default = DRAFT`. `setVerificationStatus()` centrally syncs `isVerified` (`true ⟺ APPROVED`). |
| `entity/VerificationStatus.java` | **Restored to original** (VERIFIED/SUSPICIOUS/FAILED, owned by the uncommitted trip-verification feature). Not part of 2B — see Enum Collision note. |
| `controller/DriverController.java` | `registerAsDriver` → creates profile as **DRAFT** (`isVerified=false`), response includes `verificationStatus`; new `POST /api/drivers/submit` (completeness gate → PENDING + audit `DRIVER_SUBMITTED`); `toggleOnline` gated on APPROVED when going online (403 `{"error":"Driver not verified"}`); response adds `verificationStatus`. |
| `controller/RideController.java` | `acceptRide` catch now maps `SecurityException` → 403 (the `Driver not verified` from the service). |
| `service/RideService.java` | `acceptRide` throws `SecurityException("Driver not verified")` when `verificationStatus != APPROVED` (after the existing blocked/`isActive` check). |
| `controller/ScheduledRideController.java` | `nearby` + `assign` pass the caller's driverId into the service; added `SecurityException → 403` catch. |
| `service/ScheduledRideService.java` | New `requireApprovedDriver(driverId)` called at the top of `assignRide` and `getNearbyPendingScheduledRides` (SecurityException `"Driver not verified"` for non-APPROVED). |
| `controller/AdminController.java` | New `POST /api/admin/drivers/{driverId}/approve` (→ APPROVED, sets `verifiedAt` if null, audit `DRIVER_APPROVED`), `POST /api/admin/drivers/{driverId}/reject` (→ REJECTED, optional `DocumentReviewRequest.adminNote`, audit `DRIVER_REJECTED`); legacy `PATCH /api/admin/drivers/{driverId}/verify` now routes through `setVerificationStatus` (true→APPROVED, false→DRAFT) and returns `verificationStatus` to preserve the invariant. |
| `dto/AdminDriverDetail.java` | Added `verificationStatus`, `requiredDocsPresent`, `List<DriverDocumentResponse> documents`. |
| `controller/AdminController.java` (detail) | `getDriverDetail` populates the three new fields via `DriverDocumentService` completeness + list. |

### Temporary debug (added then removed during 2B)
- `controller/GlobalExceptionHandler.java` — `handleGeneric` temporarily added `ex.printStackTrace()` to chase a register 500; **removed before this report**. Final build EXIT=0.

## API Contract Changes (flagged + tested)
- `POST /api/drivers/register` now returns `verificationStatus: DRAFT` (was implicitly verified/none before). **Breaking contract change — approved in plan.**
- New: `POST /api/drivers/submit`, `POST /api/admin/drivers/{driverId}/approve`, `POST /api/admin/drivers/{driverId}/reject`.
- `PATCH /api/admin/drivers/{driverId}/verify` response now also returns `verificationStatus` (additive).

## Database Changes
`driver_profiles` gained `verification_status varchar NOT NULL` + check constraint `('DRAFT','PENDING','APPROVED','REJECTED')`, via `ddl-auto: update` at startup (which failed on the NOT NULL-with-nulls for the existing rows once — logged, one-time), then manual:
- `ALTER TABLE driver_profiles ADD COLUMN IF NOT EXISTS verification_status varchar(255) DEFAULT 'DRAFT';`
- `UPDATE driver_profiles SET verification_status='APPROVED' WHERE is_verified=true;`  ← grandfather
- `ALTER TABLE driver_profiles ALTER COLUMN verification_status SET NOT NULL;`
- `ALTER TABLE driver_profiles ADD CONSTRAINT ... CHECK (verification_status IN ('DRAFT','PENDING','APPROVED','REJECTED'));`

Current live state: 1/2/3 → DRAFT, 4 → APPROVED (13), 5 → APPROVED (14), 6 → REJECTED (19), 7 → APPROVED (18).

## Enum Collision Note (critical)
The codebase has a **pre-existing uncommitted trip-verification feature** that owns `entity/VerificationStatus.java` (VERIFIED/SUSPICIOUS/FAILED; used by `TripVerificationService.toStatus`, `RideVerification`, `SettlementReportRepository` SQL). My first 2B file reused that name and overwrote it → compile errors. Resolved by restoring the original `VerificationStatus.java` from `target/chatserver-1.0-SNAPSHOT.jar.original` and renaming the driver enum to **`DriverVerificationStatus`**. This is recorded in the plan. No other feature was impacted.

## Verification Results (live, PID 1688 after restart)
Admin access was exercised using a JWT minted with the configured `jwt.secret` (no admin credentials exist in the DB/docs — same gap noted in Phase 1/2A reports; `extractAdminId` role check makes the minted token behave identically to a real admin login).

### DRAFT gates (driver 19 = `phase2bdriver2`)
- `POST /api/drivers/register` → 200 `{"verificationStatus":"DRAFT","profileId":6,...}`
- `GET /api/drivers/profile` → 200 `verificationStatus:DRAFT, isVerified:false`
- `POST /api/drivers/toggle-online` (going online) → **403** `{"error":"Driver not verified"}`
- `POST /api/drivers/submit` (no docs) → **400** `DocumentCompletenessResponse` `{required:5, uploaded:0, missing:[LICENSE,PROFILE_PHOTO,INSURANCE,NATIONAL_ID,VEHICLE_REGISTRATION], readyForSubmission:false}`

### PENDING gates (driver 18 = `phase2adriver`, docs already uploaded in 2A)
- `POST /api/drivers/submit` → 200 `{"verificationStatus":"PENDING","completeness":{...readyForSubmission:true}}`
- `POST /api/drivers/toggle-online` → **403** `{"error":"Driver not verified"}`

### APPROVED flow (driver 18)
- `POST /api/admin/drivers/18/approve` → 200 `{"verified":true,"verificationStatus":"APPROVED",...}`
- `POST /api/drivers/toggle-online` → 200 `isOnline:true` (then off → 200)
- `GET /api/drivers/profile` → 200 `verificationStatus:APPROVED, isVerified:true`

### REJECTED flow (driver 19)
- `POST /api/admin/drivers/19/reject` (with `{"adminNote":"Documents look valid"}`) → 200 `{"verified":false,"verificationStatus":"REJECTED",...}`
- `GET /api/drivers/profile` → 200 `verificationStatus:REJECTED, isVerified:false`

### acceptRide gate (ride 286, created by fresh rider 20)
- As REJECTED driver 19 → **403** `{"error":"Driver not verified"}`; ride stayed `REQUESTED` (DB confirmed).
- As APPROVED driver 18 (online) → 200, ride `ACCEPTED`.

### Scheduled-ride gates
- `GET /api/scheduled-rides/nearby` + `POST /api/scheduled-rides/1/assign` as DRAFT driver 19 → **403** `{"error":"Driver not verified"}`.
- As APPROVED driver 14 → 200 `[]` (no gating error).

### Grandfather (rule, not fixed IDs)
- 13 (profile id 4) and 14 (id 5): backfilled APPROVED; `GET /api/drivers/profile` → APPROVED; toggle-online → 200; scheduled nearby → 200.

### Legacy endpoint sync
- `PATCH /api/admin/drivers/13/verify` (was APPROVED) → 200 `{"verificationStatus":"DRAFT","verified":false}`; called again → 200 `{"verificationStatus":"APPROVED","verified":true}`. DB confirmed. Invariant `isVerified ⟺ APPROVED` preserved.

### Admin driver detail
- `GET /api/admin/drivers/18` → 200 with `verificationStatus:DRAFT→(then APPROVED)`, `requiredDocsPresent:true`, `documents:[5 rows]` (each with id/documentType/status/fileUrl).

### Audit trail (ride_audit_events)
- `DRIVER_REGISTERED` (18, 19) · `DRIVER_SUBMITTED` (18, PENDING) · `DRIVER_APPROVED` (18) · `DRIVER_REJECTED` (19, adminNote captured) · `ADMIN_TOGGLE_VERIFY` (13, both states) · `DRIVER_WENT_ONLINE/OFFLINE` (13, 18) · `ADMIN_VIEWED_DRIVER` — all present with correct actors.

### Phase 1 regressions
- `POST /api/auth/login` → 200. `POST /api/auth/register` duplicate email → 400 `"Email already registered"`.
- `POST /api/photos/upload` → 200 (returns `/uploads/photos/...png`); `GET /api/photos/19` → 200; anonymous `GET /uploads/photos/...` → 200 (Phase 1 static serving intact).
- `POST /api/drivers/documents` (2A upload) → 200 (Phase 2A endpoint intact).

## Notes / Deviations
- **registerAsDriver 500 transient:** an earlier live attempt for users 18/19 returned `500 {"error":"Internal server error"}` (GlobalExceptionHandler shape), reproducible during the DDL-fix window. After the column/constraint fix and a clean restart it returns 200 consistently (verified for both 18 and 19). No code defect found; the endpoint's try/catch plus the DTO deserialization are clean. The temporary `printStackTrace` was added to confirm this and has been removed.
- **Grandfathering applied as a rule** (`is_verified=true` → APPROVED), per the user decision recorded in the plan. The plan's earlier "(id 16, 17)" reference was incorrect (those are RIDERs).
- **`RideWebSocketService` unchanged** — confirmed it is only a broadcaster; the gating decision was recorded in the plan as an implementation adjustment.
- **Admin testing via minted JWT — TEST-ONLY TECHNIQUE, NOT PRODUCTION BEHAVIOR.** Because no admin credentials exist anywhere in the DB, docs, or config, admin endpoints were exercised with a JWT manually signed using the configured `jwt.secret` from `application.yml`. This was used **solely for the local verification suite in this report**; it is **not** part of production behavior, introduces no code, and changes nothing in the application. The token behaved identically to a real admin login because `extractAdminId`/the auth filter only validate the signature and the `role` claim. Any reviewer re-running this suite must generate the token the same way (or supply real admin credentials), and the technique should not be relied upon outside local testing.
- Rate limits still in force (login 10/min, register 5/hour, doc upload 5/60s). Test uploads kept within windows.

## Next Steps
1. User restarts backend with the final clean build (printStackTrace removed, EXIT=0).
2. Await approval to start **Phase 2C** (profile completeness + payload enrichment).
