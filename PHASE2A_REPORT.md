# Phase 2A Report — Driver Documents Infrastructure

Status: **COMPLETE — awaiting approval before Phase 2B.**

## Objective
Private driver-document subsystem: upload, list, download, delete, admin review, audit trail, per-type replacement, completeness endpoint. Registration gating deferred to Phase 2B. Backend-only; no Flutter changes.

## Files Created (8)
| File | Purpose |
|------|---------|
| `chatserver/.../entity/DocumentType.java` | `PROFILE_PHOTO, LICENSE, VEHICLE_REGISTRATION, VEHICLE_PHOTO, INSURANCE, NATIONAL_ID` |
| `chatserver/.../entity/DocumentStatus.java` | `PENDING, APPROVED, REJECTED, REUPLOAD_REQUESTED, EXPIRED` |
| `chatserver/.../entity/DriverDocument.java` | `id, driverId, documentType, fileName, fileUrl, fileSize, mimeType, status, adminNote, issueDate, expiryDate, documentNumber, uploadedAt, reviewedAt, reviewedBy` |
| `chatserver/.../repository/DriverDocumentRepository.java` | scoped queries: `findByDriverIdAndId`, `findByDriverIdAndDocumentType`, `findByDriverIdOrderByUploadedAtDesc` |
| `chatserver/.../service/DriverDocumentService.java` | upload validation (extension allowlist jpg/jpeg/png/webp/pdf + magic bytes incl. `%PDF`), 10MB cap, server-generated filename into `uploads/documents/{driverId}/`, **replacement** (same-type new upload deletes old row + disk), list, getFile, delete (row + disk), admin status transitions, completeness |
| `chatserver/.../controller/DriverDocumentController.java` | 5 driver-owner endpoints |
| `chatserver/.../dto/DriverDocumentResponse.java` | full document DTO |
| `chatserver/.../dto/DocumentReviewRequest.java` | `adminNote` |
| `chatserver/.../dto/DocumentCompletenessResponse.java` | `required=5, uploaded, missing[], readyForSubmission` |

## Files Modified (4)
| File | Change |
|------|--------|
| `controller/AdminController.java` | 6 admin doc endpoints (list, file, approve, reject, request-reupload, expire) + audit via `auditEventService.logEvent`; added `DriverDocumentService` field; file-streaming helper |
| `config/StaticResourceConfig.java` | restricted static mapping to `/uploads/photos/**` only — documents no longer statically reachable (user decision) |
| `config/RateLimitingFilter.java` | `doc-upload` rule for `/api/drivers/documents` POST, 5/60s, per-user key (user decision) |
| `application.yml` | `rate-limit.doc-upload.*` (max 5, window 60) |

`config/SecurityConfig.java` — **no functional change required**: `/uploads/documents/**` already falls under `anyRequest().authenticated()` (only `/uploads/photos/**` is permitAll); `/api/admin/**` already `hasRole("ADMIN")`. Verified intact.

## Endpoints Added
Driver-owner (`/api/drivers/documents`):
- `POST /api/drivers/documents` — multipart `file` + `documentType` + optional `issueDate/expiryDate/documentNumber`; 5/min rate limit; replacement per type.
- `GET /api/drivers/documents` — list own docs (desc by uploadedAt).
- `GET /api/drivers/documents/status` — completeness.
- `GET /api/drivers/documents/{documentId}/file` — private file stream (owner-only).
- `DELETE /api/drivers/documents/{documentId}` — delete row + disk.

Admin (`/api/admin`):
- `GET /drivers/{driverId}/documents`
- `GET /drivers/{driverId}/documents/{documentId}/file`
- `POST /drivers/{driverId}/documents/{documentId}/approve`
- `POST /drivers/{driverId}/documents/{documentId}/reject`
- `POST /drivers/{driverId}/documents/{documentId}/request-reupload`
- `POST /drivers/{driverId}/documents/{documentId}/expire`
Each admin action writes an audit event (driverId, documentId, documentType, status, adminNote).

## Database Changes
- New table `driver_documents` (15 columns) via `ddl-auto: update`. Verified present.
- No changes to `users`/`driver_profiles` in Phase 2A.

## Verification Performed
Backend: `mvn -q compile` EXIT=0. Flutter: `flutter analyze` → 286 issues (Phase 1 baseline, 0 errors, no Flutter files changed). Backend restarted by user (PID 20860), fresh DB schema applied.

Live regression (scoped to 2A modules + direct consumers), all passed:
- ✅ **Static/security (per user checklist):**
  - Anonymous `/uploads/photos/**` → **200** (Phase 1 contract intact).
  - `/uploads/documents/17/test.pdf` anonymous → **403**; with valid auth → **403** (no static handler; documents not reachable statically).
  - Owner file access via controller → **200** (17 bytes, `%PDF` magic verified).
  - Other authenticated user (id 16) accessing driver-18 doc → **404** (ownership via scoped repo query; existence not disclosed).
  - Other user's list → **200 `[]`** (scoped to own docs).
  - Admin routes gated: non-admin + anonymous on `/api/admin/drivers/...` → **403** (mapped, not 404).
- ✅ **Upload validation:** valid PDF → 200; `.exe` → 400; fake-magic PDF → 400; 11MB oversize → 413; missing file part → 400; invalid `documentType` → 400; invalid `issueDate` → 400.
- ✅ **Replacement:** uploading second LICENSE deleted old row (id 1) + old disk file; only new row (id 2) + file remained. Same for NATIONAL_ID chain (ids 4→5→6).
- ✅ **Completeness:** 5 required (excl. VEHICLE_PHOTO); `{required:5, uploaded, missing[], readyForSubmission}` correct at 0/1/2/4/5 uploaded; `readyForSubmission=true` only when all 5 present; VEHICLE_PHOTO upload does not count toward required.
- ✅ **Delete:** 200 → file 404 → repeat delete 404; disk file removed.
- ✅ **Rate limit:** 6 rapid uploads → `200,200,200,429,429,429` (5/60s, per-user).

**Rate-limit clarification (documented, no defect):** the burst test `200,200,200,429,429,429` is correct because the limiter is a **sliding 60s window that counts every POST** to `/api/drivers/documents` (including requests that later fail validation), keyed per-user. Two uploads by user 18 were still inside the window when the burst began — `REPLACE LICENSE` (id=2) at 13:15:56 and `INSURANCE` (id=3) at 13:16:10 (both verified in `driver_documents.uploaded_at`). The three burst successes filled slots 3–5 (5 total in window); the 4th burst request became the 6th within 60s → 429. Matches the intended 5/60s per-user policy.
- ✅ **Phase 1 regression:** register/login (new user 18 login via file-body), `GET /api/users/17` still returns `photoUrl`, photo upload → 200, photo static serving 200.
- ✅ **Server log:** no errors/unhandled exceptions during the entire test session.

## Regression Analysis
- **Photo upload/serving, register/login, `/api/users/{id}`**: all Phase 1 contracts re-verified live — untouched.
- **Static resource change**: `/uploads/photos/**` mapping points to the same physical dir (`file:uploads/photos/`) → same URLs, same files, no photo break (verified 200).
- **Rate limiter**: only added a new path rule (`doc-upload`); existing `photo-upload`/login/register/rides rules untouched (photo upload still 200 after 2A).
- **AdminController**: additive fields/methods only; existing admin endpoints untouched.
- **No Flutter dependency**: all new endpoints are additive; no keys removed from any existing response.

## Known Limitations / Follow-up Items
1. **Admin success-path not live-tested** — no ADMIN credentials available (same as Phase 1). Relies on the verified `extractAdminId` pattern (`AdminController.java`) + the fact that admin routes are correctly mapped (403 for non-admin, not 404). Should be re-verified when admin creds are available.
2. **Test data left in DB**: driver 18 (`phase2adriver@test.com` / `pass123`) now has 5 documents (LICENSE, INSURANCE, NATIONAL_ID, VEHICLE_REGISTRATION, PROFILE_PHOTO + VEHICLE_PHOTO) — intentionally kept as ready fixture for Phase 2B registration-flow testing.
3. **Rate-limit note**: the 429 also fired on a request with a *missing* body part; this is the documented Phase-1 pattern (limiter runs before controller) and is acceptable.
4. **Phase 2B dependencies**: `DriverDocumentService` already exposes `getCompleteness` (used for required-docs validation) and status transitions (used by admin approve/reject for the driver-level gate) — no rework expected.
5. **Plan updates from user decisions during 2A**: plan file now records the RateLimitingFilter + StaticResourceConfig modifications and the 404-for-non-owner policy.

## Rollback (if needed)
- Delete the 9 new source files + revert the 4 modified files.
- `DROP TABLE driver_documents;` via psql; delete `uploads/documents/**`.
- Restore `StaticResourceConfig` mapping to `/uploads/**`; remove `doc-upload` rule + yml; recompile + restart; re-run Phase 1 suite.

Phase 2A is complete and awaiting approval to proceed to **Phase 2B** (registration workflow: DRAFT → PENDING → APPROVED + goOnline/acceptRide gating + admin driver approve/reject + grandfathering).
