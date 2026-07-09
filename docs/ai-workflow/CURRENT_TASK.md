# CURRENT_TASK.md

Status: reflects the state as of 2026-07-09. Overwrite this file's content at the start/end of each work session — it should only ever describe what's active right now, not history (history belongs in `DECISIONS_LOG.md`).

## Active task

**None — awaiting product owner direction on what to pick up next.** See `BACKLOG.md` for tracked candidate work (item 0a is blocking for public release; others are non-blocking or deferred).

## Status

- [x] Phase 1 (security & data architecture) closed, `v1.0.0` tagged and released.
- [x] Post-v1.0.0 Storage authorization investigation and signup regression resolved (six commits, `origin/main`).
- [x] `docs/ai-workflow/` staleness review completed and applied.
- [x] **Forced app update mechanism shipped.** PR #2 squash-merged (`d843ddc`) to `main`. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full design/build/test record. `feature/forced-app-update` deleted locally and remotely.
- [x] **Maintenance devices search/filtering (v1) shipped.** PR #3 squash-merged (`1a3d350`) to `main`. Firestore-native per-tab bounded queries, structured filters (brand/employee/date-range), and client-side search (name/phone/model/IMEI), with swipe navigation preserved. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full design/build/test record. `firestore.indexes.json`'s 4 composite indexes deployed to `technostore-v2` and confirmed `READY`. `feature/maintenance-devices-search-filter` deleted locally and remotely.

## What is NOT yet decided

- Nothing currently in flight. Next task selection is a product-owner decision — see `BACKLOG.md`/`NEXT_STEPS.md`.

## Important reminder — not yet done, must happen before any release containing the forced-update feature

`appConfig/global` does not exist in production. Nothing in the app creates it automatically, by design. Before shipping any build that includes the forced-update code to real users, a real `appConfig/global` document must be deliberately created in the Firebase Console with production-appropriate values (`minRequiredVersion` at or below the version being shipped, correct `packageId`, and the real iOS `appStoreId` once that listing exists) — see `NEXT_STEPS.md`.

Ongoing, tracked-but-not-active follow-ups remain in `BACKLOG.md` (0a blocking public release, 0b/0c/0d/10 non-blocking).
