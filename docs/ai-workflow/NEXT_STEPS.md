# NEXT_STEPS.md

Short-lived by design — reflects proposed next actions as of 2026-07-23. Overwrite at the end of each work session. History lives in `DECISIONS_LOG.md`; the full candidate work list lives in `BACKLOG.md`.

## Immediate

**Decide what's genuinely implementation-ready**, based on the now-complete Auth & Entry review (PR #9–#13, all merged into `main`) — a deliberate sequencing call per the agreed process, not a default to Staff Auth just because it's the most recent line of work. Product owner has explicitly asked for an active recommendation, not just their own call. Per the standing process correction (`DECISIONS_LOG.md`, 2026-07-23): once something clears product decisions, behavior, and architecture with no blockers, implementation is the natural next step, not a further planning phase.

If Staff Auth is selected: implementation includes the disposition of remaining dead code (`AuthCubit.signUp`, `AuthServices.signUpWithEmailAndPassword`, `SignInFormEmailMethod`/`SignInButtons` as reference only, per prior direction not to revive them wholesale).

Separately, still outstanding from the v1.1.0 release: the actual Shorebird release / Play Console / TestFlight upload for `v1.1.0`, per `CONTRIBUTING.md` §11's boundary (product owner's to run manually).

## Production `appConfig/global` — done, 2026-07-09

Recreated (had been fully removed after the forced-update feature's pre-PR test cleanup — see `DECISIONS_LOG.md`) with safe, non-blocking values: `minRequiredVersion` "1.0.0" on both platforms (matches the currently shipped version, so no user is blocked), correct Android `packageId`, `appStoreId` null (no iOS listing yet). Verified live via an unauthenticated REST read. Firestore rules already permit public read/no client write for this document, confirmed unchanged since Phase 1.

## Before any public production release (not urgent today, but don't lose track)

1. Store metadata finalization (Privacy Policy, Data Safety, Store Listing, screenshots) — deferred during release-infrastructure setup, unrelated to Phase 1 but on the same radar.
2. `BACKLOG.md` item 0a — direct/bypass-the-UI authorization testing. No longer blocking as of 2026-07-09 (product owner accepted the residual risk — see `BACKLOG.md`), but still open and worth doing eventually if there's ever a moment to spare.

## Low-priority cleanup, whenever convenient

3. `BACKLOG.md` item 0b — delete the one orphaned `private/sensitive` subdocument (`Sd7A3a1jMByVEy9vKcfP`).
4. `BACKLOG.md` item 0c — no periodic cleanup exists yet for a Storage image that's uploaded but never referenced in its device document (only a theoretical risk so far; not observed in practice).
5. `BACKLOG.md` item 0d — verify/tighten customer `phoneNumber` updates (currently only `create` requires the Auth-verified phone; `update` doesn't).
6. `BACKLOG.md` item 10 — wire up account-activation enforcement (`AuthCubit._listenToActivation`) as its own feature, whenever the product owner wants to pick it up.
7. `BACKLOG.md` items 11/12/13 — soft update, maintenance mode, feature flags: schema-ready in `appConfig/global` since the 2026-07-09 forced-update work, none implemented yet.
8. `BACKLOG.md` item 14 (new, 2026-07-09) — `MaintenanceListCubit`'s action methods swallow service-layer exceptions instead of rethrowing, so the dialogs' failure handling never triggers; found during the search/filter feature's cleanup audit, deliberately left unfixed to keep that PR scoped.
9. `BACKLOG.md` item 15 (new, 2026-07-09) — Home page carousel uses hardcoded third-party image URLs; needs real store assets whenever there's content to put there.
10. `BACKLOG.md` item 7's Home-page bullet (new, 2026-07-09) — the single-tab `TabBar`/`TabBarView` around the fully commented-out Store tab is dead chrome; a product/roadmap call on whether Store is coming back, not assumed here.
11. Pre-existing items from the original audit not yet touched: `status` string vocabulary inconsistency (`BACKLOG.md` item 3), `docs/features/*.md` still doesn't exist. (The dormant `users/{uid}/devices` subcollection item is resolved — see `BACKLOG.md` item 4.)
