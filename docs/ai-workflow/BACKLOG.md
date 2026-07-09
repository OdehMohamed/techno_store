# BACKLOG.md

Candidate work items surfaced during the 2026-07-03 baseline review. **Nothing here is scheduled or approved** unless explicitly marked otherwise. Items move to `CURRENT_TASK.md` only when the product owner explicitly picks one. Each item states whether it's grounded in a confirmed fact or an assumption still needing confirmation, so priority calls aren't made on guesses.

Items are grouped by theme, not by priority — prioritization is a product-owner decision.

## Phase 1 follow-ups (tracked at Phase 1 closure, 2026-07-04 — see `PHASE1_CLOSURE_SUMMARY.md`)

0a. **ACCEPTED RISK / DEFERRED (2026-07-09) — Direct/bypass-the-UI authorization testing.** Phase 1's functional validation (Checkpoint 4) confirmed the *app* behaves correctly for all roles, but did not test whether the *deployed Firestore/Storage rules themselves* correctly deny a client that skips the UI and calls the API directly — the exact guarantee this whole security effort exists to provide. Suggested approach (from the Phase 1C conversation, unchanged, kept for whenever this is picked up): use existing, product-owner-designated real accounts (not newly created ones, per prior decision) — mint custom auth tokens via Admin SDK for each role (Customer, Admin, Reception, Maintenance, and confirm whether any Guest/`type:9` account exists at all), exchange for real ID tokens, and make authenticated REST calls directly against Firestore/Storage to confirm: customer denied read of `private/sensitive` (including their own device); customer denied writing `type` on their own profile; staff can read/write as expected; unauthenticated requests denied outright. Keep customer-account checks read-only; do write-denial tests against staff accounts instead, per the residual-risk discussion at the time.
    **2026-07-09 decision:** no longer blocking for the upcoming production release. Product owner reviewed this item — re-confirmed the exact deployed rules text (`type` immutability on `update`, `private/sensitive` staff-only read/write) is unchanged since Phase 1, and is comfortable proceeding on the strength of the deployed rules plus the app-level validation already performed (Phase 1 Checkpoint 4, and every feature's manual testing since). Accepted as a residual risk rather than closed as resolved — this item stays open and can be picked up later; it simply no longer gates the release.

0b. **Non-blocking — orphaned `private/sensitive` subdocument.** Device `Sd7A3a1jMByVEy9vKcfP`'s parent document was deleted (likely via direct Firestore/Console access, not the app's cascade-delete flow, since Firestore never cascades subcollection deletes automatically) between Phase 1C Checkpoint 1 and Checkpoint 2, leaving its `private/sensitive` subdocument orphaned with no parent. Inert — blocks nothing — but should be cleaned up (a one-off `delete()` call once someone has a spare moment; not worth a dedicated script for a single document). Acknowledged by product owner as a data-hygiene issue, not a migration failure.

0c. **Non-blocking — cascade delete can leave an unreferenced Storage image behind.** (2026-07-08 Storage authorization investigation) `MaintenanceListServices.deleteDevice`'s cascade deletes each device image by its stored download URL (`FirebaseStorageServices.deleteFileByUrl`), read from the device document's `imagesBeforeReceiving`/`imagesAfterDelivery` fields — it no longer lists the device's Storage folder, because a staff-only `list` on `maintenance_devices/{deviceId}` cannot be authorized (cross-service `firestore.get()`, needed to check `isStaff()`, does not resolve during `list`-operation rule evaluation — see `DECISIONS_LOG.md`). Consequence: if an upload ever partially fails in a way that leaves a blob in Storage without its URL being saved to the document, that blob is not discoverable by the client and would survive the device's deletion. Low likelihood, low impact (storage cost only, no data exposure), but worth a periodic cleanup mechanism (e.g., a scheduled Cloud Function comparing Storage objects under `maintenance_devices/` against referenced URLs) if it's ever observed happening in practice.

0d. **Verify/tighten customer `phoneNumber` updates.** (2026-07-08, alongside the `users/{userId}` `allow create` phone-verification tightening — see `firestore.rules` and `DECISIONS_LOG.md`) The new `create` rule requires `request.resource.data.phoneNumber == request.auth.token.phone_number`, closing the spoofing gap at account-creation time. The `update` rule was deliberately left untouched in that change (kept narrowly scoped to `create` only) — it currently allows a customer to change their own `phoneNumber` field on later profile edits without re-verifying it against their Auth-verified phone. Since device-linking (`functions/index.js`'s `linkDevicesToNewCustomer`, and staff-side `NewDeviceServices.getUserIdByPhoneNumber`) trusts this field, an unverified post-creation change could reintroduce the same misattribution risk the `create` tightening closes. Needs a decision: deny changing `phoneNumber` on `update` entirely (mirroring how `type` is already locked), or require the same `== request.auth.token.phone_number` check there too.

## Security / data integrity (treat as highest scrutiny per RULES.md)

**Superseded by the 2026-07-03 Security & Data Architecture Audit** (`SECURITY_AUDIT.md`, `PERMISSIONS_MATRIX.md`, `FIREBASE_COST_REVIEW.md`) — items below are retained for history; see those documents for the full current picture.

1. **Confirm whether Firestore/Storage security rules exist.** *(confirmed still absent as of the audit; escalated — see items 1a-1d below)*
   Fact: no rules files exist anywhere in this repository. Unknown: whether rules exist in the Firebase Console for project `technostore-v2` and what they enforce.
   Why it matters: if role-based access (`UserData.type`) is enforced only in Dart UI code, any authenticated user could potentially read/write any document directly. This should be resolved before any further work that touches auth, roles, or maintenance data.

1a. **CRITICAL — Make `UserData.type` immutable from client writes.** (`SECURITY_AUDIT.md` §5a) Any authenticated user can currently self-promote to Admin by writing directly to their own `users/{uid}` document, since nothing validates the `type` field server-side. This is the highest-severity item in the backlog.

1b. **CRITICAL — Resolve the sensitive-field data architecture problem.** (`SECURITY_AUDIT.md` §6, `PERMISSIONS_MATRIX.md`) `pin`, `patternLock`, and `notesHidden` share a Firestore document with customer-visible fields (`status`, `price`). Firestore rules cannot grant differential field-level read access within one document — this requires a schema change (e.g., split into a staff-only subcollection) or a backend redaction layer, decided before rules are written for `maintenanceDevices`.

1c. **HIGH — Add route-level authorization.** (`SECURITY_AUDIT.md` §4, §5b) `AppRouter.onGenerateRoute` performs no role checks at all; every route is reachable by anyone who can call `Navigator.pushNamed` with its name.

1d. **HIGH — Fix Guest-role client logic.** (`SECURITY_AUDIT.md` §5c) Every `type != 1` check (main screen device stream, add-device FAB, PIN/pattern-lock/notes visibility) treats `GuestAccount` (`9`) as staff. This is a client-code defect independent of any future rules and needs product-owner input on what a Guest account is actually meant to see, first (see `NEXT_STEPS.md`).

1e. **MEDIUM — Verify the composite index for the live customer device-list query.** (`FIREBASE_COST_REVIEW.md` §3) `streamMaintenanceDevices(uid)` — the path every Customer session uses today — requires a `userId` + `receivedAt` composite index. No `firestore.indexes.json` exists in-repo; this can only be confirmed against the live Firebase Console. If missing, this is a live functional bug, not just a future risk.

1f. **DECIDED, scheduled into Phase 1 — Cascade delete on device deletion.** (`FIREBASE_COST_REVIEW.md` §2, product-owner decision 2026-07-03) `MaintenanceListServices.deleteDevice` must be rewritten to delete the device's Storage images, the new `private/sensitive` subdocument (introduced by ADR-001), and the parent Firestore document, with confirmation UX and idempotent retry handling. No longer just a candidate item — see `PHASE1_IMPLEMENTATION_PLAN.md` §3 "Cascade deletion behavior" for the implementation plan. **Permission scope decided:** all staff (Admin, Reception, Maintenance) can trigger this, not Admin-only.

1h. **Future, deferred — Admin user-management feature.** (`ADR-004-admin-user-management-design.md`) Browse/filter users by role, activate/deactivate, potential role changes. Confirmed not required for Phase 1 security (current manual Console-based activation is unaffected by Phase 1's rules). Requires Cloud Functions infrastructure — natural to sequence alongside `ADR-002` Phase 2.

1i. **Future, deferred — Audit logging and soft-delete for device deletion.** (`PHASE1_IMPLEMENTATION_PLAN.md`, product-owner decision 2026-07-03) Proposed alongside the cascade-delete decision as compensating controls for delete now being staff-wide rather than Admin-only, but explicitly not part of Phase 1. Would extend the `auditLogs` concept already proposed in `ADR-004` to cover device deletions, and/or replace hard-delete with a flagged soft-delete + scheduled cleanup job.

1g. **LOW/MEDIUM — Add pagination/limits to `streamMaintenanceDevices` for non-Customer roles.** (`FIREBASE_COST_REVIEW.md` §1) Currently unbounded and unfiltered for 4 of 5 roles; cost scales with both collection size and concurrent staff sessions.

2. **Implement `UserData.type` as an explicit, named role model in code.**
   Fact: currently untyped `int`, compared via magic numbers (`0`, `1`, `2`, `3`, `9`) in `main_drawer2.dart` and `inner_maintenance_list.dart`.
   Product-owner-confirmed mapping (2026-07-03, see `PROJECT_CONTEXT.md` and `DECISIONS_LOG.md`): `0` = Admin, `1` = CustomerAccount, `2` = ReceptionAccount, `3` = MaintenanceAccount, `9` = GuestAccount. The mapping itself is now settled; what remains is an engineering task, not a product question.
   Needs: a scoped, approved task to introduce an enum/named constants and replace the magic-number comparisons — including the `isEmployee = type != 1` edge case in `inner_maintenance_list.dart`, which currently counts `GuestAccount` as an employee (see `PROJECT_CONTEXT.md` → Roles and permissions → Facts). Should also decide whether `type` should be renamed/represented as a `UserRole` enum end-to-end or kept as an `int` with a mapping layer, given backward compatibility with existing Firestore documents storing raw ints.

3. **Define `MaintenanceDeviceModel.status` as a single, enforced vocabulary.**
   Fact: three overlapping string vocabularies currently coexist (model default `'pending'`, `DeviceStatus` constants `'In Maintenance'/'Fixed'/'Delivered'`, and lowercase-matched values in `MaintenanceListServices` including a legacy typo `'derived'`). Unknown values silently fall back to "in maintenance" on read.
   Needs: a decision on the canonical set of statuses and a migration plan for any existing Firestore documents using old values before changing read/write logic.

## Correctness (dormant defects)

4. **Resolve the `users/{uid}/devices` dormant defect.**
   Fact: `MaintenanceListServices.fetchMaintenanceDevices` and `fetchMaintenanceDevicesPaginated` query a subcollection that nothing ever writes to. `fetchMaintenanceDevices` is reachable via `MaintenanceListCubit.fetchGroupedMaintenanceDevices`, which currently has no UI call sites; `fetchMaintenanceDevicesPaginated` has no call sites at all.
   Risk if left alone: the moment someone wires either method to a UI action (e.g., pull-to-refresh), it will silently return an empty list for real users.
   Options to weigh later: point them at the correct top-level `maintenanceDevices` collection filtered by `userId` (matching what `streamMaintenanceDevices` already does correctly), or remove them if the stream-based path is the only one actually needed.
   **RESOLVED 2026-07-09** — `fetchMaintenanceDevices`, `fetchMaintenanceDevicesPaginated`, `streamMaintenanceDevices`, `MaintenanceListCubit.listenToMaintenanceDevices`/`fetchGroupedMaintenanceDevices`, and the `GroupedMaintenanceDevices` model were all removed in the maintenance-list search/filter feature's final cleanup commit. The correct-collection, `userId`-filtered query pattern this item worried about is now implemented properly in `MaintenanceListServices._deviceTabQuery`/`streamDevicesForTab`/`fetchMoreDevicesForTab` (see `SEARCH_FILTER_IMPLEMENTATION_PLAN.md`).

5. **Harden or remove `CacheServices.getUserData()`'s non-null assertions.**
   Fact: `uid!`, `isActivated!`, `type!` will throw if any are missing from `SharedPreferences`. It's called from `HomeServices.getUserData()`, guarded by a cached-uid-matches-current-uid check, which narrows but doesn't eliminate the risk (e.g., a partially-failed prior `saveUserData` write, or data cached by an older app version before a field existed).

10. **Wire up account activation enforcement (`AuthCubit._listenToActivation`).**
   Fact: this method is the only place in the app that gates access on `isActivated`, but it has no call site anywhere in the codebase — confirmed present-but-unwired at `HEAD` before the 2026-07-08 signup-regression fix, so this is pre-existing, not something Phase 1's security work broke. During that fix, its semantics were corrected (an absent `users/{uid}/meta/isActivated` document — the normal state for every account, since only a privileged operator via Console/Admin SDK creates it, per `ADR-004` — is now treated as `isActivated: false` rather than throwing) and the underlying stream was made null-safe, but wiring it into the sign-in flow was deliberately left out of that fix's scope: the product owner confirmed the activation feature itself was intentionally postponed before Phase 1 and should be designed/implemented later as its own feature, not folded into a regression fix.
   Needs: decide where in the sign-in flow to invoke `_listenToActivation` (e.g., after `AuthCubit` emits `AuthSuccess`), and confirm the intended UX. Until this is wired up, a newly-registered account is never actually blocked from using the app regardless of its activation status.

11. **Soft-update nudge.** (2026-07-09, `FORCED_UPDATE_IMPLEMENTATION_PLAN.md`) `appConfig/global`'s `version.{android,ios}.latestVersion` fields exist in the schema but nothing reads them — only `minRequiredVersion` (hard block) is implemented. Needs: UI/cubit-state logic for "a newer version exists but isn't required yet" (dismissable, non-blocking), reusing `AppUpdateService`/`AppUpdateCubit`'s existing fetch and comparison plumbing.

12. **Maintenance mode.** (2026-07-09, same document) `appConfig/global` was deliberately designed as a single, growable document specifically so a `maintenance` key could be added later without a schema change or new Firestore rule. Not started — no `maintenance` key is written or read anywhere yet.

13. **Feature flags.** (2026-07-09, same document) Same rationale and same status as item 12 — reserved as a `featureFlags` key on the same document, not started.

14. **`MaintenanceListCubit` action methods swallow service-layer exceptions instead of rethrowing.** (2026-07-09, found during the maintenance-list search/filter feature's final cleanup audit — see `SEARCH_FILTER_IMPLEMENTATION_PLAN.md`) `deleteDevice`, `updateDeviceStatus`, `updateDeviceAsFixed`, `updateFixedDeviceDetails`, and `deliverDevice` each wrap their `MaintenanceListServices` call in `try { ... } catch (e) { emit(MaintenanceListError(...)); }` with no `rethrow`. Nothing has ever listened to `MaintenanceListState` via `BlocListener`/`BlocConsumer` (confirmed via a full-codebase grep), so the `emit` itself is currently inert — but the effect on the caller is not: `inner_maintenance_list.dart`'s `_MarkAsFixedDialog`/`_DeliverDeviceDialog`/delete-confirmation dialogs each `await` these cubit calls inside their own `try { ...; showSuccessSnackbar(); } catch (_) { ... }`, expecting a thrown exception to signal failure. Because the cubit never rethrows, a failed save/delete/deliver still shows a "success" snackbar and closes the dialog — the user is told an operation succeeded when it didn't.
    Needs: add `rethrow;` after each `emit(MaintenanceListError(...))` in the five action methods (or otherwise propagate failure to the caller), then confirm the dialogs' existing `catch (_)` blocks behave correctly (dialog stays open, `_isSaving` resets) instead of relying on this being a live, currently-undetected bug. Deliberately kept out of the search/filter feature's scope at the product owner's request, to avoid expanding that feature's diff — tracked here for separate pickup.

## Consistency / maintainability

6. **Reconcile direct `FirebaseFirestore.instance` usage vs. the `FirestoreServices` abstraction.**
   Fact: `MaintenanceListServices` and `NewDeviceServices` mix both approaches within the same class. Not a bug, but reduces the value of having a central data-access layer and makes future rules/consistency changes harder to apply uniformly.

7. **Dead code cleanup candidates** (verify fully before removing anything — see RULES.md):
   - `lib/core/widgets/main_drawer.dart` — confirmed unused (only referenced in commented-out code).
   - `view_model/` leftover `ChangeNotifier` files in `home_page`, `maintenance_list`, `new_device_maintenance` — fully commented out.
   - `MaintenanceListServices.fetchMaintenanceDevicesPaginated` — confirmed zero call sites (distinct from item 4's `fetchMaintenanceDevices`, which has one unreachable call site through the cubit). **Removed 2026-07-09** as part of the maintenance-list search/filter feature's final cleanup commit — see item 4's resolution note.

## Process / tooling

8. **No automated test coverage or CI.**
   Fact: only the Flutter-generated default counter widget test exists. Any future change to critical flows (auth, device status transitions, pricing) currently relies entirely on manual verification.

9. **`docs/features/*.md` does not exist.**
   Was requested to be read during the baseline review; it isn't present. Open question (see `NEXT_STEPS.md`): should feature-level specs be authored now, and by whom (product owner input needed for intended behavior vs. engineering reverse-engineering current behavior)?
