# CURRENT_TASK.md

Status: reflects the state as of 2026-07-09. Overwrite this file's content at the start/end of each work session — it should only ever describe what's active right now, not history (history belongs in `DECISIONS_LOG.md`).

## Active task

**Maintenance devices search/filtering — not yet started, planning next.** Firestore-based v1 (no Algolia/Typesense at this stage): structured filters plus search by phone/name/model/IMEI/serial where feasible, explicitly designed to avoid worsening the existing unbounded staff device stream (`BACKLOG.md` item 1g). Per the documented workflow, this starts with a short implementation plan for approval before any code, on its own `feature/*` branch.

## Status

- [x] Phase 1 (security & data architecture) closed, `v1.0.0` tagged and released.
- [x] Post-v1.0.0 Storage authorization investigation and signup regression resolved (six commits, `origin/main`).
- [x] `docs/ai-workflow/` staleness review completed and applied.
- [x] **Forced app update mechanism shipped.** PR #2 squash-merged (`d843ddc`) to `main`. See `DECISIONS_LOG.md` (2026-07-09 entry) for the full design/build/test record. `feature/forced-app-update` deleted locally and remotely.
- [ ] Maintenance devices search/filtering — not started.

## What is NOT yet decided

- The search/filtering implementation plan itself — architecture for structured filters vs. free-text search (phone/name/model/IMEI/serial), and how it resolves the existing unbounded-stream cost problem (`BACKLOG.md` item 1g), still needs to be written and approved.

## Important reminder — not yet done, must happen before any release containing the forced-update feature

`appConfig/global` does not exist in production. Nothing in the app creates it automatically, by design. Before shipping any build that includes the forced-update code to real users, a real `appConfig/global` document must be deliberately created in the Firebase Console with production-appropriate values (`minRequiredVersion` at or below the version being shipped, correct `packageId`, and the real iOS `appStoreId` once that listing exists) — see `NEXT_STEPS.md`.

Ongoing, tracked-but-not-active follow-ups remain in `BACKLOG.md` (0a blocking public release, 0b/0c/0d/10 non-blocking).
