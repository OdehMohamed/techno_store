# CURRENT_TASK.md

Status: reflects the state as of 2026-07-09. Overwrite this file's content at the start/end of each work session — it should only ever describe what's active right now, not history (history belongs in `DECISIONS_LOG.md`).

## Active task

**None — awaiting product owner direction on what to pick up next.** See `BACKLOG.md` for tracked candidate work.

## Status

- [x] Phase 1 (security & data architecture) closed, `v1.0.0` tagged and released.
- [x] Post-v1.0.0 Storage authorization investigation and signup regression resolved (six commits, `origin/main`).
- [x] `docs/ai-workflow/` staleness review completed and applied.
- [x] **Forced app update mechanism shipped.** PR #2 squash-merged (`d843ddc`) to `main`. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full design/build/test record. `feature/forced-app-update` deleted locally and remotely.
- [x] **Maintenance devices search/filtering (v1) shipped.** PR #3 squash-merged (`1a3d350`) to `main`. Firestore-native per-tab bounded queries, structured filters (brand/employee/date-range), and client-side search (name/phone/model/IMEI), with swipe navigation preserved. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full design/build/test record. `firestore.indexes.json`'s 4 composite indexes deployed to `technostore-v2` and confirmed `READY`. `feature/maintenance-devices-search-filter` deleted locally and remotely.
- [x] **`appConfig/global` recreated in production (2026-07-09)**, with safe non-blocking values, verified live via unauthenticated REST read. See `DECISIONS_LOG.md`.
- [x] **`BACKLOG.md` item 0a (direct/bypass-the-UI authorization testing) no longer blocks release** — product owner accepted it as a residual risk on 2026-07-09, given the deployed rules are unchanged since Phase 1 and app-level validation has been extensive since. See `BACKLOG.md`/`DECISIONS_LOG.md`.
- [x] **Staff Home page UI/UX polish shipped.** PR #4 squash-merged (`a951dfb`) to `main`. Hides the promotional banner and Contact Us footer on the Home page for staff only (customer/guest experience unchanged); FAB now respects the platform safe area; device cards are slightly denser; Load More is now the last item of the scrollable list and correctly preserves scroll position. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full record. `feature/home-page-staff-ui` deleted locally and remotely.

## What is NOT yet decided

- Nothing currently in flight. Next task selection is a product-owner decision — see `BACKLOG.md`/`NEXT_STEPS.md`.

Ongoing, tracked-but-not-active follow-ups remain in `BACKLOG.md` (0a deferred/accepted risk; 0b/0c/0d/10/14/15 non-blocking, including two new findings from the Home page audit — dead single-tab `TabBar` chrome under item 7, and hardcoded carousel image URLs as item 15).
