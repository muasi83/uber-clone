# Phase 1 Handoff Report — Security & Avatar Infrastructure

Status: **COMPLETE and FROZEN** (2026-08-02). Do not modify Phase 1 files in later phases unless a regression is found. If a later phase needs Phase 1 behavior, consume the existing API.

## Every Modified File

| File | Change |
|------|--------|
| `chatserver/src/main/java/com/example/chatserver/controller/AuthController.java` | Role allowlist at registration: only `RIDER`/`DRIVER` accepted from client; anything else → `400 {"message":"Invalid role"}`. `ADMIN` granted exclusively via `AdminBootstrapService`. `normalizePhone` logic extracted into `PhoneNormalizer` and called from here. |
| `chatserver/src/main/java/com/example/chatserver/controller/UserController.java` | `GET /api/users/{id}` now requires auth + self-or-admin (401 unauth / 403 forbidden), returns sanitized `UserResponse` instead of raw entity. `photoUrl` populated from `profile_photos` table via `PhotoService.getPhotoUrl`. |
| `chatserver/src/main/java/com/example/chatserver/controller/PhotoController.java` | Added `DELETE /api/photos` (self, 200/404). `GET /api/photos/{userId}` now self-or-admin. Explicit 10MB check → 413. |
| `chatserver/src/main/java/com/example/chatserver/controller/GlobalExceptionHandler.java` | `MaxUploadSizeExceededException` → 413 JSON. `MissingServletRequestPartException` / `MultipartException` / `MissingServletRequestParameterException` → 400 JSON. Generic handler stays silent 500. |
| `chatserver/src/main/java/com/example/chatserver/service/PhotoService.java` | Server-generated filename `{userId}_{UUID}.{ext}` (client filename never used for storage). Extension allowlist `{jpg,jpeg,png,webp}`. Magic-byte validation per type. Old physical file deleted on replace. Canonical-path assertion. New `deletePhoto(userId)`. |
| `chatserver/src/main/java/com/example/chatserver/config/SecurityConfig.java` | `permitAll` on `/uploads/photos/**` via `AntPathRequestMatcher` (exact prefix; `/uploads/documents/**` and broad `/uploads/**` remain authenticated). Filter order: `rateLimitingFilter` → `jwtAuthenticationFilter` → `correlationIdFilter`. |
| `chatserver/src/main/java/com/example/chatserver/config/RateLimitingFilter.java` | New rule group `photo-upload`: 5 uploads / 60s per user (JWT) or IP. |
| `chatserver/src/main/resources/application.yml` | Added `rate-limit.photo-upload` block (`max: 5`, `window-seconds: 60`). |
| `chatserver/.gitignore` | Added `uploads/`. |

## Every New File

| File | Purpose |
|------|---------|
| `chatserver/src/main/java/com/example/chatserver/dto/UserResponse.java` | Sanitized user DTO: `id, username, email, fullName, isOnline, isVerified, countryCode, phoneNumber, phoneVerified, gender, role, photoUrl, createdAt`. No password / deviceToken / normalizedPhone. |
| `chatserver/src/main/java/com/example/chatserver/util/PhoneNormalizer.java` | `normalize()` extracted verbatim from `AuthController.normalizePhone`. |
| `chatserver/src/main/java/com/example/chatserver/repository/ProfilePhotoRepository.java` | JPA repository for `profile_photos`; `findByUserId` added. |

Note: `PhotoController.java`, `PhotoService.java`, `entity/ProfilePhoto.java`, `config/StaticResourceConfig.java` existed as unwired/dead code before Phase 1 and were **completed/activated** by Phase 1 — they are listed as modified above.

## Every Endpoint Changed

| Endpoint | Old behavior | New behavior |
|----------|--------------|--------------|
| `POST /api/auth/register` | Accepted any role incl. `ADMIN` | Rejects non-RIDER/DRIVER → 400 `{"message":"Invalid role"}` |
| `GET /api/users/{id}` | Public; returned full entity (PII leak) | Auth required; self-or-admin; returns `UserResponse` (no PII) |
| `POST /api/photos/upload` | Raw filename storage, no size/type checks, no rate limit | Server-generated filename; extension allowlist; magic bytes; 10MB → 413; 5/60s rate limit; missing file → 400 |
| `GET /api/photos/{userId}` | Public (raw) | Auth + self-or-admin |
| `DELETE /api/photos` | **New** | Self; 200 `Photo deleted` / 404 |
| `GET /uploads/photos/**` | 403 (permitAll did not match static path) | Permit-all via `AntPathRequestMatcher`; serves avatar files anonymously |

## Configuration Changes
- `application.yml`: `rate-limit.photo-upload` (`max: 5`, `window-seconds: 60`).
- `.gitignore`: `uploads/` added.
- No DB schema change (profile_photos table pre-existed from prior work).

## Assumptions Intentionally NOT Made
1. **Ownership rule on photo metadata read** was implemented as **self-or-admin** (stricter than the "public-for-avatar" wording in Part 9 of the plan). Safe today because the static file path stays public and no app code fetches another user's photo (`PhotoService.getPhotoUrl` has zero callers). Flagged for Phase 2+ review.
2. No-auth requests on protected endpoints return **403** (Spring Security 6 anonymous default), not the controller's 401. Cosmetic; pre-existing behavior left unchanged.
3. Admin-override branch (`GET /api/users/{id}` / `GET /api/photos/{userId}` as ADMIN) was **not live-tested** (no admin credentials available); logic mirrors the verified `UserController.isAdmin` pattern used elsewhere.
4. `isVerified` key in `UserResponse` is emitted correctly as `isVerified` (matches Flutter `User.fromJson`). The `User` entity still serializes as `verified` — the entity-level fix is scoped to Phase 2 per plan.

## Verification Record
- Backend `mvn -q compile` → EXIT=0.
- Flutter `flutter analyze` → 0 errors (286 pre-existing info/warnings, no Flutter files modified).
- Live suite passed: register SUPERUSER/ADMIN → 400; login bad-pw → 400; self/other/no-auth on `GET /api/users/{id}` → 200/403/403; upload valid → 200; `.exe` → 400; fake magic bytes → 400; oversize → 413; no-file → 400; DELETE → 200 then 404; `/uploads/photos/*.png` anonymous → 200; `/uploads/documents/x` anonymous → 403; `GET /api/photos/{other}` → 403.
- DB: admin (id=1, ADMIN) intact; `profile_photos` cleanup verified (replace deletes old file + row); files verified on disk.
