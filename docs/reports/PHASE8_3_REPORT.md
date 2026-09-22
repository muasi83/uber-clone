# Phase 8.3 — Dashboard Quick Filters

## Status
COMPLETE — Flutter-only, additive. Backend untouched.

## What was built
Dashboard quick filters let an admin jump from a dashboard stat straight into a pre-filtered driver list.

### Backend
- No changes. Reuses existing `GET /api/admin/drivers` and `GET /api/admin/documents/expiry-summary`.

### Flutter
- `lib/utils/admin_driver_filters.dart` (new): pure, unit-tested filter helper `filterAdminDrivers(...)` supporting:
  - Status: `all | draft | pending | approved | rejected | online | offline | available | busy`
  - Expiry: `none | expired | expiring7 | expiring30`
  - Text search (name/vehicle model/plate), status+expiry combine as AND.
  - `driverIdSet(...)` helper converts expiry-summary lists into `Set<int>`.
- `lib/screens/admin_driver_list_screen.dart`:
  - New optional constructor params `initialStatusFilter` (default `all`) and `initialExpiryFilter` (default `none`) — default behavior identical to prior phases.
  - Chip bar extended: added **Draft / Approved / Rejected** status chips, plus a second expiry row **All / Expired / Expiring 7 / Expiring 30**.
  - Loads drivers + expiry summary in parallel; expiry chips filter via the precomputed driver-id sets.
- `lib/screens/admin_dashboard_screen.dart`:
  - Verification status cells now tappable → open driver list pre-filtered (Draft/Pending/Approved/Rejected).
  - Expiry group headers now tappable (with chevron affordance) → open driver list pre-filtered to that expiry bucket.
  - Pending-docs section unchanged.

## Quality gates
- `flutter analyze`: **282** (baseline, 0 new).
- `flutter test`: **77/77** (59 baseline + 18 new in `test/phase83_dashboard_filters_test.dart`).

## Focused E2E (live server)
- `GET /api/admin/drivers`: 10 drivers; status distribution DRAFT=3, PENDING=2, APPROVED=4, REJECTED=1 — matches dashboard counts.
- `GET /api/admin/documents/expiry-summary`: expired=0, expiring7=1 (driver 25), expiring30=0.
- Cross-check: driver 25 (in expiring7 set) exists in the drivers list (APPROVED, offline) — expiry filter set maps to a real driver card.
- Filter logic verified by unit tests against these exact response shapes.

## Regression analysis
- Prior phases untouched functionally: only additive UI in dashboard + driver list; no service/model changes; no backend/SQL/DTO changes.
- `pending2` l10n key no longer referenced in driver list (replaced by `statusPending`); key still present in arb files — no removal to avoid churn.
- Analyzer count back to baseline 282 after resolving 4 type errors from `Future.wait` inference (fixed by awaiting futures separately).

## Boundaries respected
- No refactoring, no architectural improvements, no Phase 9 scope.
- Backend tests not run-touched (no backend code changed); Flutter gates green.

## Deliverable
- `chat_app/lib/utils/admin_driver_filters.dart` (new)
- `chat_app/test/phase83_dashboard_filters_test.dart` (new)
- `chat_app/lib/screens/admin_driver_list_screen.dart` (additive)
- `chat_app/lib/screens/admin_dashboard_screen.dart` (additive)

## STOP — awaiting approval before Phase 8.4 (Expiry colors & document list clarity)
