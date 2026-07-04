# NEXT_STEPS.md

Short-lived by design — reflects proposed next actions as of 2026-07-04 (Phase 1 closed). Overwrite at the end of each work session. History lives in `DECISIONS_LOG.md`; the full candidate work list lives in `BACKLOG.md`.

## Immediate

No Phase 1 action is outstanding. Ready for feature development direction from the product owner.

## Before any public production release (not urgent today, but don't lose track)

1. `BACKLOG.md` item 0a — direct/bypass-the-UI authorization testing against the deployed Firestore/Storage rules. Blocking for public release specifically, not for continued internal/closed-testing use.
2. Store metadata finalization (Privacy Policy, Data Safety, Store Listing, screenshots) — mentioned by the product owner as intentionally deferred during release-infrastructure setup, unrelated to Phase 1 but also a public-release blocker worth keeping on the same radar.

## Low-priority cleanup, whenever convenient

3. `BACKLOG.md` item 0b — delete the one orphaned `private/sensitive` subdocument (`Sd7A3a1jMByVEy9vKcfP`).
4. Pre-existing items from the original audit not touched by Phase 1: the dormant `users/{uid}/devices` subcollection, `status` string vocabulary inconsistency, `docs/features/*.md` still doesn't exist.
