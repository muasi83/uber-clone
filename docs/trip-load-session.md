# Load-optimization session — paused state (resume here)

Saved: 2026-09-29. Frontend repo (`chat_app`). Nothing pending in code.

## Where we are

- **Backend (Render, live):** tiered dispatch fully deployed. C2 live (quiet
  DirectionsService logs). **C1 TEST config live** (Tomcat access log, pattern
  `%m %U %s %D %b`, no query/coordinates) — must be reverted after the
  30-min measurement window.
- **Access log location (changes every restart):** find with
  `find /tmp -name "access*" 2>/dev/null` (was
  `/tmp/tomcat.10000.8526.../logs/access.2026-09-29.log`).
- **Frontend:** 7 tiered-dispatch commits on `main` (not yet released to
  stores). Trip-load work is backend/measurement only so far.

## Proven already (2-min C1 test PASSED)

- Access log writes and is readable via Render Shell.
- Format OK: `GET /api/drivers/nearby 200 7972 12` (method, path, status,
  duration ms, bytes — no coordinates).
- ⚠️ Side finding: `/drivers/nearby` took **7–9 s/call** right after deploy.
  Probably cold JVM — re-check warm in the 30-min window. If still slow, it
  becomes its own fix (fires every 8 s from every rider home).

## Next steps (in order — each needs owner GO)

1. **30-min quiet-hour window:** desk test (request→accept→arrive→complete,
   5 min) + one short real drive (~10 min, any distance). Note start/end
   times. Then extract counts (`/calculate`, `/location`, `GET /{id}`),
   build baseline table.
2. **Revert C1 immediately after** (delete `tomcat:` block + push).
3. **Phase 2 code (R1+R2):** driver route debounce 1500 ms; drop per-ping
   audit row. Needs separate approval after baseline.
4. **Re-measure, then Phase 4 (R3/R4/R5)** only with torture-test sign-off.
5. **Separate security track:** unauthenticated `/api/routes/*` (quota-burn
   hole) — edge mitigation or auth fix, independent of load work.

## Key numbers (code-derived estimates, to validate in step 1)

- 15 km trip ≈ 5,100 backend HTTP (incl. ~2,850 route recalcs) + ~1,900 WS
  + ~2,850 Google calls + ~7,600 DB reads + ~5,700 DB writes.
- Fleet baseline ≈ 6 polls/min per online driver + M×3 queries per dispatch.
- Full analysis: `chatserver/docs/trip-load-decision-brief.md` (+ `V004_RUNBOOK.md`).

## Process rules agreed with owner

- Per-phase reports; never proceed without explicit GO.
- Trip resilience (reconnect/resume, no cancelled trips) outranks savings.
- R3/R4/R5 never ship without real-device torture tests.
