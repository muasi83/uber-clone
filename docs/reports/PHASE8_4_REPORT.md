# Phase 8.4 — Expiry Colors & Document List Clarity

## Status
COMPLETE — Flutter-only UI polish. Backend untouched.

## What was built
Consistent color language for document statuses + expiry-urgency coloring across driver and admin surfaces.

### New shared helper: `lib/utils/document_status_style.dart`
- `documentStatusInfo(status)` — single source of truth for the 5 primary statuses:
  | Status | Label | Color | Icon |
  |---|---|---|---|
  | APPROVED | Approved | success (green) | check_circle |
  | PENDING | Pending Review | warning (amber) | schedule |
  | REUPLOAD_REQUESTED | Re-upload Requested | info (purple) | autorenew |
  | REJECTED | Rejected | error (red) | cancel |
  | EXPIRED | Expired | errorDark (deep red) | event_busy |
  - Fixes: EXPIRED was grey/neutral → now urgent dark red; PENDING vs REUPLOAD_REQUESTED both were amber → now distinct.
- `documentExpiryColor(expiry, {now, soonDays=31})` — consistent expiry urgency: expired → errorDark, within 31 days → warning, else neutral.

### Consumers updated (all additive)
- `lib/widgets/document_status_chip.dart` (admin surfaces) → uses the helper, adds status icon.
- `lib/widgets/driver_documents_panel.dart` (driver surfaces) → `_buildStatusChip` uses the helper; "Expires" meta row now colored by `documentExpiryColor`.
- `lib/screens/admin_driver_details_screen.dart` → document list "Expires on" date colored by urgency; added `_tryParseDate`.

## Quality gates
- `flutter analyze`: **281** (baseline was 282 — improved by removing a now-unused import).
- `flutter test`: **89/89** (77 prior + 12 new in `test/phase84_document_status_style_test.dart`).

## Focused E2E
- Phase 8.4 is Flutter-only; no backend code changed, so no backend restart required.
- Live DB check (`driver_documents`): APPROVED=12, PENDING=17 present; all five status mappings exercised by unit tests (the other statuses only appear after the corresponding admin/driver flows run).

## Regression analysis
- Only UI presentation changed (labels/colors/icons); no API, schema, or model changes.
- Labels updated: "Pending" → "Pending Review", "Re-upload" → "Re-upload Requested", "Expired" neutral grey → dark red. No test asserted the old labels (verified phase3e/phase3a tests reference `driverVerificationInfo`, which is unchanged).
- Analyzer improved 282 → 281; all 89 tests green.

## Boundaries respected
- No backend modifications, no refactoring, no architectural improvements.
- Prior-phase behavior preserved; changes purely visual/clarity.

## Deliverable
- `chat_app/lib/utils/document_status_style.dart` (new)
- `chat_app/test/phase84_document_status_style_test.dart` (new)
- `chat_app/lib/widgets/document_status_chip.dart`
- `chat_app/lib/widgets/driver_documents_panel.dart`
- `chat_app/lib/screens/admin_driver_details_screen.dart`

## STOP — awaiting approval before Phase 8.5 (Configurable expiry windows)
