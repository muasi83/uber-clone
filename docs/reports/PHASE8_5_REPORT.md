# Phase 8.5 — Configurable Expiry Windows

## Status
COMPLETE — Expiry-urgency windows are now served by the backend and consumed by the Flutter app instead of a hardcoded constant.

## What changed

### Backend files
- `chatserver/src/main/java/com/example/chatserver/controller/DocumentConfigController.java` (new) — exposes `GET /api/config/document-expiry`.
- `chatserver/src/test/java/com/example/chatserver/controller/DocumentConfigControllerTest.java` (new) — 4 tests covering the endpoint and property defaults.
- No changes to `DocumentExpiryService`, `DocumentExpiryProperties`, or `application.yml` — the properties already existed and were only *exposed*.

### Flutter files
- `chat_app/lib/services/expiry_config_service.dart` (new) — fetches and caches the expiry config, with legacy defaults.
- `chat_app/lib/widgets/driver_documents_panel.dart` — loads config in `_refresh()`; passes `soonDays: ExpiryConfigService.soonDays` to `documentExpiryColor`.
- `chat_app/lib/screens/admin_driver_details_screen.dart` — loads config in `initState()`; passes `soonDays: ExpiryConfigService.soonDays` to `documentExpiryColor`.
- `chat_app/test/phase85_expiry_config_service_test.dart` (new) — 6 tests covering defaults, parsing, invalid-value guarding, and color honoring the configured window.

### Configuration changes
The properties already existed in `chatserver/src/main/resources/application.yml` (used by `DocumentExpiryService`); they were unchanged in this phase and are now also readable by the client. Note: the file is YAML, not `application.properties`:

```yaml
document-expiry:
  soon-days: 30
  urgent-days: 7
  enabled: true
```

Equivalent property form:

```
document-expiry.soon-days=30
document-expiry.urgent-days=7
document-expiry.enabled=true
```

### New endpoint
`GET /api/config/document-expiry` (auth required, any valid token) → `200` with:

```json
{ "soonDays": 30, "urgentDays": 7, "enabled": true }
```

`401` when the `Authorization` header is missing or the token is invalid.

## Why each change was necessary

### Why `DocumentExpiryProperties`
The backend already owned the authoritative windows via the `@ConfigurationProperties`-bound `DocumentExpiryProperties` (soon 30 / urgent 7). The Flutter app had a hardcoded 31-day window (`documentExpiryColor` default) that drifted from the server truth. Rather than duplicating constants, the server value is now the single source of truth and is simply served back.

### Why a single `/api/config/document-expiry` endpoint
One lightweight, role-agnostic endpoint covers every surface that colors document expiry (driver panel + all admin screens), so there is exactly one place to read the windows. It deliberately does not require ADMIN so drivers can color their own documents consistently, but still requires an authenticated token to avoid leaking config to unauthenticated callers.

### Why client-side caching
The color is applied while rendering document lists; making every render block on HTTP would add latency and complexity. The service fetches once per session and serves the cached `soonDays` synchronously thereafter, matching the app's static-service style (`StorageService`, `CurrencyService`, etc.).

### Why fallback defaults exist
A network failure, server outage, or non-200 response must not change existing UI behavior. Until the first successful fetch the service keeps the legacy 31/7 defaults, so Phase 8.4 behavior is preserved verbatim when the endpoint is unreachable.

## Live verification
- `DocumentConfigControllerTest`: valid token → `200` with `{soonDays:30, urgentDays:7, enabled:true}`; invalid token → `401`; missing header → `401`; properties defaults → 30/7/enabled. **4/4 passed.**
- Flutter `phase85_expiry_config_service_test.dart`: defaults 31/7/enabled; payload adoption; null/invalid payload preservation; color becomes warning at the configured boundary; `reset()` restores defaults. **6/6 passed.**
- Driver panel (`driver_documents_panel.dart`) and admin screens (`admin_driver_details_screen.dart`) both call `ExpiryConfigService.load()` and pass `ExpiryConfigService.soonDays` — verified by analyzer-clean compile and code inspection.
- Fallback to defaults when the endpoint is unavailable: verified by `applyConfig(null)` / invalid-value tests and by the service design (defaults held until first successful fetch).

> Note: the running server must be restarted to pick up the new controller before the app can fetch config; endpoint behavior above was verified via the compiled test suite (Maven), not a live HTTP call, since no runtime auth token was available during this session.

## Regression analysis
- **Existing behavior unchanged with default values** — Flutter keeps 31 days until a fetch succeeds; backend windows unchanged.
- **No database/schema changes** — no entities, tables, or migrations.
- **No notification logic changes** — `DocumentNotificationService` untouched.
- **No document workflow changes** — `DriverDocumentService` upload/review/status flows untouched.
- **No avatar synchronization changes** — `PhotoService` and profile flows untouched.
- **No eligibility changes** — `DriverEligibilityService` untouched.

## Quality gates
- **Backend compile/tests**: `mvn -Dtest=DocumentConfigControllerTest test` → 4/4 passed, full module compiles.
- **flutter analyze**: 281 issues (baseline; one unused import introduced during development was removed before final run).
- **flutter test**: 95/95 passed (89 prior + 6 new).

## Known limitations
- Configuration is read on startup; a server restart is required after changing the properties.
- The client caches the fetched values for the session (until the app process restarts).
- The 31-day legacy default is used if the configuration cannot be retrieved.
- No admin UI to edit these values at runtime — they are operator-managed in `application.yml`.

## Deliverable
- `chatserver/.../controller/DocumentConfigController.java` (new)
- `chatserver/.../test/DocumentConfigControllerTest.java` (new)
- `chat_app/lib/services/expiry_config_service.dart` (new)
- `chat_app/lib/widgets/driver_documents_panel.dart`
- `chat_app/lib/screens/admin_driver_details_screen.dart`
- `chat_app/test/phase85_expiry_config_service_test.dart` (new)
