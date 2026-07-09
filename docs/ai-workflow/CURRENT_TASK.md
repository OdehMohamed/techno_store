# CURRENT_TASK.md

Status: reflects the state as of 2026-07-09. Overwrite this file's content at the start/end of each work session — it should only ever describe what's active right now, not history (history belongs in `DECISIONS_LOG.md`).

## Active task

**Feature development, post-v1.0.0.** Two features approved by the product owner, to be built one at a time on dedicated branches per `CONTRIBUTING.md`, each starting with a short implementation plan before any code:

1. **Forced app update mechanism** — in progress. Branch: `feature/forced-app-update`. A partial, incomplete implementation already exists (`in_app_update` package, Android-only, wired only into the sign-in screen) — see the implementation plan for what's kept vs. replaced.
2. **Maintenance devices search/filtering** — not started. Firestore-based v1 (no Algolia/Typesense at this stage): structured filters plus search by phone/name/model/IMEI/serial where feasible, explicitly designed to avoid worsening the existing unbounded staff device stream (`BACKLOG.md` item 1g).

## Status

- [x] Phase 1 (security & data architecture) closed, `v1.0.0` tagged and released.
- [x] Post-v1.0.0 Storage authorization investigation and signup regression fully resolved — six commits on `main`, pushed to `origin/main`, retested end-to-end with no regressions. See `DECISIONS_LOG.md` (2026-07-07/08 entries) for the full record.
- [x] `docs/ai-workflow/` staleness review completed and applied (this session): `DECISIONS_LOG.md` backfilled, `CURRENT_TASK.md`/`NEXT_STEPS.md` refreshed, stale `drafts/*.rules.draft` files removed.
- [ ] Forced app update — implementation plan approved, branch created, not yet implemented.
- [ ] Maintenance devices search/filtering — not started, deliberately sequenced after forced update.

## What is NOT yet decided

- Exact mechanism for the forced-update minimum-version check (Firestore doc vs. Remote Config) and whether the existing Android-only `in_app_update` flow is kept as a complementary nudge or removed — being resolved in the implementation plan.
- Whether search/filtering's free-text search fields need a denormalized search-tokens approach, and where the Firestore-native v1's limitations should be documented as a Phase 2 candidate (Algolia/Typesense) — to be addressed when that feature's plan is written.

Ongoing, tracked-but-not-active follow-ups remain in `BACKLOG.md` (0a blocking public release, 0b/0c/0d/10 non-blocking).
