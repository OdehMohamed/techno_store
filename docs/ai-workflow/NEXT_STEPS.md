# NEXT_STEPS.md

Short-lived by design — reflects proposed next actions as of 2026-07-09. Overwrite at the end of each work session. History lives in `DECISIONS_LOG.md`; the full candidate work list lives in `BACKLOG.md`.

## Immediate

1. Plan the maintenance devices search/filtering feature (Firestore-based v1: structured filters + phone/name/model/IMEI/serial search, explicitly addressing `BACKLOG.md` item 1g's unbounded-stream cost problem), get it approved, then implement on its own branch per `CONTRIBUTING.md`.

## Before any release that includes the forced-update feature (not urgent today, but must not be forgotten)

1. Create the real `appConfig/global` document in the Firebase Console — nothing in the app does this automatically. Needs, at minimum: `version.android.minRequiredVersion`/`latestVersion`/`packageId`, `version.ios.minRequiredVersion`/`latestVersion`/`appStoreId` (leave `appStoreId` null until the App Store listing exists — the app already degrades gracefully for that case). Set `minRequiredVersion` at or below whatever version is being shipped, or every user is immediately blocked on launch.
2. Confirm the deployed Firestore rules in production already include `appConfig/global` (they do, as of 2026-07-09 — this note is a reminder to re-check if rules are ever redeployed from an older branch/tag).

## Before any public production release (not urgent today, but don't lose track)

1. `BACKLOG.md` item 0a — direct/bypass-the-UI authorization testing against the deployed Firestore/Storage rules. Blocking for public release specifically, not for continued internal/closed-testing use.
2. Store metadata finalization (Privacy Policy, Data Safety, Store Listing, screenshots) — deferred during release-infrastructure setup, unrelated to Phase 1 but on the same radar.

## Low-priority cleanup, whenever convenient

3. `BACKLOG.md` item 0b — delete the one orphaned `private/sensitive` subdocument (`Sd7A3a1jMByVEy9vKcfP`).
4. `BACKLOG.md` item 0c — no periodic cleanup exists yet for a Storage image that's uploaded but never referenced in its device document (only a theoretical risk so far; not observed in practice).
5. `BACKLOG.md` item 0d — verify/tighten customer `phoneNumber` updates (currently only `create` requires the Auth-verified phone; `update` doesn't).
6. `BACKLOG.md` item 10 — wire up account-activation enforcement (`AuthCubit._listenToActivation`) as its own feature, whenever the product owner wants to pick it up.
7. `BACKLOG.md` items 11/12/13 — soft update, maintenance mode, feature flags: schema-ready in `appConfig/global` since the 2026-07-09 forced-update work, none implemented yet.
8. Pre-existing items from the original audit not yet touched: the dormant `users/{uid}/devices` subcollection, `status` string vocabulary inconsistency, `docs/features/*.md` still doesn't exist.
