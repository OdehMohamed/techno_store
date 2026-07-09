# CURRENT_TASK.md

Status: reflects the state as of 2026-07-09. Overwrite this file's content at the start/end of each work session — it should only ever describe what's active right now, not history (history belongs in `DECISIONS_LOG.md`).

## Active task

**Home page UI/UX for staff users — planning/audit stage, no code yet.** For staff users only, hide the top banner and the Contact Us section on the Home page; customers keep the current experience unchanged. Also auditing the current Home page for any other UI/UX polish genuinely worth doing, to propose (not implement) alongside the required change. Per the documented workflow: audit → plan → approval → feature branch → commit-by-commit implementation.

## Status

- [x] Phase 1 (security & data architecture) closed, `v1.0.0` tagged and released.
- [x] Post-v1.0.0 Storage authorization investigation and signup regression resolved (six commits, `origin/main`).
- [x] `docs/ai-workflow/` staleness review completed and applied.
- [x] **Forced app update mechanism shipped.** PR #2 squash-merged (`d843ddc`) to `main`. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full design/build/test record. `feature/forced-app-update` deleted locally and remotely.
- [x] **Maintenance devices search/filtering (v1) shipped.** PR #3 squash-merged (`1a3d350`) to `main`. Firestore-native per-tab bounded queries, structured filters (brand/employee/date-range), and client-side search (name/phone/model/IMEI), with swipe navigation preserved. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full design/build/test record. `firestore.indexes.json`'s 4 composite indexes deployed to `technostore-v2` and confirmed `READY`. `feature/maintenance-devices-search-filter` deleted locally and remotely.
- [x] **`appConfig/global` recreated in production (2026-07-09)**, with safe non-blocking values, verified live via unauthenticated REST read. See `DECISIONS_LOG.md`.
- [x] **`BACKLOG.md` item 0a (direct/bypass-the-UI authorization testing) no longer blocks release** — product owner accepted it as a residual risk on 2026-07-09, given the deployed rules are unchanged since Phase 1 and app-level validation has been extensive since. See `BACKLOG.md`/`DECISIONS_LOG.md`.

## What is NOT yet decided

- The Home page audit/plan itself — which specific additional polish items (beyond the required staff-banner/Contact-Us hide) are worth proposing, still to be written and approved.

Ongoing, tracked-but-not-active follow-ups remain in `BACKLOG.md` (0a now deferred/accepted risk rather than blocking; 0b/0c/0d/10/14 non-blocking).
