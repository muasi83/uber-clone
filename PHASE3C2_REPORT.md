# Phase 3C2 Report — Driver Document Workflow

**Status: COMPLETE (awaiting approval before 3D).**
**Date:** 2026-08-02
**Backend frozen throughout — zero backend source changes (`.java` file-set stable at 99: 37 modified + 62 untracked, identical to the 3B/3C1 snapshots).**

## Scope delivered (Flutter only)
1. **Upload all six document types** — new reusable panel `lib/widgets/driver_documents_panel.dart`:
   - PROFILE_PHOTO, LICENSE, VEHICLE_REGISTRATION, VEHICLE_PHOTO, INSURANCE, NATIONAL_ID (constant list + labels in `lib/models/driver_document.dart`).
   - Camera/Gallery picker via `image_picker`, per-document upload with in-flight spinner.
2. **Document upload progress/status display** — per-document chip (Pending/Approved/Rejected/Re-upload/Expired), filename, Replace/Delete actions, per-type status.
3. **Completeness endpoint consumed** — `GET /api/drivers/documents/status` → progress card ("Required documents: X of 5", progress bar, missing list, ready state). `DocumentCompleteness` model.
4. **Submit action** — `POST /api/drivers/submit` → `submitDriver` in `DriverService`; surfaces backend message/completeness on failure.
5. **DRAFT → PENDING transition** — registration review step now registers **and** submits; `POST /api/drivers/documents` uploads happen in a new Documents step inserted between Vehicle Info and Review (4 steps total). Documents step gates on readiness.
6. **REJECTED → resubmit** — new `DriverDocumentsScreen` (from menu or profile "Complete Verification" button shown for DRAFT/REJECTED): re-upload/replace docs + resubmit → PENDING. Profile banner reflects the resulting state.
7. **Driver home reflects states** — PENDING shows "Pending Review" (no action), APPROVED shows verified, DRAFT/REJECTED show a "Complete Verification" action.

## Backend contract consumed (read-only, from 2A/2C)
- `POST /api/drivers/documents` — multipart `file` + `documentType` (+ optional issueDate/expiryDate/documentNumber); replaces same-type doc; returns `DriverDocumentResponse`.
- `GET /api/drivers/documents` — list; `GET /api/drivers/documents/status` — `{required:5, uploaded, missing[], readyForSubmission}`; `DELETE /api/drivers/documents/{id}`.
- `POST /api/drivers/submit` — 200 → PENDING (includes completeness); 400 → completeness (not ready). **No status guard** → REJECTED can resubmit (verified live).
- Completeness requires **5** types (VEHICLE_PHOTO is optional). `DocumentStatus`: PENDING/APPROVED/REJECTED/REUPLOAD_REQUESTED/EXPIRED.

## Verification matrix
| Check | Result |
|---|---|
| `flutter analyze` | ✅ **0 errors** — 282 issues (down from 283 at 3C1; all pre-existing style infos) |
| `flutter build apk --debug` | ✅ built |
| `flutter test` | ✅ **27/27** (added 8: document types/labels, `DriverDocument` parse+round-trip, `DocumentCompleteness` ready/not-ready/tolerant) |
| Backend frozen | ✅ `.java` set identical to 3B/3C1 (99 files) |

## Live backend regression (localhost:8080)
| # | Flow | Result |
|---|---|---|
| A | Completeness on fresh DRAFT (user 22) | ✅ `required:5 uploaded:0 ready:false` |
| B | Upload 6 types (incl. optional VEHICLE_PHOTO) | ✅ 200 each → 6 docs, all `PENDING` |
| C | Completeness after uploads | ✅ `required:5 uploaded:5 missing:[] ready:true` |
| D | Submit (DRAFT→PENDING) | ✅ 200 `verificationStatus:"PENDING"` |
| E | Profile reflects PENDING | ✅ `verificationStatus:PENDING isVerified:false` |
| F | Toggle online while PENDING | ✅ 403 `{"error":"Driver not verified"}` (surfaced in-app) |
| G | Simulate REJECTED (DB) | ✅ profile shows `REJECTED` |
| H | Replace a doc (resubmit path) | ✅ 200, old file removed, new id |
| I | Resubmit from REJECTED | ✅ 200 → PENDING (backend supports REJECTED→resubmit) |
| J | Delete doc | ✅ 200; completeness unaffected (optional doc) |
| K | **Full end-to-end, fresh user 23**: register → registerAsDriver (DRAFT) → upload 5 required → status ready → submit → PENDING, `vehicleYear:2020` | ✅ all 200 |

## Findings / notes (frozen backend, not changed)
- **Doc-upload rate limit: 5 POSTs / 60s per user** (`/api/drivers/documents`). Uploading all 6 docs in one rapid burst can 429 on the 6th — the app surfaces the failure and the user retries. Noted as a UX consideration, not a bug.
- **Document file URLs** (`/uploads/documents/22/...`) are not anonymously servable; the app displays doc *status* only (no previews) this phase — consistent with scope.
- `VEHICLE_PHOTO` is not part of backend completeness (5 required). The panel marks it "Optional".
- Admin approval/rejection screens are **out of scope** (Phase 3E). REJECTED path here was driven by DB state; the admin review UI comes later.

## Test-data note
- New DB rows: user 22 `phase3c1_driver` (PENDING, 5 docs, optional vehicle photo removed), user 23 `phase3c2_driver` (PENDING, 5 docs, vehicleYear 2020, profile id 9). Driver 13/ADMIN 1 untouched.

## Files changed (Flutter only)
| File | Change |
|---|---|
| `lib/models/driver_document.dart` | **new** — `DriverDocument`, `DocumentCompleteness`, doc-type constants/labels |
| `lib/services/driver_service.dart` | +`uploadDriverDocument`, `getDriverDocuments`, `getDocumentCompleteness`, `deleteDriverDocument`, `submitDriver` |
| `lib/widgets/driver_documents_panel.dart` | **new** — upload/status/completeness panel (Camera/Gallery, replace/delete, chips, progress) |
| `lib/screens/driver_documents_screen.dart` | **new** — standalone doc screen w/ status header + submit (DRAFT/REJECTED) |
| `lib/screens/driver_registration_screen.dart` | Documents step (4 steps), readiness gate, review submit = register + submit |
| `lib/screens/driver_home_screen.dart` | "Complete Verification" action (DRAFT/REJECTED) + "Documents & Verification" menu item |
| `test/phase3c2_documents_model_test.dart` | **new** — 8 model tests |

## Next step
Await approval, then begin **Phase 3D — Rider driver-card enrichment** (REST + WS paths verified independently).
