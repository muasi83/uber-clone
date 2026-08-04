# Phase 8.6 — Email Notifications for Document Events

## Status
COMPLETE — Drivers now receive an email (in addition to the existing in-app notification + Firebase push) when their documents are approved/rejected/re-upload-requested, and when documents expire or are about to expire.

Scope decided with reviewer: **email only** (SMS has no provider/credentials configured), covering **review status + expiry** events.

## What changed

### Backend files
- `chatserver/src/main/java/com/example/chatserver/service/EmailService.java` — rewritten:
  - Explicit constructor with `@Value("${spring.mail.username:}") String mailUsername` (replaces `@RequiredArgsConstructor`).
  - New `sendDocumentNotification(String toEmail, String subject, String body)` — guarded, failure-safe (never throws).
  - Existing `sendOtpEmail` overloads unchanged in behavior.
- `chatserver/src/main/java/com/example/chatserver/service/DocumentNotificationService.java` — sends `user.getEmail()` a copy of the review notification (approved / rejected / re-upload requested / admin-expired) via `emailService`.
- `chatserver/src/main/java/com/example/chatserver/service/DocumentExpiryService.java` — sends `user.getEmail()` a copy of the scheduled expiry notification (DOCUMENT_EXPIRING_30 / EXPIRING_7 / EXPIRED) via `emailService`.

### Flutter files
None — emails are sent server-side directly to the driver's registered email; the app continues to surface the same in-app notification + push as before.

## Why each change was necessary

### Why a dedicated `sendDocumentNotification` method
Document emails must never break the caller. `notifyReview` runs inside the admin document-status transaction and the expiry check runs on a daily scheduler — a mail outage must not roll back a status change or crash the job. The method therefore swallows send failures (logged to `backend.log` / stderr), unlike the OTP path which must surface SMTP errors for login/reset UX.

### Why the `spring.mail.username` guard
The OTP flow already requires SMTP; the new document emails run in background/scheduler contexts where SMTP might be absent (local dev, CI, fresh clones). When `spring.mail.username` is blank the email is skipped with a single log line instead of throwing, so document workflows still complete.

### Why wiring inside the two existing services
Both services already own the notification pipeline (in-app row + Firebase push + audit event) and already look up the `User`. Adding one `emailService.sendDocumentNotification(...)` call reuses that single pipeline rather than introducing a parallel mailer that could drift from the in-app copy.

### Why no Flutter changes
The driver-facing channel is the email inbox; the app surfaces the notification/push identically. No API, payload, or schema change reaches the client.

## Live verification
- `EmailServiceTest` (4): sends to correct recipient with subject+body when configured; skips when SMTP not configured; skips when recipient blank; swallows SMTP failures. **4/4 passed.**
- `DocumentNotificationServiceTest` (7): approve now also verifies `emailService.sendDocumentNotification("driver@example.com", …)`; pending-status and missing-user paths verify email is never sent. **7/7 passed.**
- `DocumentExpiryServiceTest` (2): expiry check sends email to the driver; disabled expiry still sends nothing. **2/2 passed.**
- Full backend suite: **47 tests, 0 failures, 0 errors** (includes prior `DocumentConfigControllerTest` 4, `PhotoControllerRoleTest` 3, `DriverEligibilityServiceTest` 9, audit/util tests 11, etc.).

> Note: actual SMTP delivery to a real inbox requires the Gmail SMTP credentials in `application.yml` (already present) and an outbound connection; verified at unit level via a mocked `JavaMailSender`. A live delivery test can be performed by running the app and triggering a document review or expiry check.

## Regression analysis
- **Existing behavior unchanged** — the in-app `Notification` row, Firebase push payload, and audit events are untouched; email is additive.
- **No database/schema changes.**
- **No notification logic changes** — types, titles, bodies, and dedup (`existsByUserIdAndTypeAndRelatedUserId`) preserved; email simply mirrors the generated title/body.
- **No document workflow changes** — `DriverDocumentService` upload/review/status flows untouched.
- **No avatar synchronization changes.**
- **No eligibility changes** — `DriverEligibilityService` untouched (only invoked as before by the scheduler).
- **OTP email behavior unchanged** — `sendOtpEmail` signature and delivery path identical; only constructor wiring changed (still a single Spring-managed bean).

## Quality gates
- **Backend compile/tests**: full `mvn test` suite → 47/47 green.
- **flutter analyze / test**: unaffected (no Flutter changes); prior gates remain 281 baseline / 95/95.

## Configuration
No new configuration. Uses the existing SMTP settings already in `chatserver/src/main/resources/application.yml`:

```yaml
spring:
  mail:
    host: smtp.gmail.com
    port: 587
    username: muasiassi@gmail.com
    password: <gmail-app-password>
    properties:
      mail:
        smtp:
          auth: true
          starttls:
            enable: true
            required: true
```

Expiry scheduling remains gated by the existing `document-expiry.enabled` flag; the email is only sent when a notification would otherwise be created.

## Known limitations
- **Email only** — SMS is not implemented (no provider/credentials configured).
- Requires the driver's `User.email` to be set; blank recipients are skipped silently.
- If SMTP is unavailable the email is skipped (logged) — the in-app notification and push still go out.
- Gmail's outgoing rate limits apply to the daily expiry job; bursts on mass re-verifications may queue/fail at Gmail's side (logged, non-fatal).

## Deliverable
- `chatserver/src/main/java/com/example/chatserver/service/EmailService.java`
- `chatserver/src/main/java/com/example/chatserver/service/DocumentNotificationService.java`
- `chatserver/src/main/java/com/example/chatserver/service/DocumentExpiryService.java`
- `chatserver/src/test/java/com/example/chatserver/service/EmailServiceTest.java` (new)
- `chatserver/src/test/java/com/example/chatserver/service/DocumentNotificationServiceTest.java` (extended)
- `chatserver/src/test/java/com/example/chatserver/service/DocumentExpiryServiceTest.java` (new)

## STOP — development complete
All planned phases 8.2–8.6 are complete. Per the agreed plan, development now stops and the project transitions into **full application testing**.
