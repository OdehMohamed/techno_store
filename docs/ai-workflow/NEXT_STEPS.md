# NEXT_STEPS.md

Short-lived by design — reflects proposed next actions as of 2026-07-24. Overwrite at the end of each work session. History lives in `DECISIONS_LOG.md`; the full candidate work list lives in `BACKLOG.md`.

## Immediate

**Device lifecycle (ADR-005) is fully shipped, migrated, and live in production (PR #18 backend + PR #19 client + PR #20 hotfix, all in `main` as of 2026-07-24).** The device-deletion thread opened two sessions ago is now completely closed. The next line of work is an open sequencing decision within the still-active Reception & Maintenance review — candidates on the table (not yet deliberately chosen):
- Employee attribution (`receivedByEmployee`/`maintenanceEmployee`/`deliveredByEmployee`) drawn from a hardcoded `AppConstants` list, disconnected from real Staff Auth accounts.
- The intake-form-shape question (single large form vs. the PRD's "captures only what's genuinely required" framing).
- The confirmed dead code cleanup (`ManageCategoriesPage`+cubit, `maintenance_list_state.dart`, Invoice/Reopen TODO stubs, empty drawer stubs).

Small deferred items from the device lifecycle work, not urgent but worth deliberately picking up at some point:
- The 4 orphaned pre-`recordState` Firestore composite indexes in production (additive deploy never removes old indexes) — low-priority cleanup.
- Whether Restore's Admin-only enforcement and the `lifecycleEvents` split need a shared helper if a third Cloud Function ever needs the same "Admin + own-staffStatus-active" check — still just two call sites, still not revisited.

Staff Auth is also fully shipped and live-verified (PR #14 backend + PR #15 client). Small deferred items surfaced during PR #15, not urgent but worth deliberately picking up at some point:
- Criterion 3 (restart recheck) re-tested in true isolation (app fully closed *before* any `staffStatus` change) — currently just deferred, not failed.
- Old email/password dead code cleanup (`SignInFormEmailMethod`, `SignInButtons`, `sign_in_form_text_fields.dart`, commented-out `AuthCubit.signUp`/`AuthServices.signUpWithEmailAndPassword`) as its own separate PR.
- `phoneNumber` nullability reconsideration on the shared `UserData` model.
- Making `staffStatus` document creation a mandatory part of any future staff-account-creation feature.

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
