# PHASE1_IMPLEMENTATION_PLAN.md

> - **Archived:** 2026-07-17
> - **Historical reference only.**
> - Reflects the project's state before the Phase 1 remediation work was completed. This plan's own "Status" line below (written 2026-07-03) predates execution — the work it describes was fully implemented, migrated, and deployed to production; see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md`.
> - **Must not be treated as the current source of truth.** For current information, see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` (what shipped) and `docs/ai-workflow/DECISIONS_LOG.md` (the full decision record). Retained as historical reference documentation — parts of it may be useful when planning a future migration or deployment, but it should not be treated as a current or authoritative migration procedure.

**Status:** Planning only — approved for planning by the product owner on 2026-07-03. **No code has been modified. No rules have been deployed.**
**Implements:** `ADR-001-sensitive-data-separation.md` (Option A), `ADR-002-role-management.md` (Phase 1), `ADR-003-guest-account-behavior.md` (as a side effect of ADR-002's allow-list refactor).
**Rules drafts:** `docs/ai-workflow/drafts/firestore.rules.draft` and `docs/ai-workflow/drafts/storage.rules.draft` — **both required, deployed together in the same pass** (product-owner decision, 2026-07-03).

This plan sequences the work; it does not execute it. Each numbered section below is a planning artifact for review. Per `RULES.md`, implementation begins only after this plan itself is approved.

---

## 1. Sensitive data schema separation

**New path:** `maintenanceDevices/{deviceId}/private/sensitive` — a single subdocument per device holding the three fields that must never be visible to a Customer, even the owning one: `pin`, `patternLock`, `notesHidden`.

**Removed from the parent document** (`maintenanceDevices/{deviceId}`): `pin`, `patternLock`, `notesHidden`. Everything else stays where it is.

**New model:** `MaintenanceDeviceSensitiveData` (new file, `lib/core/model/maintenance_device_sensitive_data.dart`):
```dart
class MaintenanceDeviceSensitiveData {
  final String? pin;
  final List<int>? patternLock;
  final String? notesHidden;
  // toMap / fromMap, mirroring the existing MaintenanceDeviceModel style
}
```

**Existing model change:** `MaintenanceDeviceModel` (`lib/core/model/maintenance_device_model.dart`) loses the `pin`, `patternLock`, `notesHidden` fields and their corresponding entries in the constructor, `toJson`, `fromJson`, `fromMap`, `copyWith`, `toString`, and `==`/`hashCode`.

**New path builder:** `FirestoreApiPath.maintenanceDeviceSensitiveData(deviceId) => 'maintenanceDevices/$deviceId/private/sensitive'` (`lib/core/utils/firestore_api_path.dart`).

**Write path change:** `NewDeviceServices.addNewDevice`/`updateDevice` currently write the entire model (including the three sensitive fields) via a single `setData` call. These need to become an **atomic batched write** — one write to the parent document (public fields) and one to `private/sensitive` (sensitive fields), using `FirebaseFirestore.instance.batch()` (no batch helper currently exists in `FirestoreServices` — confirmed by search; this plan proposes adding one there, or using the raw batch API directly in `NewDeviceServices`, which already holds a direct `FirebaseFirestore.instance` reference, consistent with that file's existing style). Atomicity matters here: we don't want a device to ever exist with public fields saved but sensitive fields silently missing (or vice versa) due to a partial failure.

**Read path change:** `MaintenanceListServices` gets a new method, e.g. `Future<MaintenanceDeviceSensitiveData?> fetchSensitiveData(String deviceId)`, doing a `get()` on the new subdocument. This is called **only from staff-facing UI**, never from any customer-facing code path (defense in depth — the real boundary is the Firestore rule, but the client shouldn't even attempt the read for a customer, both to avoid a confusing permission-denied surfacing in their UI and to avoid relying on the rule as the *only* safeguard).

**No change needed to `streamMaintenanceDevices`/`fetchMaintenanceDevices`**: once the three fields are removed from `MaintenanceDeviceModel`, these methods simply stop returning them — no crash risk, since the fields are already nullable and optional in the model today.

**New implication from the product-owner's deletion decision (§ "Cascade deletion behavior" below):** introducing the `private/sensitive` subcollection creates a second place that must be cleaned up when a device is deleted. Firestore does **not** cascade-delete subcollections when a parent document is deleted — this is the same class of orphaning bug already found for Storage images (`FIREBASE_COST_REVIEW.md` §2), and this plan must not reintroduce it for the new subcollection. See the dedicated cascade-deletion section below, which now covers both Storage and this new subcollection together.

## 2. Firestore rules draft (role immutability + access control)

Full draft: `docs/ai-workflow/drafts/firestore.rules.draft`. Summary of what it enforces:

- **`users/{uid}`**: readable by the owner and any staff role; `create` only by the owner and only with `type == 1` (matches the only code path that creates this document — new customer signup); `update` only by the owner, and **`type` may never change via any client write, including by Admins editing their own document.** Role changes in Phase 1 are Admin-SDK/Console only, by design (per `ADR-002`).
- **`users/{uid}/meta/isActivated`**: readable by the owner and staff; **all client writes denied**. **Confirmed by product owner (2026-07-03):** this field is currently changed manually via the Firebase Console by a privileged operator — Console edits with sufficient IAM permissions bypass Firestore security rules entirely (they don't go through the client SDK/rules evaluation path), so **this rule does not affect the current manual workflow at all.** Also verified: `AuthCubit._listenToActivation`, the only code that *reads* it via a live listener, has zero call sites anywhere in the app — dead code, unaffected either way. See "Future admin user-management feature" below for how this field would be written from a future in-app Admin action.
- **`maintenanceDevices/{deviceId}`**: staff get full read; Customers get read access only to documents where `userId` matches their own uid, **and their query must be shaped to match** (Firestore rejects list queries it can't prove are scoped to a rule condition that depends on document data). The existing customer code path (`streamMaintenanceDevices(uid)`) already filters with `.where('userId', isEqualTo: uid)`, so this is expected to already be compatible — flagged explicitly for the verification checklist rather than assumed safe. **`create`, `update`, and `delete` are all staff-wide** (Admin, Reception, Maintenance) per explicit product-owner decision (2026-07-03) — a uniform `isStaff()` check across all three write operations. This simplifies an earlier draft that had narrowed `create` to Reception-only and `delete` to Admin-only; both of those narrower drafts are now superseded. Customers and Guest are denied all three regardless.
- **`maintenanceDevices/{deviceId}/private/{doc}`**: staff-only for both read and write, **no exception for the owning customer**, matching the explicit product-owner instruction.
- **Default-deny** on everything else, written out explicitly for auditability even though Firestore denies by default.
- **Cost note:** every role check performs a `get()` on the caller's own `users/{uid}` document (since Phase 1 stores role as a plain field, not a Custom Claim). This is an accepted, deliberate cost of Phase 1 per `ADR-002` — it's billed as one extra document read per rule evaluation. Phase 2 (Custom Claims) removes this cost later; not addressed in this plan.

**Storage rules — required, bundled into the same deployment (product-owner decision, 2026-07-03):** `docs/ai-workflow/drafts/storage.rules.draft` mirrors the same role logic for `profiles_photos/` and `maintenance_devices/.../` Storage paths, and its `maintenance_devices` write rule already used `isStaff()` (covering create/update/delete uniformly in Storage's rule model), so it's already consistent with the all-staff decision above with no further change needed. This is no longer an optional supplement — it deploys in the same pass as the Firestore rules, not as a follow-up step.

**Future admin user-management feature (design proposed, NOT part of Phase 1):** the product owner has asked for a future Admin page to browse/filter users by role and activate/deactivate accounts (and potentially change roles). A full design proposal is in `ADR-004-admin-user-management-design.md`. One important consequence worth noting here: because this plan's rules make `type` and `isActivated` immutable from **any** client write — including an Admin's own — that future feature structurally **cannot** be built as direct client-side Firestore writes, even from an authenticated Admin account. It will require a trusted server-side mechanism (a Cloud Function using the Admin SDK, which bypasses rules by design) for the write side. The **read/browse/filter side, however, needs no new rules or infrastructure at all** — `isStaff()` already grants read access to the full `users` collection, including `list` queries filtered by `type`, since that check doesn't depend on which document is being read. This is elaborated in ADR-004.

**Resolved since the previous version of this plan (product-owner decisions, 2026-07-03):**
- ~~Should Customers ever be allowed to `create` their own device intake directly?~~ **Resolved: No**, and further clarified: `create` is staff-wide (Admin, Reception, Maintenance), not Reception-only as an earlier draft had it.
- ~~Should `delete` be Admin-only, or should Reception/Maintenance also be able to delete?~~ **Resolved: staff-wide** — Admin, Reception, and Maintenance can all delete, not Admin-only as an earlier draft had it.
- ~~Should editing (`update`) also be narrowed?~~ **Resolved: no narrowing** — stays staff-wide, uniform with create and delete.
- ~~Who is the intended writer of `users/{uid}/meta/isActivated`?~~ **Resolved:** the product owner, manually, via Firebase Console — confirmed unaffected by this rule (see above). Long-term direction is a future Admin panel (`ADR-004`), explicitly deferred beyond Phase 1.
- ~~Should Storage rules be bundled or deferred?~~ **Resolved: bundled**, same deployment as Firestore rules.

All permission-scope questions for `maintenanceDevices` are now resolved and uniform: **Admin, Reception, and Maintenance can create, update, and delete; Customer and Guest can do none of these.** No open questions remain in this section.

## 3. Client code changes required

| File | Change |
|---|---|
| `lib/core/model/maintenance_device_model.dart` | Remove `pin`, `patternLock`, `notesHidden` and all references in constructor/`toJson`/`fromJson`/`fromMap`/`copyWith`/`toString`/`==`/`hashCode`. |
| `lib/core/model/maintenance_device_sensitive_data.dart` (new) | New model for the three sensitive fields, with `toMap`/`fromMap`. |
| `lib/core/utils/firestore_api_path.dart` | Add `maintenanceDeviceSensitiveData(deviceId)` path builder. |
| `lib/features/new_device_maintenance/services/new_device_services.dart` | `addNewDevice`/`updateDevice`: split into an atomic batched write (parent doc + `private/sensitive` subdoc) instead of one `setData` call. |
| `lib/features/maintenance_list/services/maintenance_list_services.dart` | Add `fetchSensitiveData(deviceId)`, staff-only call sites. |
| `lib/features/maintenance_list/view/widgets/device_details_sheet.dart` | Replace direct `device.pin`/`device.patternLock`/`device.notesHidden` reads with a role-gated fetch of the new sensitive-data doc. |
| `lib/core/services/auth_services.dart` — `completeUserProfile` | **Required fix, found during this planning pass, not previously flagged:** this method currently *always* hardcodes `type: 1` when writing a user's profile, unconditionally. It's only ever called from the new-signup flow today (verified — single call site in `sign_up_form.dart`), so this happens to be safe right now. But once the `type`-immutability rule is live, if this method is ever invoked for a user whose document already exists with a different role (e.g., a future "edit profile" feature, or an edge-case retrigger), it would attempt to reset their role to `1` and get correctly rejected by the rule — surfacing as a confusing permission error rather than the real issue. **Fix:** read the existing document's `type` first (if any) and preserve it; only default to `1` when creating a brand-new document. This is a root-cause fix, not a workaround — it closes a latent bug that exists independent of the rules change (today, without rules, this same code path could silently downgrade a staff member's role to Customer if it were ever re-triggered). |
| Role allow-list refactor (ADR-002 + ADR-003) | Introduce a small helper — e.g. `lib/core/utils/user_role.dart` with named checks (`isStaffRole(int type)`, `isReceptionRole(int type)`, `isCustomerRole(int type)`, etc.) — and replace every `type != 1` deny-list check with an explicit allow-list check. Security-relevant call sites: `lib/features/main_screen/views/main_screen.dart:60` (device stream scoping), `lib/features/maintenance_list/view/inner_maintenance_list.dart` (`isEmployee`, which also flows into `device_details_sheet.dart`'s PIN/pattern/notes visibility gate). Cosmetic/lower-risk call sites (drawer item visibility in `lib/core/widgets/main_drawer2.dart`) should be updated for consistency in the same pass, but are not themselves data-access risks — they only affect which buttons render. |
| `lib/features/maintenance_list/view/inner_maintenance_list.dart` — "add device" FAB | Continues to use the **staff-wide** allow-list check (Admin, Reception, Maintenance) via the same `user_role.dart` helper introduced for the ADR-002/ADR-003 refactor — no Reception-specific narrowing, per the confirmed decision that create is staff-wide. The only functional change from today's behavior is that Guest (`type == 9`) is excluded, which was already planned as part of the ADR-003 fix, independent of this round of decisions. |
| `lib/features/maintenance_list/services/maintenance_list_services.dart` — `deleteDevice` | **New, required by the deletion-scope decision:** must be rewritten to cascade — delete the Storage images, then the `private/sensitive` subdocument, then the parent `maintenanceDevices` document. Detailed in "Cascade deletion behavior" below. |
| `lib/core/services/firebase_storage_services.dart` — new method | **New, required by the deletion-scope decision:** add a `deleteFolder(folderPath)` method that lists all items under a Storage path prefix (via `listAll()`, recursing into subfolders) and deletes each — needed because `maintenance_devices/{deviceId}/` contains two subfolders (`before_receiving/`, `after_delivery/`) and there is no native recursive-delete in Firebase Storage. Must treat a "file already gone" error as success (see idempotency note below), not a real failure. |
| Delete confirmation UI (wherever `deleteDevice` is currently triggered from, e.g. `inner_maintenance_list.dart`'s slidable/action menu) | **New, recommended given delete is now available to all staff, not just Admin:** extend or reuse the existing `CustomDialogs.showDialogConfirm` pattern (already used for logout confirmation in `main_drawer2.dart`) to require explicit confirmation before deletion, showing enough identifying detail (customer name, phone, device model) that staff can visually verify they're deleting the intended record — not just a generic "are you sure?" Detailed in "Cascade deletion behavior" below. |

**Explicitly out of scope for this phase** (per `ADR-002`): restoring `NewUserAdminSide`'s commented-out account-creation flow. That remains non-functional until Phase 2 (Custom Claims + admin-gated Cloud Function) is built — resurrecting it as a direct client-side Firestore write would reopen the exact hole this phase closes.

### Cascade deletion behavior (product-owner decision, 2026-07-03)

When a maintenance device is deleted, **both** the Firestore document **and** all related Storage images must be deleted — confirmed instruction, replacing the current behavior where `deleteDevice` only removes the Firestore document and leaves images orphaned indefinitely (`FIREBASE_COST_REVIEW.md` §2).

Combined with this phase's own schema change (§1), there are now **three** things to clean up per deletion, not two: the Storage images, the new `private/sensitive` subdocument, and the parent document itself. Recommended order and rationale:

1. **Delete Storage images first** (list everything under `maintenance_devices/{deviceId}/` via the new `deleteFolder` helper and delete it, best-effort). If this step fails partway, the leftover artifact is non-sensitive image files — a cost/hygiene issue, not a security one.
2. **Delete the `private/sensitive` subdocument.**
3. **Delete the parent `maintenanceDevices/{deviceId}` document last**, as the final, authoritative "this device record is gone" action.

This ordering is deliberate: if the operation fails partway, the worst-case leftover state is orphaned non-sensitive images (low severity, matches today's already-accepted risk), rather than an orphaned Firestore document still containing customer PII or an orphaned sensitive-data subdocument. **No silent failures**: if any step fails, the error must surface to the calling UI so staff know the deletion was incomplete and can retry or escalate, rather than the app reporting success when cleanup was only partial. This is a new operational risk introduced by adding cascade behavior (a multi-step operation has more partial-failure states than a single delete call did before) — flagged explicitly here and in the rollback/risk section below, and worth a dedicated line in the verification checklist.

**New risk from this round of decisions: delete is now staff-wide, not Admin-only.** Broadening deletion from Admin-only to all staff (Admin, Reception, Maintenance) increases the blast radius of a mistake or a compromised staff account — any of the three roles can now permanently destroy a device record, its sensitive data, and its images, with no undo path in Phase 1. The recommendations below are the compensating controls for that broadened permission, requested by the product owner alongside the decision itself:

**Confirmation UX (recommended for Phase 1, low cost, directly mitigates the broadened blast radius):**
- Require an explicit confirmation step before deletion, reusing the existing `CustomDialogs.showDialogConfirm` pattern already used elsewhere in the app (e.g., logout) rather than introducing a new dialog pattern.
- The confirmation dialog should display identifying details of the device being deleted (customer name, phone number, device model) so staff can visually verify they have the right record — a generic "are you sure?" is not enough for a destructive, cascading, cross-service operation now reachable by three roles instead of one.

**Retry handling (recommended for Phase 1, since the cascade is a new multi-step operation):**
- Each step must be individually **idempotent**. Note a real technical asymmetry here: Firestore's `.delete()` on an already-deleted document succeeds silently (no-op) — but Firebase Storage's `.delete()` on an already-deleted file **throws** an `object-not-found`-style error. The `deleteFolder` helper (and any direct file-delete calls) must explicitly catch that specific error and treat it as success, not a real failure — otherwise a retry after a partial failure would itself report a false failure on the step that actually already succeeded.
- Recommend retrying the **entire sequence** on failure rather than building logic to resume from a specific failed step — since every step is idempotent, a full retry is simple, safe, and avoids unnecessary complexity (per `RULES.md`) that granular resume-tracking would add for little benefit at this scale.
- The UI should surface a clear "deletion incomplete — retry?" state on failure rather than silently leaving staff unsure whether the action succeeded.

**Future audit logging / soft-delete consideration (explicitly proposed for a later phase, NOT Phase 1 — consistent with `ADR-004`'s "propose, don't implement unless required for security" framing, and confirmed not required for Phase 1 since hard-delete-with-cascade is what's been decided now):**
- **Audit logging:** record who deleted which device and when (acting staff uid, device id, customer identifying info, timestamp), extending the same `auditLogs` collection concept already proposed in `ADR-004` for user-management actions. Given deletion is now available to all staff rather than only Admin, an audit trail is the main way to retain accountability for this action without restricting who can perform it.
- **Soft-delete:** instead of immediately hard-deleting the Firestore document, consider marking it `isDeleted: true` (excluded from normal queries) with actual hard-deletion — including the Storage cascade — deferred to a scheduled cleanup job (Cloud Function) after a grace period. This would give a recovery window against an accidental or mistaken deletion, which matters more now that three roles can trigger it instead of one. This would require its own rules change (the primary staff action would become an `update` setting a flag, not a `delete`) and is a meaningfully bigger change than Phase 1's scope — proposed here as the natural next step if accidental-deletion incidents become a real problem in practice, not as a Phase 1 requirement.

## 4. Migration/backfill plan for existing devices

1. **Inventory (read-only, safe to run anytime):** query `maintenanceDevices` and count how many documents have a non-null `pin`, `patternLock`, or `notesHidden`, to size the migration and spot-check sample data before writing anything.
2. **Backup:** export the full `maintenanceDevices` collection (Firestore managed export to GCS, or an Admin SDK script dumping to JSON) immediately before any migration write. This is the rollback safety net — mandatory, not optional, per the rollback plan below.
3. **Migration script** (Node.js or Python using the Firebase Admin SDK, run manually by a trusted operator — **not shipped in the Flutter app**), in two passes:
   - **Pass A (copy):** for every `maintenanceDevices/{deviceId}` document with any of the three sensitive fields set, write them into the new `maintenanceDevices/{deviceId}/private/sensitive` subdocument. Support a `--dry-run` flag that logs intended writes without executing them, for the product owner/operator to review first.
   - **Verification step (between passes):** read back every newly-created `private/sensitive` subdocument and diff it against the source fields on the parent document, for every migrated device — confirm 100% match before proceeding.
   - **Pass B (strip):** only after Pass A is verified complete and correct, remove (`FieldValue.delete()`) `pin`, `patternLock`, `notesHidden` from every parent document.
4. **Sequencing with the client code deploy:** the new client code (writing to the subcollection going forward) should be live before or at the same time as Pass A runs, so no new writes land in the old location after migration starts. Pass B (the destructive strip) should only run once the new app version is confirmed live for all active staff sessions — avoiding a window where an un-updated client tries to read `pin` from the parent document and silently gets nothing.
5. **This entire migration must complete, verified, before the Firestore rules draft is deployed** — the rules assume the final schema (sensitive fields absent from the parent document, present in the subcollection). Deploying rules before migration would deny reads of sensitive fields that are still sitting in the parent document, which is actually the *safe* failure direction (staff would briefly lose access rather than customers gaining it) — but it's still the wrong order operationally and would break the staff-facing device details screen until migration catches up.

## 5. Rollback plan

- **Rules rollback:** Firebase keeps rules version history. Reverting to the prior ruleset (today: no rules at all) is a single `firebase deploy --only firestore:rules` with the previous version, or a Console "restore previous version" action — fast (seconds to minutes). This should be the first response to any unexpected production denial that can't be immediately diagnosed.
- **Schema rollback:** as long as Pass B (the destructive strip) has **not** run yet, rollback is simple and non-destructive — stop the migration, revert client code to read from the parent document again; the original fields are still there untouched. **If Pass B has already run**, rollback requires restoring `pin`/`patternLock`/`notesHidden` onto the parent documents from the Step 2 backup — this is precisely why that backup is mandatory before Pass A even begins, not an afterthought.
- **Client code rollback:** this needs to be treated as a **coordinated unit with rules and schema**, not rolled back independently. Rolling back client code alone (e.g., re-publishing a previous build) while the new rules/schema remain live would break the app for anyone still on the old build, since old code expects `pin`/`patternLock`/`notesHidden` inline on the parent document. If a rollback is needed, roll back rules first (fastest, safest, buys time), then decide on schema/client rollback deliberately rather than as an automatic cascade.
- **Role-immutability rule rollback:** if the `type`-immutability rule unexpectedly blocks a legitimate flow in production (e.g., the `completeUserProfile` edge case, if the fix above were somehow missed), prefer a **targeted rule relaxation** for the specific broken pattern over fully removing the rule — fully removing it reopens the CRITICAL self-promotion hole this phase exists to close, even temporarily. Any such relaxation should be a deliberate, reviewed decision at the time, not an automatic fallback.
- **Cascade-deletion partial failure (new risk from this round of decisions):** the new multi-step `deleteDevice` (Storage → sensitive subdoc → parent doc) can fail partway. There is no "rollback" for a partial delete in the traditional sense — the mitigation is detection and manual cleanup, not automatic reversal. If a deletion is reported as failed, staff should be able to re-run it safely (each step should be idempotent — deleting an already-deleted Storage file or document should not throw an unhandled error) rather than leaving the record in an ambiguous half-deleted state with no recovery path.

## 6. Manual verification checklist

No automated test suite exists in this repository (per `RULES.md`/`PROJECT_CONTEXT.md`), so this checklist is the primary safety net. Recommend running the first block against the Firestore Emulator Suite before touching production, and the second block against production (or a staging project, if one exists — **unknown, needs confirmation**) immediately after deploy.

**Pre-deploy (emulator, seeded with a test account for each role, including a manually-seeded `type: 9` account):**
- [ ] Customer can read only their own `maintenanceDevices` documents; a customer's filtered query (matching current code) succeeds; an unfiltered/broad query attempt is denied.
- [ ] Customer's read of `maintenanceDevices/{id}/private/sensitive` is denied, including for their own device.
- [ ] Staff (Admin/Reception/Maintenance) can read the full unfiltered `maintenanceDevices` collection and the `private/sensitive` subdocument.
- [ ] The seeded `type: 9` (Guest) account is denied read access to `maintenanceDevices` and `private/sensitive` entirely.
- [ ] No role — including Admin acting on their own document — can write a different `type` value to any `users/{uid}` document via a client-style request.
- [ ] New user profile creation (`type: 1`, own uid) still succeeds.
- [ ] A staff account's profile-completion path (if exercised in the emulator) does not attempt to overwrite its own `type` back to `1`.
- [ ] **Admin, Reception, and Maintenance** can all `create`, `update`, and `delete` `maintenanceDevices` documents; **Customer and the seeded Guest account can do none of the three** — confirm all combinations, not just Customer-cannot-create.

**Post-deploy (production or staging, real accounts per role if possible):**
- [ ] Customer: device list still loads with no permission-denied error (validates query-shape compatibility called out in §2).
- [ ] Customer: no PIN/pattern lock/notes visible or fetchable anywhere in the UI, for any device, including their own.
- [ ] Reception/Maintenance/Admin: full device list still loads; PIN/pattern/notes still visible in the device details screen.
- [ ] Direct attempt (via a script or REST call using a customer's real ID token, not through the app UI) to write `type: 0` to that customer's own `users/{uid}` — confirm `PERMISSION_DENIED`.
- [ ] Direct attempt to read a customer's own device's `private/sensitive` subdocument using their ID token — confirm `PERMISSION_DENIED`.
- [ ] Creating a new device intake (staff flow) succeeds end-to-end; confirm in the Firebase Console that both the parent document and the `private/sensitive` subdocument were created.
- [ ] Updating an existing device (status change, marking fixed, delivery) still succeeds for staff roles.
- [ ] A brand-new customer signup + profile completion still succeeds end-to-end.
- [ ] Spot-check a sample of migrated devices in the Console: `private/sensitive` matches the pre-migration backup values, and the parent document no longer contains the three fields.
- [ ] No unexpected spike in Firestore read volume/cost immediately after rollout beyond the expected per-request `get()` cost noted in §2 (sanity check against `FIREBASE_COST_REVIEW.md`).
- [ ] Confirm `AuthCubit._listenToActivation` (currently dead code — zero call sites) remains inert and doesn't unexpectedly start erroring; if it's ever wired up later, retest this specifically given `meta/isActivated` is now write-denied for all clients.
- [ ] **In the app UI**, confirm the "add device" FAB appears for Admin, Reception, and Maintenance test accounts, and does not appear for Customer or Guest accounts.
- [ ] **Cascade deletion**, tested from each staff role (Admin, Reception, and Maintenance — not just one): delete a test device and confirm, in the Firebase Console/Storage browser, that (a) the parent `maintenanceDevices` document is gone, (b) the `private/sensitive` subdocument is gone, and (c) all files under `maintenance_devices/{deviceId}/` in Storage are gone — check all three, not just the Firestore document.
- [ ] **Delete confirmation dialog:** confirm it appears before any deletion completes, and displays the correct device's identifying details (customer name, phone, model).
- [ ] **Cascade deletion idempotency:** attempt to delete an already-deleted device (or re-run the delete action after simulating a partial failure) and confirm it fails gracefully / is safely re-runnable rather than throwing an unhandled error; specifically confirm a missing Storage file during retry is treated as success, not a fatal error.
- [ ] Confirm the product owner's existing manual Console-based activation/deactivation workflow still works exactly as before after rules deploy (toggle `isActivated` for a test account via Console, confirm the app's behavior responds as expected).

## 7. Deployment order

Consolidating the sequencing implied across §1–§6 into one end-to-end order, now that Storage rules are confirmed bundled with Firestore rules:

1. Implement and ship the `AuthServices.completeUserProfile` type-preservation fix (§3) — independent, low-risk, no dependency on anything else below.
2. Implement the sensitive-data schema split client code (§1) and the cascade-delete client code (§3/"Cascade deletion behavior") — ship together, since both touch `NewDeviceServices`/`MaintenanceListServices` and both must be live before their respective backend changes (migration, rules) land.
3. Implement the role allow-list refactor (§3) — resolves the Guest exposure (ADR-003) as a side effect.
4. Run the migration script's Pass A (copy sensitive fields into `private/sensitive`) once the new client code from step 2 is live for all active staff sessions, then verify, per §4.
5. Run the migration script's Pass B (strip sensitive fields from the parent document) only after Pass A is verified.
6. Validate the full rules draft (Firestore + Storage together) against the Firestore Emulator Suite using the pre-deploy checklist in §6.
7. Deploy **Firestore rules and Storage rules together, in the same pass** (product-owner decision) — not staggered.
8. Run the post-deploy verification checklist (§6) immediately against production.

Rules (step 7) must come **after** the schema migration (steps 4–5) completes and is verified — deploying rules first would deny staff reads of sensitive fields still sitting in the old location, breaking the device details screen until migration catches up (noted already in §4).

## 8. Rollback order

If something goes wrong after deployment, in order of what to try first:

1. **Revert Firestore + Storage rules together** (they were deployed together; revert them together too, back to the pre-Phase-1 state of no rules) — fastest, buys time to diagnose without re-exposing anything worse than the pre-Phase-1 baseline that's been running until now.
2. **Assess schema migration state.** If Pass B (the destructive strip) has not run yet, schema rollback is simple — stop, revert client code, original fields are untouched. If Pass B has already run, restore `pin`/`patternLock`/`notesHidden` from the mandatory pre-migration backup (§4) — this is not optional cleanup, it's the only path back.
3. **Decide on client code rollback deliberately**, not automatically — rolling back client code alone while schema/rules have moved on would break the app for anyone already updated. Roll back rules first (step 1) to buy time before deciding this.
4. **Cascade-deletion issues specifically** have no traditional rollback — see §5's partial-failure handling (idempotent retries, no silent failures) rather than treating this as a revertible step.

## What this plan does not cover (explicitly deferred)

- ADR-002 Phase 2 (Custom Claims, admin Cloud Function, rebuilt `NewUserAdminSide`) — separate future plan.
- **The future Admin user-management feature** (browse/filter users by role, activate/deactivate, potential role changes) — the product owner explicitly asked for this to be proposed but not built in Phase 1. Design proposal: `ADR-004-admin-user-management-design.md`. Confirmed not required for Phase 1 security, since the current manual Console-based activation process is unaffected by this phase's rules (see §2).
- Field-level write validation on `maintenanceDevices` (status enum, price bounds) — a data-integrity backlog item, not part of Phase 1's access-control scope.
- Audit logging and soft-delete for device deletion — proposed above as future considerations, not built in Phase 1.
- The dormant `users/{uid}/devices` subcollection and `status` vocabulary inconsistency (existing `BACKLOG.md` items) — should be resolved before or alongside this work per `SECURITY_AUDIT.md` §9's recommended sequencing, but are independent decisions not bundled into this plan unless the product owner wants them combined.
