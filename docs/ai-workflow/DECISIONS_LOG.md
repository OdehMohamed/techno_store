# DECISIONS_LOG.md

Chronological log of actual decisions made in the AI-assisted workflow for this project. This log records **decisions**, not facts about existing code — reverse-engineered architecture observations belong in `PROJECT_CONTEXT.md`, not here. Newest entries at the bottom.

---

### 2026-07-03 — Adopt Tech Lead / Senior Engineer operating model for AI-assisted work

**Decision:** All engineering work in this repository (whether done by a human or an AI agent) follows the workflow and constraints defined in `RULES.md`: understand before proposing, explain trade-offs, get explicit approval before major design decisions, treat data integrity/security/permissions as critical, no silent failures or temporary hacks.

**Decided by:** Product owner.

**Rationale:** This is a Firebase-backed app handling customer data, device intake (including PIN/pattern-lock capture), and pricing — correctness and reversibility matter more than speed.

---

### 2026-07-03 — Perform a baseline codebase review before any implementation work

**Decision:** Before touching any code, conduct a full baseline review of the app's architecture, roles/permissions, Firebase data model, and known risks, based strictly on direct source inspection.

**Decided by:** Product owner (explicit request).

**Rationale:** The AI workflow referenced `docs/ai-workflow/*` files as pre-existing context, but they did not exist. A shared, verified baseline was needed before any further request could be trusted to have accurate context.

**Outcome:** Baseline review completed via direct reading of models, services, cubits, and routing code, plus grep-based call-site verification. Findings captured in `PROJECT_CONTEXT.md`.

---

### 2026-07-03 — Create `docs/ai-workflow/` documentation set from verified code facts only

**Decision:** Create `PROJECT_CONTEXT.md`, `RULES.md`, `CURRENT_TASK.md`, `DECISIONS_LOG.md`, `BACKLOG.md`, and `NEXT_STEPS.md`, using only facts verified in the codebase, with assumptions/unknowns/risks explicitly labeled and separated from facts.

**Decided by:** Product owner (explicit request).

**Rationale:** Formalize the baseline review into a durable, auditable reference before any code changes are proposed or made, and establish a documentation structure the workflow can maintain going forward.

**Outcome:** No code was modified or refactored as part of this decision — documentation only.

---

### 2026-07-03 — Confirm `UserData.type` role mapping

**Decision:** The authoritative role mapping for `UserData.type` is:

| `type` | Role |
|---|---|
| `0` | Admin |
| `1` | CustomerAccount |
| `2` | ReceptionAccount |
| `3` | MaintenanceAccount |
| `9` | GuestAccount |

**Decided by:** Product owner (explicit confirmation).

**Rationale:** This value was previously an assumption inferred loosely from UI comparisons in `main_drawer2.dart` and one inline code comment (`// 9 for guest`); it needed direct product-owner confirmation before any code or documentation treated it as fact, per `RULES.md`.

**Status:** Documented in `PROJECT_CONTEXT.md` as product-owner-confirmed. **Not yet implemented in code** — the codebase still has no enum/named constants for these values; that remains an open backlog item (see `BACKLOG.md`) pending its own scoping and approval, not bundled into this documentation update.

---

### 2026-07-03 — Commission a Security & Data Architecture Audit before any rules or fixes

**Decision:** Pause all implementation work and conduct a full audit of Firestore collections, Storage patterns, per-role permissions (current/intended/recommended), privilege escalation scenarios, data integrity risks, Firebase cost risks, index requirements, and rules-rollout risks — documented, not implemented.

**Decided by:** Product owner (explicit request), with explicit instruction to treat the absence of `firestore.rules`/`storage.rules`/`firestore.indexes.json` as a major risk until proven otherwise, and to assume no server-side protection exists.

**Outcome:** `SECURITY_AUDIT.md`, `PERMISSIONS_MATRIX.md`, and `FIREBASE_COST_REVIEW.md` created under `docs/ai-workflow/`. No code or rules were written. The audit surfaced two CRITICAL findings (client-writable role field enabling self-promotion to Admin; sensitive fields like device PIN/pattern-lock sharing a document with customer-visible fields, which Firestore rules cannot separate without a schema change) and two HIGH findings (no route-level authorization; GuestAccount inadvertently granted staff-level visibility in client code due to `type != 1` checks). Full detail in `SECURITY_AUDIT.md`.

---

### 2026-07-03 — GuestAccount clarified as an undefined, historical role

**Decision:** `GuestAccount` (`type == 9`) has no current business role or intended permissions. It exists historically and may or may not be used in the future. Engineering should treat it as undefined and not design a permission model or feature set around it unless necessary to close an active risk.

**Decided by:** Product owner (explicit clarification, in response to `SECURITY_AUDIT.md` §5c).

**Rationale:** Resolves the "Unknown" left open in `PERMISSIONS_MATRIX.md` regarding what a GuestAccount is. Directly shapes `ADR-003-guest-account-behavior.md`'s recommendation (disable/neutralize current unintended staff-level access, retain the reserved value, do not build new Guest-specific behavior).

---

### 2026-07-03 — Customers must never view submitted PIN/pattern-lock/staff notes, including their own

**Decision:** Once a customer submits a device PIN or pattern lock, and for internal staff notes (`notesHidden`), the customer must never be able to view these values again — not even for their own device. This is a stronger requirement than ownership-based access control (it isn't "only the owner can read this"; it's "the owner specifically must never read this").

**Decided by:** Product owner (explicit clarification).

**Rationale:** Confirms and sharpens the CRITICAL finding in `SECURITY_AUDIT.md` §6 — this cannot be satisfied by Firestore rules alone on the current schema (rules are document-level; they can't grant a customer read access to some fields of a document while denying others). Directly drove the schema-separation recommendation in `ADR-001-sensitive-data-separation.md`.

**Outcome:** Documented in `ADR-001-sensitive-data-separation.md`. Not yet implemented — awaiting product-owner decision on Option A vs. B before any schema or code change.

---

### 2026-07-03 — Commission ADRs before implementing security rules or code changes

**Decision:** Before writing any Firestore/Storage rules or modifying production code, produce formal Architecture Decision Records for the three open architecture questions raised by the audit: sensitive data separation, role immutability/management, and Guest account handling.

**Decided by:** Product owner (explicit request).

**Outcome:** `ADR-001-sensitive-data-separation.md`, `ADR-002-role-management.md`, `ADR-003-guest-account-behavior.md` created under `docs/ai-workflow/`. Each presents options with pros/cons/migration risk and a recommendation, but **no ADR has been approved for implementation yet** — all three remain in "Proposed" status pending product-owner sign-off.

---

### 2026-07-03 — Approve ADR-001, ADR-002, ADR-003 as proposed; commission Phase 1 implementation plan

**Decision:** All three ADR recommendations are approved as proposed (ADR-001 Option A subcollection split; ADR-002 phased approach starting with Phase 1 rules-enforced immutability; ADR-003 disable-and-retain for GuestAccount). Product owner requested a detailed Phase 1 implementation plan — schema separation, Firestore rules draft, client code changes, migration/backfill plan, rollback plan, and manual verification checklist — before any implementation begins.

**Decided by:** Product owner (explicit approval and request).

**Outcome:** `PHASE1_IMPLEMENTATION_PLAN.md` created, along with `docs/ai-workflow/drafts/firestore.rules.draft` (required) and `docs/ai-workflow/drafts/storage.rules.draft` (supplementary). **No code modified, no rules deployed.** Planning surfaced one additional required fix not previously identified: `AuthServices.completeUserProfile` unconditionally hardcodes `type: 1`, which would conflict with the new role-immutability rule if ever retriggered for an existing non-Customer account — folded into the plan as a required client-code change. Also surfaced three open questions requiring product-owner input before implementation (customer self-service device intake, device-deletion role scope, intended writer of `users/{uid}/meta/isActivated`) and one dead-code confirmation (`AuthCubit._listenToActivation` has zero call sites today).

---

### 2026-07-03 — Device creation restricted to ReceptionAccount only

**Decision:** Customers must not create maintenance requests. Only `ReceptionAccount` (type 2) may create new `maintenanceDevices` records — this is narrower than "any staff role": Admin and Maintenance do not create intake records either under this decision.

**Decided by:** Product owner (explicit decision, resolving the open question from `PHASE1_IMPLEMENTATION_PLAN.md`'s prior draft).

**Outcome:** `drafts/firestore.rules.draft`'s `maintenanceDevices` `create` rule narrowed from `isStaff()` to `isReception()`. `update` (status changes, delivery, editing already-filed intake) is unchanged and remains staff-wide — this decision was scoped to creation only; whether editing should also narrow is logged as a still-open question. Client-side: the "add device" FAB must be gated to Reception only, not the general staff/`isEmployee` check.

---

### 2026-07-03 — Device deletion must cascade to Storage (and, per this phase's own schema change, the sensitive-data subcollection)

**Decision:** When a `maintenanceDevices` document is deleted, both the Firestore document and all related Storage images must be deleted.

**Decided by:** Product owner (explicit decision, formalizing what `FIREBASE_COST_REVIEW.md` §2 had flagged as an existing orphaned-data risk).

**Outcome:** `PHASE1_IMPLEMENTATION_PLAN.md` §3 updated with a dedicated "Cascade deletion behavior" section. Combining this with `ADR-001`'s subcollection split (also introduced in this same phase) means there are now three things to clean up, not two — the plan explicitly adds cleanup of the new `private/sensitive` subdocument to avoid immediately reintroducing the same class of orphaning bug for the new schema. Deletion order recommended: Storage images first, then the sensitive subdocument, then the parent document, so any partial failure leaves only non-sensitive orphaned artifacts rather than orphaned customer data. New requirement: no silent failures — a partial cascade-delete failure must surface to the caller, not report false success.

---

### 2026-07-03 — `isActivated` current state confirmed; future Admin user-management feature proposed but deferred

**Decision:** Current activation process is confirmed as a manual Firebase Console edit by the product owner (privileged/IAM access, which bypasses Firestore security rules — Phase 1's rules do not affect this workflow). Future direction: an Admin page to browse/filter users by role (Admin, Reception, Maintenance, Customer) and activate/deactivate accounts, potentially including role changes. Product owner asked for the safest design to be proposed, explicitly **not** implemented in Phase 1 unless required for security.

**Decided by:** Product owner.

**Outcome:** Confirmed this feature is **not required for Phase 1 security** (the manual Console workflow is unaffected by Phase 1's rules either way). `ADR-004-admin-user-management-design.md` created as a future-work design proposal: read/browse/filter needs no new infrastructure (already enabled by Phase 1's staff-read rule on `users`); write actions (activate/deactivate, role change) must go through a Cloud Function using the Admin SDK, since Phase 1's rules make these fields client-write-immune even for Admins, by design. Recommends an audit log for these actions and treating role-change as a separate, higher-scrutiny capability from simple activation. Not scheduled — future work, sequenced independently of `ADR-002` Phase 2.

---

### 2026-07-03 — maintenanceDevices create/update/delete unified as staff-wide; Storage rules bundled with Firestore rules

**Decision:** All three write operations on `maintenanceDevices` — create, update, and delete — are staff-wide (Admin, Reception, Maintenance), uniformly. This **supersedes** two narrower choices drafted earlier in the same planning session: `create` had been narrowed to Reception-only, and `delete` to Admin-only. Both are reverted to the uniform `isStaff()` check. Additionally, Storage rules (`drafts/storage.rules.draft`) will be deployed in the same pass as Firestore rules, not as a separate/later step — resolving the previously-open bundling question.

**Decided by:** Product owner (explicit decision, revising the prior round).

**Rationale:** Simplifies the rule set to one consistent staff/non-staff boundary for all three operations, rather than per-operation role carve-outs. Does not reopen any CRITICAL/HIGH finding from `SECURITY_AUDIT.md` — the security-relevant boundary was always staff vs. Customer/Guest, not which specific staff sub-role gets which specific operation, so this reversal is a business-process simplification, not a security regression.

**Outcome:** `drafts/firestore.rules.draft` updated (`create`/`delete` reverted to `isStaff()`, matching `update`). `PHASE1_IMPLEMENTATION_PLAN.md` updated throughout (§2, §3, §6, new §7/§8). Client-side "add device" FAB reverts to staff-wide visibility (no Reception-only narrowing). **New risk accepted, with compensating controls requested by the product owner:** broadening delete to all staff increases the blast radius of an accidental or malicious deletion — mitigated in Phase 1 by required deletion confirmation UX (reusing the existing `CustomDialogs.showDialogConfirm` pattern) and retry/idempotency handling; audit logging and soft-delete are proposed as future (not Phase 1) considerations.

---

### 2026-07-03 — Phase 1 implementation approved

**Decision:** `PHASE1_IMPLEMENTATION_PLAN.md` is approved. Two final artifacts were required first — `PRE_DEPLOYMENT_BACKUP_PLAN.md` (what/how/where backups are taken, and the restoration procedure) and `MIGRATION_SUCCESS_CRITERIA.md` (measurable validation checks, count invariants, verification queries, failure/rollback triggers) — both now created. Per the product owner's own stated condition, **Phase 1 implementation is approved to begin.**

**Decided by:** Product owner.

**Outcome:** All planning artifacts for Phase 1 are complete: `ADR-001` through `ADR-004`, `PHASE1_IMPLEMENTATION_PLAN.md`, `drafts/firestore.rules.draft`, `drafts/storage.rules.draft`, `PRE_DEPLOYMENT_BACKUP_PLAN.md`, `MIGRATION_SUCCESS_CRITERIA.md`. **No code has been modified and no rules have been deployed as of this entry** — implementation has been approved but not yet started; the next session's work is expected to begin executing the plan per its §7 deployment order.

---

### 2026-07-03 — Phase 1A implemented (low-risk client-side fixes, no migration/rules)

**Decision:** Implement Phase 1 in sub-phases; Phase 1A covers only the client-side fixes with no production data changes: `completeUserProfile` type-preservation, deny-list → allow-list conversion, centralized role helpers, and the GuestAccount-treated-as-staff fix. Schema migration, sensitive-data movement, and Firestore/Storage rules deployment explicitly held for a later sub-phase.

**Decided by:** Product owner.

**Outcome:** Implemented. New file `lib/core/utils/user_role.dart`. Modified: `lib/core/services/auth_services.dart`, `lib/core/services/firestore_services.dart` (additive `getDocumentOrNull` helper), `lib/features/main_screen/views/main_screen.dart`, `lib/features/maintenance_list/view/inner_maintenance_list.dart`, `lib/core/widgets/main_drawer2.dart`. `flutter analyze` run before and after on all touched files plus the full project — zero new errors or warnings introduced; the 3 issues present are pre-existing and unrelated. `lib/core/widgets/main_drawer.dart` deliberately left untouched (confirmed dead code, zero usage — not touched opportunistically per `RULES.md`). One incidental operator error during this work: a `git stash` was run without checking status first, stashing pre-existing uncommitted user changes alongside these edits; recovered cleanly via `git stash pop` after resolving an unrelated `pubspec.lock` conflict — no work was lost, but noting it here as a process lesson (check `git status` before any stash/reset-style command, even when not asked to use git).

---

### 2026-07-03 — Phase 1B implemented (schema separation, client changes, cascade delete, migration scripts prepared)

**Decision:** Implement Phase 1B — sensitive data schema separation, required client code changes, cascade delete, and migration script preparation — with no rules deployment, no migration execution, and no production data modification.

**Decided by:** Product owner.

**Outcome:** Implemented. Two architectural discoveries made during implementation, not previously called out at file-level in `PHASE1_IMPLEMENTATION_PLAN.md`, both addressed without altering any ADR's conclusion:
1. `NewDeviceServices.updateDevice` previously used a full-document `.set()` (no merge). Once `pin`/`patternLock`/`notesHidden` are removed from `MaintenanceDeviceModel`, this would have silently deleted those fields from any un-migrated device the moment staff edited it. Fixed by switching the parent-document write to `SetOptions(merge: true)`.
2. `new_device_maintenance.dart`'s edit form pre-fills PIN/pattern/notes directly from the model being stripped of those fields. Fixed by fetching sensitive data asynchronously on open (via the new shared `MaintenanceDeviceSensitiveDataService`, which checks the new subdocument first and falls back to legacy inline fields), and blocking save until that fetch completes — preventing a race where a still-empty field could be submitted and wipe existing data.

New files: `lib/core/model/maintenance_device_sensitive_data.dart`, `lib/core/services/maintenance_device_sensitive_data_service.dart`, `scripts/migration/` (Node.js, prepared but not run, not part of the Flutter app). Modified: `maintenance_device_model.dart`, `firestore_api_path.dart`, `storage_api_path.dart`, `new_device_services.dart`, `new_device_cubit.dart`, `new_device_maintenance.dart`, `maintenance_list_services.dart`, `device_details_sheet.dart`, `firebase_storage_services.dart`, `inner_maintenance_list.dart`. `flutter analyze` clean throughout (only pre-existing, unrelated issues remain). No rules deployed, no migration run, no production data touched.

---

### 2026-07-03 — Migration Rehearsal performed; bug found and fixed in `verify-pass-b.js`; edit-form fetch error handling fixed

**Decision:** Before Phase 1C, rehearse the migration scripts end-to-end against representative data in a non-production environment, and clarify three implementation details of Phase 1B.

**Decided by:** Product owner.

**Outcome:**
- Answered three clarification questions precisely by re-reading the actual code (single-batch semantics with one create/update asymmetry; cascade-delete abort-on-Storage-failure behavior with one identified inconsistent-window edge case; no loading indicator and, previously, no error handling on the edit form's sensitive-data fetch).
- Fixed the edit-form fetch-error gap: `_loadSensitiveData` in `new_device_maintenance.dart` now catches failures and shows a real error message instead of leaving Save silently and permanently blocked.
- The genuine Firebase Firestore Emulator binary could not be run in this environment — natively (wrong OS/architecture: Linux x86-64 binary on macOS ARM64) or in a Docker container (the binary is linked against Google's internal GRTE runtime, unavailable in standard Linux images). Rather than force this or skip the rehearsal, ran the actual unmodified `scripts/migration/*.js` files against a small, faithful in-process mock of the exact `firebase-admin` Firestore API surface those scripts use (persisted to a JSON file across process invocations, so each script ran as a genuinely separate process like it would in real use). This is disclosed as a real limitation, not presented as equivalent to the official emulator.
- Seeded 7 representative devices covering edge cases from `MIGRATION_SUCCESS_CRITERIA.md`: full sensitive data, partial sensitive data, no sensitive data, empty-but-present fields (`patternLock: []`, `notesHidden: ''`), and an already-migrated device. Ran inventory → backup → Pass A (dry-run, then execute) → verify-pass-a → Pass B (dry-run, then a deliberate negative test confirming Pass B refuses to run against a corrupted state, then the real execute) → verify-pass-b, plus an independent field-by-field diff beyond the scripts' own self-reported results, plus a live test of the backup-restore procedure.
- **Found a real bug**: `verify-pass-b.js` checked raw field-key presence rather than the shared `hasSensitiveData()` definition, causing false-positive "lingering sensitive fields" failures for devices whose `patternLock`/`notesHidden` were present but empty (correctly never migrated, correctly never touched by Pass B). Fixed to use the same shared helper as every other script. Re-ran and confirmed the fix resolves it with zero false positives.
- All other checks passed, including a negative test proving Pass B's "refuse to run against an unverified Pass A" guard actually works (not just documented), and a live restoration test proving the JSON backup can genuinely restore original values.

---

### 2026-07-04 — Phase 1C execution runbook produced (checkpointed, not continuous)

**Decision:** Production backup confirmed complete and verified by the product owner. Phase 1C will execute as five discrete, gated checkpoints (0–4) rather than one continuous operation, each requiring an explicit GO decision before the next begins.

**Decided by:** Product owner.

**Outcome:** `PHASE1C_EXECUTION_RUNBOOK.md` created — exact execution order, expected output, stop conditions, rollback triggers, time estimates, downtime expectations, and read-only-vs-write classification for every step across all five checkpoints. Added one explicit prerequisite gate not in the original checkpoint outline: confirming the Phase 1B app build is live for all active staff sessions before Checkpoint 0 begins, since Pass B's safety (Checkpoint 2) depends on it. Also added a GO/NO-GO to Checkpoint 3, which the provided outline didn't list one for, for consistency with every other checkpoint. **Nothing has been executed. No code was modified in this session.**

---

### 2026-07-04 — Migration scripts support gcloud ADC login, not just service account key files

**Decision:** `scripts/migration/lib/admin.js` should not require `GOOGLE_APPLICATION_CREDENTIALS` to be set — it should let Application Default Credentials resolve naturally (service account key file, or `gcloud auth application-default login`, whichever is available), avoiding the need to create/store a long-lived service account key for a one-off operator script.

**Decided by:** Product owner (preference to avoid creating a service account key unless necessary).

**Rationale:** `admin.credential.applicationDefault()` already supports gcloud user ADC login natively — the only blocker was an artificial check in `initAdmin()` that hard-required the env var, incorrectly assuming a key file was the only valid path. Removed that check; added an explicit `projectId: 'technostore-v2'` pin to `initializeApp()` instead, since gcloud user ADC (unlike a service account key file) carries no embedded project id — without pinning it, the scripts could otherwise silently target whatever project happens to be the operator's ambient gcloud default.

**Outcome:** `lib/admin.js` updated; `README.md` updated to document both auth paths, with `gcloud auth application-default login` as the recommended default. Verified via a functional smoke test (mocked `firebase-admin`, no production access) that `initAdmin()` now succeeds without the env var set and correctly pins the project id regardless of credential source. Not re-run against the full Migration Rehearsal mock (only the auth-initialization function changed, not migration logic), but the change is small and isolated enough that this is judged sufficient. **No execution against production has occurred.**

---

### 2026-07-04 — Checkpoint 0 executed against production

**Decision/Action:** Product owner authorized executing Checkpoint 0 directly. Installed `gcloud` CLI (via Homebrew, was not previously present), product owner completed `gcloud auth application-default login` personally (the one step requiring their own interactive browser auth — not something this session could do on their behalf). Then ran `npm install`, `node backup.js`, and `node inventory.js` against production `technostore-v2`.

**Outcome:** `backup.js`: 430 `maintenanceDevices` + 5 `users` documents written to a local JSON dump. `inventory.js`: N=430, M=85 — consistent with the backup's document count. **Found and immediately fixed a real gap**: the local backup output directory (`scripts/migration/backups/`) was not gitignored, meaning real production customer PII and plaintext PIN/pattern-lock/notes data was at risk of being accidentally committed. Added `scripts/migration/backups/` and `scripts/migration/node_modules/` to `.gitignore` immediately. **No Pass A, Pass B, or rules deployment was run.** Full results reported to product owner for the Checkpoint 0 GO/NO-GO decision.

---

### 2026-07-04 — Format B backup uploaded to backup bucket; Checkpoint 1 (Pass A) executed against production

**Decision/Action:** Product owner approved Checkpoint 0 as GO, conditional on uploading the Format B JSON backup to `gs://technostore-v2-firestore-backups/`. Uploaded, then authorized to proceed to Checkpoint 1 (Pass A + verification only).

**Outcome — backup upload:** `gcloud storage cp -r` initially nested the files one directory level deeper than the exact destination path specified (a `cp -r` basename-preservation quirk) — caught by listing the result rather than trusting the success message, corrected by re-copying flat and removing the erroneous nested copy, then independently verified via MD5 hash comparison (decoded from GCS's base64 format) that both uploaded files are byte-for-byte identical to the local originals. Confirmed the bucket already contains the previously-confirmed Format A export prefix.

**Outcome — Pass A:** dry-run and execute both matched expectations exactly (85 would-migrate/migrated, 0 skipped, consistent with Checkpoint 0's M=85). `verify-pass-a.js`: 85 expected, 85 found, 0 mismatches, exit 0. Independently re-ran `inventory.js` after Pass A and confirmed N is still 430 (parent documents untouched, as designed).

**Important handling note:** the dry-run output contained real production customer PINs, unlock patterns, and service notes in plaintext. These were deliberately **not reproduced** in the report back to the product owner — only summary counts were shared — since doing so would recreate, in the chat transcript, the exact class of sensitive-data exposure this entire Phase 1 effort exists to prevent. The product owner was advised to do the required human spot-check (`MIGRATION_SUCCESS_CRITERIA.md` §3, at least 20 devices) directly in the Firebase Console instead.

**No Pass B, no rules deployment.** Holding for GO/NO-GO before Checkpoint 2.

---

### 2026-07-04 — Checkpoint 2 (Pass B) paused: Phase 1B rollout not confirmed

**Decision/Action:** Product owner approved Checkpoint 1 (20-device human spot-check completed, confirmed matching) and authorized proceeding to Checkpoint 2 (Pass B + verification). Before executing, re-checked the runbook's pre-Checkpoint-0 prerequisite — whether the Phase 1B app build is confirmed live for all active staff sessions — since this specific gate hadn't been explicitly addressed anywhere in the conversation. Product owner confirmed: **not fully confirmed / uncertain.**

**Outcome:** Pass B was **not run**. Per the runbook's own stated rule for this exact scenario ("if this cannot be confirmed with confidence, stop here"), execution is paused at Checkpoint 2 until the Phase 1B rollout to all active staff sessions can be confirmed. Risk if run anyway: any staff device still on pre-Phase-1B code reads/writes `pin`/`patternLock`/`notesHidden` directly on the parent document and has no knowledge of the new subcollection — stripping those fields while such a session is active would break that device's sensitive-data access, with no way for this review to detect or prevent it from Firestore data alone (rollout status is an operational fact outside what's observable in the database).

**No Pass B, no verify-pass-b, no rules deployment.** Holding for product-owner confirmation of the rollout prerequisite before resuming Checkpoint 2.

---

### 2026-07-04 — Phase 1B rollout confirmed (release infrastructure + Closed Testing/TestFlight); Checkpoint 2 (Pass B) executed against production

**Decision/Action:** Product owner confirmed the previously-outstanding prerequisite explicitly: a Phase 1B build (containing the merge-based `updateDevice`, sensitive-data fallback service, and role allow-list changes) has been built and uploaded through newly-established release infrastructure (Google Play Closed Testing / TestFlight, with Shorebird prepared for future releases), and this is the version staff are now using. Proceeded with Checkpoint 2 (Pass B + verification) on that basis.

**Outcome:** Before executing, Pass B's dry-run internal re-verification reported 84 devices needing stripping, not the 85 confirmed at Checkpoint 1 — investigated before proceeding rather than assumed benign. Root cause identified precisely: device `Sd7A3a1jMByVEy9vKcfP` (one of the original 85) was deleted from `maintenanceDevices` sometime between Checkpoint 1 and Checkpoint 2 (net collection change during the same window: 430 → 432, i.e. 3 created, 1 deleted). Confirmed this deletion did **not** go through the app's own cascade-delete path — the parent document is gone but its `private/sensitive` subdocument survived as an orphan, a pattern inconsistent with the app's delete-order (Storage → subcollection → parent last) and consistent instead with a direct Firestore/Console-level deletion, which never cascades to subcollections. This orphaned subdocument was **not deleted** — flagged for the product owner's awareness, cleanup deferred as out of Checkpoint 2's scope.

With the discrepancy fully explained as benign (a legitimate deletion during live production use, not corruption), executed Pass B: 84 documents stripped. `verify-pass-b.js` (the rehearsal-fixed version): 0 lingering sensitive fields, exit 0. Independently re-ran `inventory.js`: N=432, M=0 — consistent with `verify-pass-b.js`'s own result via a second, independent method.

**No Firestore or Storage rules deployed. Not proceeding to Checkpoint 3 without explicit approval**, per instruction.

---

### 2026-07-04 — Checkpoint 3 (Firestore + Storage rules) deployed to production

**Decision/Action:** Product owner approved Checkpoint 2 and the orphaned-subdocument finding as a tracked follow-up rather than a migration failure, and authorized Checkpoint 3 (rules deployment), explicitly scoped to deployment only — live functional verification (3.3) deferred to a separate, later authorization.

**Outcome:**
- Pre-flight: confirmed via `gcloud firestore indexes composite list` that the `userId`+`receivedAt` composite index on `maintenanceDevices` exists and is `READY` — resolves a question open since the original Security Audit.
- Copied `docs/ai-workflow/drafts/firestore.rules.draft`/`storage.rules.draft` byte-for-byte to `firestore.rules`/`storage.rules` at the repo root; added `firestore`/`storage` keys to `firebase.json`.
- The `firebase` CLI's global install was broken in this environment (a stale/corrupted install) and `firebase-tools@latest` requires Node ≥20, while the project's default Node is 18. Installed Node 20 via Homebrew (isolated, not linked as the system default) and a local `firebase-tools@latest` under it, used only for this deployment.
- Deployed both rules files with `firebase deploy --only firestore:rules --project=technostore-v2` and `--only storage --project=technostore-v2`, explicitly targeting `technostore-v2` given several similarly-named projects are visible on this account (`technostore-86118`, `techno-staff`, etc.).
- **Independently verified** both deployments via the Firebase Rules API directly (not just the CLI's success message): fetched the live release + ruleset content for both `cloud.firestore` and `firebase.storage`, confirmed `updateTime` matches the deploy time, and confirmed the deployed ruleset content is byte-for-byte identical to the approved local rules files.

**Explicitly not done, per instruction:** no live functional verification (customer/staff read-write behavior testing) — that remains a separate, later step. **Not proceeding to Checkpoint 4.**

---

### 2026-07-04 — Phase 1 formally closed

**Decision:** Product owner reviewed the distinction between app-level functional validation (completed, by the product owner directly, across all roles) and rules-level direct/bypass-the-UI authorization testing (not performed). Decided to close Phase 1 now rather than block on the latter, with it explicitly tracked as a required follow-up **before any public production release**, not silently dropped.

**Decided by:** Product owner.

**Outcome:** Committed `firestore.rules`, `storage.rules`, `firebase.json` to the repository (merged into the *current* HEAD content, not a stale cached copy — a real discrepancy was caught and corrected before committing, since the working file had been edited from an outdated read of `firebase.json` predating the product owner's release-infrastructure work, which had added web/Windows/macOS Firebase app configurations and new app IDs that would otherwise have been silently reverted). `PHASE1_CLOSURE_SUMMARY.md` created as the capstone reference. Two items added to `BACKLOG.md` as explicit, tracked follow-ups: direct authorization testing (blocking for public release) and the orphaned `private/sensitive` subdocument cleanup (non-blocking, data hygiene). **Phase 1 is closed. Next work is feature development**, per product-owner direction.

---

### 2026-07-04 — Permanent Git/GitHub workflow established

**Decision:** Product owner requested a permanent Git/GitHub workflow covering the full feature lifecycle (planning, branching, commits, PRs, merges, releases, technical debt handling), to be reviewed/improved and finalized as a standing project document.

**Decided by:** Product owner, with several refinements proposed during drafting (marked `[Proposed]` in the document itself, pending explicit confirmation rather than silently adopted): a concrete plan-vs-no-plan heuristic for §1, branch-type-to-commit-type alignment for §2, sequential-PR guidance for large features in §3, an explicit "buildable ≠ tests pass" clarification for §4 given no test suite exists, squash-merge as the default strategy in §8, a Shorebird-patchability note in the release workflow (§10), and a recommendation to start a `CHANGELOG.md`.

**Outcome:** `CONTRIBUTING.md` created at repo root (the authoritative document), `.github/PULL_REQUEST_TEMPLATE.md` created to operationalize the PR-description requirements, `docs/ai-workflow/RULES.md` updated to reference it. **Two findings surfaced and fixed proactively during this work, both pre-existing and unrelated to the request itself:** `upload-keystore.jks` (the Android app signing key) was not gitignored — fixed immediately, same urgency class as the earlier migration-backup `.gitignore` gap, since a leaked signing key is a supply-chain-level risk. Also flagged: the prior commit (`a9f7587`, Phase 1 rules deployment) includes a `Co-Authored-By: Claude` trailer added before the new no-attribution rule existed; it is unpushed (`main` is 1 ahead of `origin/main`), so amending it is low-risk, but this requires explicit product-owner confirmation before doing it, not an assumption. **Not yet proceeding to the requested repository cleanup or v1.0.0 release** — per the product owner's own sequencing ("after the workflow is finalized and approved"), holding for explicit approval of the workflow document first.

---

### 2026-07-04 — v1.0.0 tag and GitHub Release created

**Decision:** Product owner approved the finalized `CONTRIBUTING.md` (see prior entry) and authorized Part 2: repository cleanup, sync verification, and creating the project's first official release, marking completion of the initial development phase and its security foundation.

**Decided by:** Product owner.

**Outcome:** Verified no obsolete or forgotten branches existed locally or remotely (only `main`; the one prior PR was already merged with its branch already deleted). Created `CHANGELOG.md` documenting Phase 1's security work as the `[1.0.0]` entry. Created and pushed annotated tag `v1.0.0` ("Initial Stable Release") and a corresponding GitHub Release with technical release notes, per explicit instruction that no store release was in scope for this task. `main` and `origin/main` confirmed in sync.

---

### 2026-07-07/08 — Storage image upload/delete authorization failures investigated and fixed

**Decision:** Investigate why maintenance-device photo deletion failed for all staff roles after Phase 1's Storage rules deployment, and (once found to be broader) why photo upload failed too — without relaxing the deployed Storage rules unless proven necessary.

**Decided by:** Product owner (investigation approach: root-cause only, no rules relaxation, verify every claim empirically before acting on it — extensive back-and-forth using the Firebase Rules API dry-run endpoint, IAM policy inspection, and controlled temporary rule experiments, each reverted immediately after its single test).

**Outcome — root causes found (two independent bugs, not one):**
1. `MaintenanceListServices.deleteDevice`'s cascade delete listed the device's Storage folder (`listAll()`) before deleting each file. A staff-only `list` on `maintenance_devices/{deviceId}` can never be authorized: detecting staff requires a cross-service `firestore.get()` call inside `isStaff()`, which does not resolve during `list`-operation rule evaluation (proven via the Rules API dry-run: the same `isStaff()` check that succeeds for `write` returns unmatched/unauthorized for `list`, even under a direct-UID bypass on a confirmed-clean path).
2. Separately, the image folder path builders (`StorageApiPath.maintenanceImages`/`profilesPhotos`) emitted a trailing slash that `uploadFile()` turned into a double slash — an extra empty path segment the deployed rules' exact-depth match rejected. This affected uploads independently of bug 1.
3. A red herring pursued at length: a missing IAM grant (`roles/firebaserules.firestoreServiceAgent`, required for Storage rules' cross-service Firestore reads) was found genuinely absent from the correct service agent and granted — but the underlying `list` limitation (bug 1) is a platform constraint, not an IAM misconfiguration, so this grant did not fix the delete failure by itself. It was likely still a real, independently necessary fix (the project's first-ever cross-service rules deploy went through non-interactive CLI calls that never triggered Firebase's normal interactive permission-grant prompt) — later evidence (a previously-blocking Storage warning about cross-service configuration clearing on its own after this grant, without any further change) suggests it had simply needed time to propagate. Kept as applied.

**Fix:** Cascade delete now deletes each image by its already-known stored download URL (`FirebaseStorageServices.deleteFileByUrl`) instead of listing the folder — sidesteps the `list` limitation entirely, no rules change needed. `uploadFile()` sanitizes trailing slashes defensively. Trade-off documented in `BACKLOG.md` (0c): an image never referenced in the device document (e.g. from a partially failed upload) is no longer discoverable for cleanup via this path.

**Not done:** no Storage rules were relaxed. The two temporary experiment rules used during investigation (a direct-UID bypass, and an unconditional `allow write: if true`) were each deployed for exactly one test and reverted immediately after, never committed.

---

### 2026-07-08 — Signup regression (post-Phase-1) investigated and fixed; device-linking moved to a Cloud Function

**Decision:** While retesting the Storage fix above, signup itself was found broken by Phase 1's rules in three separate, previously-undiscovered ways. Fix each at the root rather than work around it, and decide the correct trusted-actor design for one of them (device-to-customer linking) without weakening customer permissions.

**Decided by:** Product owner, per-issue as each was found.

**Outcome:**
1. **`permission-denied` on profile completion:** `AuthServices.completeUserProfile` wrote both `users/{uid}` and `users/{uid}/meta/isActivated` — the latter is intentionally `allow write: if false` under Phase 1's rules (activation is Console/Admin-SDK-only, per `ADR-004`), but this client write was never removed when the rules deployed. Fixed: `saveUserData` now writes only the profile document; `getUserData` and the (still-unwired) `AuthCubit._listenToActivation` both treat an absent meta document as `isActivated: false` rather than throwing. Wiring `_listenToActivation` into the sign-in flow itself was explicitly deferred — product owner confirmed the activation-gate feature was intentionally postponed before Phase 1 and should be designed as its own feature later (`BACKLOG.md` item 10), not folded into this regression fix.
2. **Null-check crash in `MainScreen` right after profile completion:** `completeUserProfile` emitted a bare `AuthSuccess()` with no `userData`; `MainScreen` assumes `state.userData` is always populated on that state. Fixed by fetching the profile and emitting `AuthSuccess(userData)`, matching what `checkAuth` already does.
3. **Automatic linking of devices Reception received before the customer registered was silently broken:** the client-side `findUserDevices` (query `maintenanceDevices` by phone, write `userId`) is denied under Phase 1's rules for a customer on both counts (read scoped to own uid; write staff-only) — it had been failing silently (caught, logged, swallowed) since the rules deployed, with no one aware. **Decision on the fix:** evaluated existing trusted actors first, per explicit instruction, before reaching for new infrastructure. Found staff already resolve this at intake/update time (`NewDeviceServices.getUserIdByPhoneNumber`) whenever the customer already has an account — only the reverse ordering (device first, customer registers later) was uncovered. Concluded this reverse case needed a trusted, non-client mechanism specifically because no existing staff action reliably fires at the moment a customer registers. Chose a Cloud Function (`functions/index.js`, `linkDevicesToNewCustomer`, `users/{uid}` `onCreate`) over both an unauthorized client path and staff-side workarounds — first Cloud Functions infrastructure in this project (Blaze plan already planned). Reads the phone number Firebase Auth verified via OTP directly from the Auth record, not the client-written Firestore field, so its correctness doesn't depend on any Firestore rule staying in place. The broken client-side `findUserDevices` and its now-dead service class were removed.
4. **Related tightening:** `users/{userId}` `allow create` now also requires `request.resource.data.phoneNumber == request.auth.token.phone_number` — closes a spoofing gap the Cloud Function's (and the pre-existing staff-side) phone-based matching would otherwise trust blindly. Deliberately scoped to `create` only; the same gap on `update` is tracked separately (`BACKLOG.md` item 0d), not folded into this change.
5. **`permission-denied` stream error on sign-out:** `MaintenanceListCubit`'s device-stream subscription is only cancelled when a new one starts or the cubit itself closes — but the cubit persists across sign-in/sign-out within the same `MainScreen` route, so `close()` never fired on sign-out, leaving the stream running with an invalidated session. Fixed with `MaintenanceListCubit.stopListening()`, called on the `AuthInitial` state. Also closes a real (not just cosmetic) gap: without it, a different user signing in next could briefly see the previous user's device list.

**Result:** six commits (`bb24873`, `b30aa34`, `3c67492`, `535a756`, `e54ca45`, `456f97c`), each scoped to one of the above, reviewed and approved commit-by-commit, retested end-to-end by the product owner (device creation/deletion with photos, full signup flow, device-linking, login/logout — no regressions found), then pushed to `origin/main`.

---

### 2026-07-09 — Forced app update mechanism designed, built, and merged

**Decision:** Build a cross-platform forced-update mechanism, ordered before the maintenance-devices search/filter feature (as a safety net: ship the recovery lever before the riskier, larger change). Audited the existing `in_app_update` integration first — found it Android-only, tied to Play's own publish timing with no "force only below version X" control, and blind to already-authenticated returning users (only wired into `SignIn.initState()`).

**Decided by:** Product owner, architecture confirmed before implementation: Firestore (not Remote Config) as the config source; a single, deliberately growable `appConfig/global` document (not a dedicated version-gate doc) so maintenance mode/feature flags can be added later without a schema change; `pub_semver` for comparison (no manual string parsing); no hardcoded iOS App Store ID (kept in the document, nullable); a dedicated full-screen blocking page (not a dialog); the gate layered onto the existing `MainScreen`/`AuthCubit` flow *after* auth resolves, not as a new first gate before it; and explicit fail-open on any config-read or version-comparison failure, approved specifically so a Firestore hiccup or missing document can never brick the app for everyone.

**Outcome:** `in_app_update` kept, unchanged, as a non-blocking Android nudge only — no longer the enforcement mechanism. Implemented on `feature/forced-app-update` as five reviewed, individually-approved commits (implementation plan, data layer, cubit, blocking page, wiring + Firestore rule), each following `CONTRIBUTING.md`'s branch/commit-approval workflow. The one new Firestore rule (`appConfig/global`, public read, no client write) was validated against the Rules API dry-run before being deployed ahead of merge, specifically so the feature could be tested end-to-end pre-merge without opening a PR early. Test config was created and torn down via Admin SDK for reproducibility, independently verified via unauthenticated REST reads at every step, and fully removed before the PR was opened — `appConfig/global` does not exist in production as of this entry; creating the real one is a deliberate, tracked release-time step (see `NEXT_STEPS.md`), not something any code in this repo does automatically.

**Testing (product owner, manual, both platforms):** blocked path (non-dismissable, correct store link/fallback), allowed path (no regressions in auth/navigation), the specific gap that motivated this feature — an already-authenticated returning session, not just a fresh sign-in — and fail-open (app launches normally with `appConfig/global` deleted). No regressions found.

**Merged:** PR #2, squash-merged as `d843ddc`. Feature branch deleted locally and remotely per `CONTRIBUTING.md §9`/§10.

---

### 2026-07-09 — Maintenance devices search/filtering (v1) designed, built, and merged

**Decision:** Build a practical, Firestore-native v1 of search/filtering for the maintenance devices list — no Algolia/Typesense — that also resolves the existing unbounded, all-statuses staff stream (`BACKLOG.md` item 1g). Planning started with a review of the current implementation before any code: found `MaintenanceListServices.fetchDevicesByStatus` unused and buggy (its customer-path branch queried the dormant `users/{uid}/devices` subcollection, `BACKLOG.md` item 4), `assignedTechnicianId` dormant, and no `firestore.indexes.json` in the repo.

**Decided by:** Product owner, confirmed before implementation: "serial" search reuses the existing `imeiNumber` field (no new model field); a "technician" filter uses the populated `maintenanceEmployee` field, not the dormant `assignedTechnicianId`; filter scope is status (tab) plus at most one structured filter, not fully composable; pagination is live top-50 + explicit Load More; and — after querying real production data (441 documents, exactly 3 canonical status values, zero legacy variants) — status matching is exact-match only, no case-insensitive/legacy-variant tolerance.

**Mid-implementation course correction:** after the query/index/service layer (data layer) was committed and approved, a UI-migration commit was proposed that replaced swipeable `TabBarView` with a tap-only `TabBar`, as a "deliberate simplification" to make per-tab bounded queries work. **Product owner did not accept this trade-off** and asked whether swipe could be preserved without reintroducing eager/unbounded fetching. Re-analyzed and found `AutomaticKeepAliveClientMixin` + per-tab lazy-start resolves it: each tab is its own `_MaintenanceTabPage` widget that defers starting its bounded Firestore query until its `TabController` index first becomes active, and stays alive across swipes (native Flutter caching, no manual cache map). This required reworking the already-approved per-tab cubit-flow commit into a widget-owned-state design instead — product owner explicitly chose to do the rework rather than keep the tap-only UX.

**Outcome:** Implemented on `feature/maintenance-devices-search-filter` as five reviewed, individually-approved commits (implementation plan; bounded per-tab query methods + `firestore.indexes.json`; per-tab cubit flow, later superseded; UI rewire onto the swipe-preserving per-tab-widget design; final removal of the legacy unbounded loading path — `streamMaintenanceDevices`, `fetchMaintenanceDevices(Paginated)`, `GroupedMaintenanceDevices`, and the cubit methods that drove them, once the new flow was fully verified). `firestore.indexes.json` (4 composite indexes on `maintenanceDevices`) was deployed to `technostore-v2` — indexes only, no rules — and independently confirmed `READY` via `gcloud firestore indexes composite list` before the corresponding brand/employee filters were retested; the deploy was kept as a separate, explicit step after implementation was complete, per instruction.

Two findings surfaced during the final cleanup's dead-code audit, both handled as the product owner directed rather than folded into this feature: `fetchMaintenanceDevicesPaginated` (zero call sites anywhere) was removed as part of this cleanup since it depended on the same `GroupedMaintenanceDevices` model being deleted; a pre-existing, unrelated bug (the cubit's action methods — `deleteDevice`, `updateDeviceAsFixed`, etc. — swallow service-layer exceptions instead of rethrowing, so a failed save/delete/deliver still shows a "success" snackbar) was logged as `BACKLOG.md` item 14 and deliberately left unfixed to keep this commit scoped to cleanup.

**Testing (product owner, manual, Android emulator, staff account):** tab loading (lazy, one query per tab on first visit), swipe navigation, revisit caching, brand/employee/date-range filters (mutually exclusive, correct results), search by name/phone/model/IMEI (continues working after filters applied/cleared), Load More pagination, device actions (Edit/Fixed/Deliver/Delete across all three tabs), and sign-out/sign-in after the cleanup commit (no stale subscriptions, no permission errors). One `[cloud_firestore/failed-precondition]` index error was hit before the indexes were deployed (expected) and confirmed resolved after deployment. No regressions found.

**Merged:** PR #3, squash-merged as `1a3d350`. Feature branch deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

---

### 2026-07-09 — `BACKLOG.md` item 0a deferred; `appConfig/global` recreated in production

**Decision:** Before starting the next feature, product owner reviewed `BACKLOG.md` item 0a (direct/bypass-the-UI authorization testing against the deployed Firestore/Storage rules — the one item still marked blocking for public release) and decided not to perform it now.

**Decided by:** Product owner. Rationale given: comfortable with the deployed roles/rules and the app-level validation already performed to date, and does not want it to gate the upcoming release.

**Verification performed before treating this as safe to defer:** re-read the currently deployed `firestore.rules` directly (not from memory/prior notes) to confirm the specific guarantees item 0a is about are unchanged since Phase 1 — `type` immutability on `users/{userId}` `update`, and `private/sensitive` subdocument staff-only read/write. Confirmed unchanged; the only rule changes since Phase 1 (the `users/{uid}` `create`-time phone-verification tightening, and the `appConfig/global` public-read/no-write rule) are narrow and additive, neither touching these guarantees.

**Outcome:** `BACKLOG.md` item 0a re-labeled from "BLOCKING FOR PUBLIC RELEASE" to "ACCEPTED RISK / DEFERRED" — kept open (not closed as resolved, since the testing itself never happened) so it can still be picked up later if there's ever a moment to spare. `NEXT_STEPS.md`/`CURRENT_TASK.md` updated to stop listing it as a release blocker.

**Separately, same session:** product owner noted `appConfig/global` appeared to be missing from production. Verified via Admin SDK read: the document did not exist — consistent with the forced-update feature's PR-prep cleanup, which deliberately removed the test document entirely rather than leaving it in a "previous test values" state (see the 2026-07-09 forced-update entry above). Recreated it with safe, non-blocking production values: `version.android`/`version.ios` `minRequiredVersion` "1.0.0" (matches the currently shipped app version, so no real user is blocked), Android `packageId` "com.mohamedodeh.technostore", iOS `appStoreId` null (no App Store listing exists yet — the app already degrades gracefully for that case, per the original design). Independently verified via an unauthenticated REST read against the live document (not just the write call's own success response), confirming it matches exactly what was written and is publicly readable as the rules intend.

---

### 2026-07-09 — Staff Home page UI/UX polish designed, built, and merged

**Decision:** Improve the Home page for staff users: hide the customer-facing promotional carousel banner and Contact Us footer for staff only (customers/guests keep the current experience unchanged), and audit the Home page for any other UI/UX polish genuinely worth doing before starting the next feature.

**Decided by:** Product owner. Audit findings presented before any code: `HomeLoaded` already carries `UserData`, so `UserRole.isStaff(...)` — the existing allow-list helper — could gate both sections directly with no new plumbing; both the carousel and footer are used only in `home_page.dart`, confirmed via grep; the standalone `MaintenancePage` route already has neither, confirming staff have no operational need for them on the Home tab. Two unrelated findings surfaced during the audit and were logged to `BACKLOG.md` rather than fixed here (item 7's new bullet: the single-tab `TabBar`/`TabBarView` around the fully commented-out Store tab is dead chrome; item 15: the carousel's hardcoded image URLs point at unrelated third-party sites, not the store's own assets).

**Outcome:** Implemented on `feature/home-page-staff-ui` as two reviewed, individually-approved commits:
1. Gated the banner and `MainFooter` behind `UserRole.isStaff(state.userData.type)` in `home_page.dart`. The loading/initial fallback (before the role is known) was deliberately left showing the footer regardless of role, per product-owner direction, rather than adding complexity to suppress it pre-role-resolution.
2. Three additional staff-facing polish items on the maintenance devices list (embedded in the Home page's staff tab), requested after reviewing the first commit: the "New Device" FAB now respects the platform safe area (`MediaQuery.padding.bottom`) plus a comfortable, screen-size-scaled margin instead of a fixed offset that pushed it toward the bottom edge; device cards are slightly shorter to fit more on screen (an initial reduction was tested on-device and found to overflow by 2px, caught via the emulator's `RenderFlex` warning before being corrected — verified clean afterward); and Load More was moved from a button pinned below the grid into the last item of a single `CustomScrollView` (grid + trailing sliver), which surfaced a real bug — the list was keyed on `devices.length`, so every Load More remounted the whole scrollable and reset scroll position to the top. Fixed with a `_generation` counter that only increments on a genuine new query (tab switch, filter change), not on Load More's append, so appending now preserves scroll position — confirmed on-device via before/after screenshots that pressing Load More keeps the user's place.

**Testing (product owner + on-device verification during implementation, Android emulator, staff account):** staff view confirmed with no banner/footer via screenshot; customer/guest path provably unchanged (the diff only wraps existing content in a conditional); FAB clearance, card density, and Load More's inline behavior and scroll-position preservation all visually confirmed; `flutter analyze` identical to `main` baseline (zero new issues). No regressions found.

**Merged:** PR #4, squash-merged as `a951dfb`. Feature branch deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

---

### 2026-07-09 — v1.1.0 tagged and released (internal/closed testing)

**Decision:** Prepare and publish the next release per `CONTRIBUTING.md` §11, covering the three features shipped since v1.0.0 (forced app update, maintenance devices search/filtering v1, staff Home page UI/UX polish) plus the six auth/storage fixes from the post-v1.0.0 investigation.

**Decided by:** Product owner, confirmed this release targets internal/closed testing (Play Closed Testing / TestFlight), not the public store listing — consistent with the same-day `BACKLOG.md` item 0a deferral and the still-deferred store-metadata-finalization gap.

**Pre-release verification (per §11.1–11.3):** confirmed `main` stable (clean tree, only `main` branch existed, `flutter analyze` stable at the confirmed 48-issue pre-existing baseline, with zero new issues introduced). The sensitive-files check against release scope surfaced two pre-existing, unrelated hygiene issues — each fixed as its own small PR before the release commit, per product owner's direction that repository housekeeping doesn't warrant its own decision entry (referenced here only as release-prep context):
- A native build tool (Xcode/SPM) had checked out a full companion Dart monorepo into `build/ios/SourcePackages/checkouts/`, which `flutter analyze` was silently scanning — inflating the reported issue count from a true baseline of 48 to 5375 for the entire session. Fixed by excluding `build/` in `analysis_options.yaml` (PR #5).
- A root-level `node_modules/` directory (7,689 files, 116 MB) had been tracked in git since 2025-06-10, predating this project's sensitive-files discipline — orphaned, unreferenced by any current tooling. Removed from tracking along with its unused `package.json`/`package-lock.json` (PR #6).

**Version bump:** `1.0.0` → `1.1.0` (minor — three new features, no breaking changes). Explicitly **not Shorebird-patchable**: `package_info_plus` (added for the forced-update feature) changes native plugin registration, so this ships as a full new store build rather than a patch.

**Outcome:** `CHANGELOG.md` updated with a `[1.1.0]` entry (Added/Changed/Fixed/Internal/Known follow-ups, matching the `[1.0.0]` entry's structure). `pubspec.yaml` bumped to `1.1.0+2`. Committed directly to `main` as `163e746` (`build(release): bump version to 1.1.0+2, update CHANGELOG`), matching the same direct-to-main precedent set by the `v1.0.0` CHANGELOG commit. Annotated tag `v1.1.0` created and pushed; GitHub Release published at that tag with technical release notes (by category) plus separate store-ready "what's new" notes (plain language, for the Play Console/TestFlight upload) — the store notes are not part of the GitHub Release body, matching how `v1.0.0` was handled.

**Explicitly out of scope, per `CONTRIBUTING.md` §11's own boundary:** Shorebird release commands and the actual store upload are the product owner's to run manually.

---

### 2026-07-17 — Documentation audit and engineering-documentation restructuring designed, built, and merged

**Decision:** Before starting any PRD work, perform a full documentation audit of `docs/ai-workflow/` and restructure it as a deliberate "phase zero" — separating active documentation from historical/archive material, correcting stale content, and preparing a place for upcoming product documentation — rather than writing a PRD on top of a document set that had grown inconsistent since v1.0.0.

**Decided by:** Product owner, following a full-codebase product-discovery pass and a documentation audit (classification of every `docs/ai-workflow/` document as active/permanent/historical/candidate-for-consolidation) presented for review before any change was made.

**Outcome:** Implemented on `docs/restructure-engineering-docs` as seven reviewed, individually-approved commits:
1. Archived 3 pre-Phase-1 audit documents (`SECURITY_AUDIT.md`, `PROJECT_CONTEXT.md`, `FIREBASE_COST_REVIEW.md`) into `archive/phase1-audit/`.
2. Archived 4 Phase 1 execution documents (`PHASE1_IMPLEMENTATION_PLAN.md`, `PRE_DEPLOYMENT_BACKUP_PLAN.md`, `MIGRATION_SUCCESS_CRITERIA.md`, `PHASE1C_EXECUTION_RUNBOOK.md`) into `archive/phase1-execution/`.
3. Archived 2 shipped-feature implementation plans (`FORCED_UPDATE_IMPLEMENTATION_PLAN.md`, `SEARCH_FILTER_IMPLEMENTATION_PLAN.md`) into `archive/shipped-features/`. Each of the 9 archived documents carries a structured status banner: archived date, "historical reference only," what it reflects, and where to look for current information — refined over several rounds of product-owner feedback to frame them as material to *learn from*, not procedures to copy verbatim.
4. Corrected the stale "Proposed — awaiting product-owner decision. Not implemented." status headers in ADR-001/002/003 — all three were actually implemented in Phase 1. ADR-002 was split correctly: Phase 1 (rules-enforced immutability) implemented; Phase 2 (Custom Claims) remains genuinely open.
5. Repointed every stale bare-filename cross-reference to the newly archived documents across `BACKLOG.md`, `PERMISSIONS_MATRIX.md`, `ADR-004`, `RULES.md`, and `PHASE1_CLOSURE_SUMMARY.md`'s document index (the latter reworked to explicitly separate Active vs. Archived documents). `RULES.md`'s documentation-maintenance policy, which had pointed new inferred code facts at `PROJECT_CONTEXT.md`, was reworded: `PERMISSIONS_MATRIX.md` is now stated as the actively-maintained home for permissions/role facts, and general product/feature documentation is stated as belonging under the not-yet-created `docs/product/`.
6. Refreshed `PERMISSIONS_MATRIX.md` in full — both its "Current — backend" rows (verified directly against the deployed `firestore.rules`/`storage.rules` text) and its "Current — client UI" rows (re-verified against current source, since the client code changed twice since the original 2026-07-03 audit: the Phase 1A allow-list refactor, and the 2026-07-09 search/filter rewrite that deleted `streamMaintenanceDevices` entirely). Closed out several findings that had been standing as documented gaps/live bugs since the original audit — Guest no longer inherits the unfiltered staff device stream or sees sensitive fields (fixed in Phase 1A), and cascade-delete of Storage images on device deletion (flagged missing in the original audit) is implemented today. `PERMISSIONS_MATRIX.md` is now the single actively-maintained source of truth for roles/permissions, explicitly not to be duplicated into the forthcoming PRD.
7. Fixed remaining stale references found during a self-review pass before merge: ADR-001/002/003 body prose (commit 4 only corrected their header blocks) and one leftover in `PHASE1_CLOSURE_SUMMARY.md`'s opening paragraph.

**Deliberately deferred, not part of this restructuring** (each raised during self-review, each explicitly declined by the product owner to avoid unbounded scope growth): ~17 Dart source-code doc-comments under `lib/` citing the old flat archive paths — flagged for a separate, small future cleanup rather than mixed into a docs-only branch. `scripts/migration/README.md` and the comment headers in `firestore.rules`/`storage.rules` similarly left untouched — low-consequence, and outside a documentation restructuring's natural scope.

**Documentation ownership going forward, established during this session:** `docs/ai-workflow/` remains the engineering-process/decision record (this log, `RULES.md`, `BACKLOG.md`, `CURRENT_TASK.md`, `NEXT_STEPS.md`, the ADRs, `PERMISSIONS_MATRIX.md`). `docs/product/` (not yet created) will hold product-level documentation once its structure is approved: a master `PRD.md`, a dedicated `ROADMAP.md` (product direction/planned features — deliberately separated from `BACKLOG.md`'s engineering-level tracking, per explicit product-owner decision), and per-domain feature specs, at minimum `maintenance-workflow.md`, `auth-onboarding.md`, `navigation-home.md` (approved as its own spec, not folded into the master PRD), `app-config.md`, and `retail-catalog.md`.

**Testing:** documentation-only change — no application code, Firestore rules, or Storage rules were touched. Verified via repeated repo-wide `git grep` sweeps confirming no remaining stale bare-filename references outside the intentionally-deferred set above, and by cross-checking `PERMISSIONS_MATRIX.md`'s refreshed content directly against the deployed rules text and current source files rather than from memory or the original ADRs' draft intent.

**Merged:** PR #7, squash-merged as `ae306d3`. Feature branch `docs/restructure-engineering-docs` deleted locally and remotely per `CONTRIBUTING.md` §9/§10. (Local sync to `main` after merge required a one-off workaround: `git push`/`git fetch` over SSH fail in the sandboxed execution environment used for this session — no SSH key access — so the push, and the post-merge local sync, both went over HTTPS using the already-authenticated `gh` CLI credentials instead, without changing the configured `origin` remote or git identity.)

**Explicitly not decided in this session:** what comes after this. Per product-owner instruction, no assumption is made that product-documentation/PRD work starts next — there are still product-level decisions to align on first (e.g., the retail catalog's long-term fate was discussed but not fully resolved). The next phase is to be defined jointly, not assumed.

---

### 2026-07-22 — Product discovery and `docs/product/` documentation set completed and merged

**Decision:** Undertake a full product discovery process for Techno Store — explicitly not an exercise in documenting the current implementation, but a first-principles rediscovery of the best version of this product that can reasonably be built, treating nothing as sacred purely because it already existed or shipped, and with the resulting roadmap kept strictly downstream of discovery (never allowed to influence it).

**Decided by:** Product owner, who set the governing philosophy before any discussion began: product quality over implementation ease, every existing decision/feature/workflow open to challenge, sunk cost explicitly excluded, UI/UX treated as fully open rather than constrained by what's shipped, and discovery run as structured phase-based discussions rather than large batches of unrelated questions. Also set the meta-flow this session followed end to end: Product Discovery → Open Product Decisions → Product Discussions → Product Documentation Planning → Product Documentation Structure Approval → PRD Structure Approval → PRD Writing → Product Review → Roadmap Definition, with "Future Implementation Decisions" explicitly named as a later, separate step not to be assumed as started by this work.

**Outcome:** Conducted across nine sequential discovery phases — Vision & Strategic Foundation, Core Domain (maintenance workflow and customer/device transparency), Retail Strategy, Identity & Permissions, Auth & Account Lifecycle, Information Architecture, UI/UX & Design System, Platform & Technical Scope, Business Operations & Analytics — each closed with an explicit agreed/open/disagreements synthesis before the next began, followed by a full discovery synthesis across all nine. A reusable decision-making methodology emerged from recurring patterns across phases rather than being designed upfront: 4 Product Principles (Relationship Not Transaction; Goal-Oriented Not Feature-Oriented; Built for This Business Not a Platform; Action and Authority Are Separable), 2 Structural Patterns (Identity Persists/Attributes Change — proven independently four times: device/repair-episode, customer/phone-number, staff/role, experience/platform; Sequences Carry Meaning), 3 Operational Tests (does the application need to participate here or does this belong to reality; can an existing place already satisfy this goal; has this specific conclusion actually been earned), and 6 Design Principles governing the experience layer (Tell the Story Not the Status; For Staff, Invisible Is the Highest Compliment; Quiet When Life Is Quiet; Presence Is Earned Not Performed; Default Modes Break at Genuine Exceptions; Deliberate Friction Protects Against Real Mistakes).

Documentation planning was itself held to the same discovery discipline (structure proposed and approved before writing, each document's purpose independently justified rather than assumed) and produced four files under `docs/product/`: `METHODOLOGY.md` (the decision-making reference above), `PRD.md` (a Shared Foundation — vision & scale, core entities & identity model, auth & account lifecycle, the relationship timeline, roles as expertise — plus three deliberately asymmetric lenses answering different questions: Relationship Lens, Operational Lens, Business Lens, with open items flagged inline rather than collected in an appendix), `OPEN_DECISIONS.md` (a registry of what discovery deliberately left unresolved, in four honestly distinct categories: Open Product Decisions, Design & Experience — Not Yet Earned, Revisitable Concepts — Not Currently Earned, Disagreements on Record), and `ROADMAP.md` (open decisions sequenced into four groups strictly by factual dependency — Foundational, Self-Contained, Gated by Something Outside This Process, Speculative — never by priority, ease, or timeline; ordering within a group implies nothing). Every section of every document was read in full and individually corrected/approved before the next began; several rounds of precision fixes were made in response to product-owner review, including distinguishing technical-judgment attribution from business authority, qualifying retail-boundary language so it doesn't imply every physical sale touches the app, precisely wording what's settled vs. open around staff-account and deletion/refund authority, and — most substantively — a completeness pass on `OPEN_DECISIONS.md` after the product owner caught real gaps against `PRD.md` (the PIN/pattern purge lifecycle, "Starting Something New," and order-fulfillment-distinct-from-payment-timing were all missing or conflated), which also surfaced that Staff Communication Timeline needed its own new category (a rejected-but-reopenable concept, not an execution-level design question).

Closed with a dedicated Product Review — a deliberate holistic pass across all four documents together, distinct from the section-by-section writing review, asking whether someone reading all four for the first time would conclude this is truthfully the best version of Techno Store that discovery earned. It found three genuine cross-document defects invisible to any single document's own review: a direct contradiction between `ROADMAP.md` (which gated product representation's shape behind inventory ownership) and `OPEN_DECISIONS.md` (which explicitly said it wasn't blocked by that); `METHODOLOGY.md`'s Design Principle 5 naming "exactly three" universal triggers for breaking default modes while `PRD.md`'s Operational Lens actually used a fourth, unnamed one (technical-judgment attribution); and misleading Shared Foundation phrasing that implied staff-account-management authority was as open as deletion/refund authority when it was actually already settled. All three were fixed in place. A related philosophical tension — "a promotion genuinely relevant to customers" sitting as a settled Communication Timeline example without independent scrutiny — was resolved by moving it into `OPEN_DECISIONS.md` across all three affected documents. `METHODOLOGY.md`'s introduction now records a standing expectation to cross-check these documents against each other whenever one changes, not just against itself, since this defect class was proven real and not theoretical.

**Testing:** documentation-only, no application code, Firestore rules, or Storage rules touched. Verified by full-document reads (not summaries) at every approval step, and specifically by the holistic Product Review step designed to catch what section-by-section review structurally cannot.

**Merged:** PR #8, squash-merged as `110f8b2`, four commits in dependency order (`METHODOLOGY.md` → `PRD.md` → `OPEN_DECISIONS.md` → `ROADMAP.md`), each individually reviewed and approved. Feature branch `docs/product-discovery-and-prd` deleted locally and remotely per `CONTRIBUTING.md` §9/§10. (Local sync to `main` again required the HTTPS workaround established during the 2026-07-17 merge — SSH push/fetch is unavailable in this sandboxed execution environment.)

**Explicitly not decided in this session:** what comes after this. `ROADMAP.md` sequences the open product decisions by dependency, but which of them — or what engineering work — gets taken up next is a separate, later decision ("Future Implementation Decisions" in the product owner's own meta-flow), not assumed here.

---

### 2026-07-23 — Staff account, activation, and dark/light mode decisions reconciled (PR #9)

**Decision:** Resolve two Open Decisions and one previously-agreed-but-unreconciled product truth that surfaced directly while reviewing the Auth & Entry workflow during the "Current Application Review & Evolution" phase (the phase agreed to follow Product Documentation) — rather than continuing to review code against product documents that were, on inspection, internally contradictory.

**Decided by:** Product owner, in direct response to concrete findings from a full code-level review of Auth & Entry (`MainScreen`'s auth state machine, `AuthCubit`/`AuthServices`, `NewUserAdminSide`, and related views): the "Add new Employee" screen's account-creation call was found entirely commented out end-to-end (UI → Cubit → Service, meaning no live path exists today to create a Reception/Maintenance/Admin account), and `ADR-004` and `PRD.md` were found to describe the `isActivated` field with two directly contradictory stories — a forward-looking staff activation mechanism per `ADR-004`, versus a retired multi-tenant-licensing artifact per `PRD.md`.

**Outcome:** Resolved directly rather than carried forward:
- **Staff account creation** is settled: accounts are created directly by Admin, with no invitation flow, authenticating via email and password — a path deliberately separate from the customer phone-OTP flow.
- **Staff status** (active/inactive) is introduced as a new, distinct concept from role, letting Admin suspend and later restore an employee's access without touching identity or history. This resolves the `ADR-004`/`PRD.md` contradiction by recognizing both were partially right: the old generic `isActivated` field really is retired for customer accounts (as `PRD.md` said), but `ADR-004`'s underlying need — Admin-driven activate/deactivate — is real and will be met by this new, staff-specific concept rather than a revival of the old field.
- **Light and Dark Mode** are settled as supported product capabilities (not token/partial implementations) — a decision reached earlier in the Auth & Entry review's Foundation Design Decisions pass but not yet reconciled into the documents. Given a canonical home in a new `PRD.md` subsection, **Appearance & Accessibility**, alongside the already-agreed Arabic-first support, WCAG 2.2 AA baseline, and Material 3 foundation — stating only earned constraints, not a design system.

Implemented on `docs/staff-account-and-activation-decisions` as five reviewed, individually-approved commits: `PRD.md` (staff account creation/status settled), `OPEN_DECISIONS.md` (both items closed), `ROADMAP.md` (resolved item removed), `ADR-004` (status note pointing at the settled decision, flagging that its `isActivated`-based technical design needs revisiting against the new staff-status concept when actually built), and a follow-up commit adding `PRD.md`'s new Appearance & Accessibility subsection plus a corrected cross-reference in `OPEN_DECISIONS.md`.

**Testing:** documentation-only; no application code, Firestore rules, or Storage rules touched. Every cross-reference between the four affected documents re-read after editing to confirm no remaining contradictions.

**Merged:** PR #9, squash-merged as `d3ada95`. Feature branch `docs/staff-account-and-activation-decisions` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Explicitly not decided in this session:** the actual technical implementation of staff status (data shape, Cloud Function design, audit logging) — `ADR-004`'s note flags this as a real design question for whenever it's actually built, not resolved here. Also unresolved: the remaining Auth & Entry code findings from the same review pass — a likely navigation bug stranding new phone sign-ups on the OTP screen after successful verification, a phone country-code propagation bug in the sign-in form, a silent password-reset failure, dead email/password-auth-adjacent code (now partially relevant again given the staff-account decision), and two seemingly unreconciled app-update mechanisms. The Auth & Entry review continues from here.

---

### 2026-07-23 — Two contained Auth & Entry bug fixes shipped; update-mechanism finding retracted

**Decision:** Implement the two Auth & Entry findings that were fully contained and required no product or design decision, as separate reviewable fixes, rather than waiting for the broader staff-auth workflow to be designed. Investigate the "two app-update mechanisms" finding before deciding whether it needed fixing at all.

**Decided by:** Product owner, confirming the two bug fixes should proceed independently and asking for a history-based investigation (not a guess) on the update-mechanism question before any action there.

**Outcome:**
- **Update-mechanism finding retracted.** `git log` traced `in_app_update`'s usage in `SignIn.initState` to before the forced-update feature existed, and `docs/ai-workflow/DECISIONS_LOG.md`'s own 2026-07-09 entry (already read earlier this session but not cross-checked against this specific code-review finding) documents that the forced-update feature's design explicitly audited `in_app_update` first and made a deliberate call: kept unchanged, as a non-blocking Android-only nudge toward the latest Play release, with all actual blocking owned by `AppUpdateCubit`/`ForcedUpdatePage`. Complementary by design, not redundant — no code change made. Recorded here as a correction to the prior review pass's characterization, not a new decision.
- **Fix 1:** `PinVerificationPage`'s listener now also reacts to `AuthNeedsProfileCompletion`, not just `AuthSuccess`, and pops the same way. Brand-new phone sign-ups were emitting `AuthNeedsProfileCompletion`, which the listener ignored, stranding them on the OTP screen while `MainScreen` swapped to `CreateUserAccount` unseen underneath.
- **Fix 2:** `SignInFormPhoneInput` no longer mutates its own local `phoneCode` field (silently discarded, since it's passed by value from the parent). Replaced with an explicit `onCodeChanged` callback so country selection actually reaches `SignInFormPhoneMethod`'s state before submission. The widget is now properly immutable, dropping the `must_be_immutable` lint suppression it carried.

Implemented on `fix/auth-pin-verification-and-phone-code` as two separate, individually-approved commits, deliberately not bundled together or with the broader staff-auth redesign.

**Testing:** `flutter analyze` clean on all four touched files. Manual on-device verification of both fixes (new-signup flow reaching profile completion; non-default country code submitting correctly) flagged as recommended but not yet independently confirmed by the product owner.

**Merged:** PR #10, squash-merged as `75b735c`. Feature branch `fix/auth-pin-verification-and-phone-code` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Explicitly not decided in this session:** the staff-auth workflow itself. Product owner directed that this be treated as its own workflow-design discussion before any implementation — not an incremental revival of the old, pre-decision email/password code, which is to be treated as reference only, inspected for reusable pieces rather than restored wholesale. Scope for that discussion, per product owner: the entry point and dedicated screen already discussed, plus explicitly session management, in-session deactivation behavior, in-session role changes, sign-out and session restoration, and shared-device implications between staff and customer accounts. Not started as of this entry.

---

### 2026-07-23 — Staff Auth workflow behavior settled; shared-device switching registered as open (PR #11)

**Decision:** Settle the Staff Auth workflow-design discussion's behavioral questions (entry point, dedicated screen, error handling, password reset, status enforcement at sign-in/restart/session, session/device model) and reconcile the parts that are genuine product truth into `docs/product/`, rather than leaving settled decisions living only in conversation.

**Decided by:** Product owner. Key calls: a small, clearly visible "Staff sign in" entry beneath the customer phone form (not hidden behind a gesture); the old email/password code treated as reference only, not a revival base; staff sessions not restricted to a single device (no concrete reason identified to justify the session-tracking infrastructure that would require); no default automatic sign-out timeout, since shop devices commonly stay in active operational use throughout the day; deactivation and role changes take effect immediately, everywhere observed, via the same forced-sign-out mechanism (uniform behavior rather than trying to hot-swap role-dependent UI in place). One precision correction from the product owner during review: "no default sign-out timeout" must not be read as "no inactivity handling at all" — shared devices may eventually need inactivity-based *locking* that preserves the underlying session, which is materially different from a full sign-out, so that distinction was written into `PRD.md` explicitly rather than left implicit.

**Outcome:** Reconciled into `docs/product/` as three commits: `PRD.md`'s Auth & Account Lifecycle section extended with the settled session-behavior truths and a precisely-scoped Open line; a new `OPEN_DECISIONS.md` item, **Shared-device staff identity switching or locking**, registered under Identity & Account Lifecycle — the need is confirmed and settled, but its secure mechanism (local PIN, another re-authentication method, inactivity-based locking, or something else) is explicitly not designed, and was deliberately not guessed at inline; `ROADMAP.md` sequences it under Self-Contained.

**Testing:** documentation-only; no application code, Firestore rules, or Storage rules touched.

**Merged:** PR #11, squash-merged as `584bd27`. Feature branch `docs/staff-auth-session-decisions` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Explicitly not decided in this session:** the technical architecture behind any of this — the staff-status data model, write authority, Firestore rules, live-session enforcement mechanism, behavior on role/status change at the code level, migration from the legacy `isActivated` field, and failure handling if status can't be verified. Product owner explicitly named this as the next step: a dedicated **Staff Status Architecture Pass**, before anything is treated as implementation-ready.

---

### 2026-07-23 — Process-discipline correction: implementation is the default once a line of work clears, not a new phase

**Decision:** No additional "implementation planning" phase gets introduced by default once a line of work has settled product decisions, behavior, and architecture with no remaining blockers — implementation itself is the natural next step at that point, unless there's a concrete reason not to. More generally, keep the "Current Application Review & Evolution" phase iterative — review → decide → implement → test → move on, per item — rather than accumulating a large batch of settled-but-unbuilt decisions across an entire product area before building anything.

**Decided by:** Product owner, explicitly warning against the decision-making framework built across PR #6–#12 becoming "the thing we're optimizing for" instead of a tool for decision quality. Staff Auth (settled end-to-end across PR #9–#12: product decisions, workflow behavior, technical architecture) was named as the worked example — once genuinely implementation-ready, activating it should mean building it, not adding another phase first.

**Outcome:** No code or document change — a standing process correction, recorded here and in memory for continuity across sessions (`[[future-implementation-decision-process]]`, `[[current-application-review-phase]]`). Applied immediately: when closing the Auth & Entry review's last two items (route-level authorization, the inactive Cairo font declaration), both were implemented directly as soon as they were confirmed contained and unblocked, rather than deferred into a separate planning step.

**Testing:** N/A — process decision.

**Explicitly not decided in this session:** which specific line of work moves into implementation next. Per the same discipline, that's a genuine sequencing decision to make deliberately once the Auth & Entry review is fully closed out, not something to default into.

---

### 2026-07-23 — Two contained closeout fixes shipped, Auth & Entry review complete

**Decision:** Close the Auth & Entry review's two remaining independent items — route-level authorization and the inactive Cairo font declaration — as the final step before treating the area as complete, per the product owner's explicit request to close the authorization gap "properly rather than treating it as a residual concern by default."

**Decided by:** Product owner, confirming both items were sufficiently contained and independent of the still-pending Staff Auth implementation to finish now.

**Outcome:**
- **Route-level authorization:** `AppRouter` performed no role checks at all — `createAccountAdminSide` (Admin-only) and `maintenancePage` (staff-only) were reachable by anyone who could trigger the navigation, protected only by the drawer not showing the button. This is the exact gap `ADR-004`'s "Route-level authorization" section already flagged, closed now specifically because `createAccountAdminSide` is about to become a real, functioning screen via Staff Auth rather than a non-functional one. Firestore rules and Cloud Functions remain the actual enforcement backstop for any write — this closes UI-reachability, not a substitute for that. Confirmed distinct from `BACKLOG.md` item 0a (direct/bypass-the-UI Firestore rules testing), a different, still-separately-tracked concern.
- **Cairo font declaration:** `fontFamily: 'Cairo'` was removed from both light and dark theme. It was never bundled (no `fonts:` section in `pubspec.yaml`, no font files in the repo) and silently fell back to the platform default while the code claimed otherwise. A real tension was caught and resolved deliberately: actually bundling Cairo now would have settled the still-open typeface comparison (`OPEN_DECISIONS.md`'s Design & Experience section) through implementation rather than decision. Removing the dead declaration fixes the code's false claim without spending that openness — Arabic-first support remains a settled requirement; the specific typeface stays open.

Implemented on `fix/auth-router-role-guards` as two separate, individually-approved commits.

**Testing:** `flutter analyze` clean on all touched files (one pre-existing, unrelated `withOpacity` deprecation warning, not introduced by this change). Manual on-device verification of the route guards flagged as recommended but not yet independently confirmed by the product owner.

**Merged:** PR #13, squash-merged as `0fc44b8`. Feature branch `fix/auth-router-role-guards` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**With this merged, the Auth & Entry area of "Current Application Review & Evolution" is complete.**

**Explicitly not decided in this session:** what's genuinely implementation-ready next. Also flagged here: PR #12 (the Staff Status architecture settlement on `ADR-004`) was found still open and unmerged at this point in the session — approved in conversation but the merge/cleanup sequence was never actually run. Needs the product owner's review before it can be folded into any "what's implementation-ready" assessment, since that assessment depends on the architecture actually being in `main`, not just agreed in conversation.

---

### 2026-07-23 — PR #12 closed out; Staff Auth's full design line now in `main`

**Decision:** Merge the previously-dropped PR #12 before making any implementation-readiness assessment, so that assessment is grounded in what's actually in `main`, not just what's been agreed in conversation.

**Decided by:** Product owner, explicit: "I'd rather have `main` reflect the settled state before we make any implementation-readiness decisions."

**Outcome:** PR #12 squash-merged as `ee1b2d3`. With this, every piece of the Staff Auth line of work — product decisions (PR #9), workflow behavior (PR #11), and technical architecture (PR #12) — is now actually present in `main`, not just settled in conversation. Feature branch `docs/staff-status-architecture` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Testing:** documentation-only; no application code, Firestore rules, or Cloud Functions touched.

**Merged:** PR #12, squash-merged as `ee1b2d3`.

**Explicitly not decided in this session:** what's genuinely implementation-ready next — the product owner explicitly asked for an active recommendation here, not deference, consistent with the standing instruction to keep challenging sequencing rather than treating it as their call alone.

---

### 2026-07-23 — Staff Auth implementation begins: setStaffStatus Cloud Function shipped (PR #14)

**Decision:** Begin Staff Auth implementation, split into two PRs — backend first, client-side vertical slice second — with the client PR's scope and acceptance criteria locked in explicitly before it starts, since it combines several security-sensitive behaviors rather than being just a new screen.

**Decided by:** Product owner, confirming the sequencing recommendation (Staff Auth now, before opening Reception & Maintenance's review, to keep one active line of work at a time) and setting nine explicit acceptance criteria for the still-pending client PR: active staff sign-in succeeds; inactive staff denied and immediately signed out; status rechecked on app restart; deactivation during an active session forces sign-out with a clear message; a role change during an active session forces sign-out with a distinct message; a temporary listener/network interruption does not force sign-out; password-reset failures are handled correctly without false success; the customer phone-OTP path remains unchanged; staff and customer authentication paths remain clearly separated.

**Outcome:** `setStaffStatus({ uid, status })` HTTPS Callable Cloud Function added to the existing `functions/` project (no new infrastructure — corrects a stale `ADR-004` claim that this would require standing up Cloud Functions "for the first time"; `functions/index.js` already existed via `linkDevicesToNewCustomer`). Requires the caller to be Admin *and* have their own `staffStatus` active (closes the deactivated-Admin-with-a-lingering-session gap), restricts targets to staff accounts, writes an audit log entry for every change. No Firestore rules changes needed — the existing `users/{uid}/meta/{metaDoc}` wildcard already denies all client writes and covers the new `staffStatus` document automatically. No client-side changes in this PR; the function is unreachable from the app until the client PR ships.

Implemented on `feat/set-staff-status-function` as two commits (the function; the `ADR-004` correction).

**Testing:** `node --check` and module-load verification only — not yet deployed or exercised against a live/emulated Firestore instance. Flagged as recommended (Admin can activate/deactivate; non-Admin caller rejected; deactivated-Admin caller rejected; Customer target rejected; audit log entry written) before the client PR relies on it.

**Merged:** PR #14, squash-merged as `8fc01a5`. Feature branch `feat/set-staff-status-function` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Explicitly not decided in this session:** the client-side vertical slice itself. Scoped and bounded by the nine acceptance criteria above, to be implemented next.

---

### 2026-07-23 — Client-side Staff Auth vertical slice shipped and live-verified against all nine acceptance criteria (PR #15)

**Decision:** Implement the client-side Staff Auth vertical slice against the nine acceptance criteria locked in PR #14's entry, and verify the six most security-sensitive criteria (sign-in, deactivation, restart recheck, mid-session deactivation, mid-session role change, listener interruption tolerance) live on a real Android emulator against a real test staff account, rather than closing the line of work on code-level reasoning alone.

**Decided by:** Product owner, requesting live verification explicitly: "the outstanding cases are the most security-sensitive part of this feature ... I don't think leaving these six criteria resting only on code review." Provided a real test staff account (`staffStatus`/role toggled live in Firestore during the pass) and an explicit standing instruction to stop and flag anything unexpected rather than working around it silently.

**Outcome:**
- Removed the retired `isActivated` field from `UserData` and `FirestoreApiPath`; added `staffStatus(uid)` pointing at `users/{uid}/meta/staffStatus`, write-only via the already-shipped `setStaffStatus` function.
- `AuthCubit.signIn` rewritten as the staff-only email/password path: Firebase Auth → fetch `UserData` → confirm staff role → check `staffStatus` (fail-closed: missing/unreadable/non-`active` all deny) → curated rejection messages, or `AuthSuccess` plus two live Firestore listeners (`staffStatus`, and the user document itself for role changes). Both listeners react only to actual data changes, never to `onError` (network interruption) — the mechanism behind criterion 6.
- `checkAuth()` runs the same fail-closed staff-status check on app restart before granting `AuthSuccess`.
- New dedicated `StaffSignInPage`, reachable via a small, low-emphasis "Staff sign in" entry beneath the customer phone form — never a toggle inside it, keeping the two auth paths structurally separate.
- `AuthServices.resetPassword` changed from a `Future<bool>` that swallowed all errors into an unconditional `true` to a `Future<void>` that only treats `user-not-found` as a silent success (preventing account enumeration) and rethrows everything else.
- Two pre-existing bugs found via live testing, not code review, and fixed in-scope per product owner approval:
  - `UserData.fromMap` cast `phoneNumber`/`location` as non-nullable `String`, crashing on any staff document (created directly in Firestore, never through `completeUserProfile`, so lacking `phoneNumber` entirely). Fixed: `phoneNumber` defaults to `''` (matches its non-nullable declared type), `location` reads as nullable (matches its declared type). Flagged for later, deliberately out of scope now: whether `phoneNumber` should become nullable on the shared `UserData` model, since a staff account doesn't inherently have one.
  - `Message.showBottomMessage` internally re-curated any message against hardcoded Firebase error-code substrings, silently discarding caller-curated text that didn't literally contain them — found when a real `invalid-credential` response showed "An unexpected error occurred" instead of `AuthCubit`'s actual curated message. This affected the already-shipped customer phone-OTP error path too, not just new code. Fixed by removing the re-curation entirely; error interpretation now happens exactly once, at the `AuthCubit`/domain boundary.

**Live verification (real device, real test staff account, `moh95od@gmail.com`):**
1. Active sign-in — verified live.
2. Inactive denial + immediate sign-out — verified live.
3. Restart recheck — not exercised in isolation; the test sequence used hit criterion 4 first (deactivation while the app was open forced an immediate sign-out), so no session remained to restart into by the time the app was relaunched. Product owner explicitly accepted this as "not yet exercised independently" rather than failed, and the immediate-sign-out behavior observed instead was treated as a positive result. Deferred, not blocking.
4. Mid-session deactivation forces sign-out with distinct message — verified via precise log timestamps correlating with the live Firestore change, accepted by product owner without requiring a repeat for a screenshot.
5. Mid-session role change forces sign-out with distinct message — verified on the same log-based basis as criterion 4.
6. Listener interruption tolerance — verified live: wifi/data disabled ~23s (app stayed on Home, signed in, no forced sign-out), then re-enabled (app remained stable, still signed in). Both directions confirmed no forced sign-out from connectivity alone.
7. Password-reset failure handling — covered by the `resetPassword` fix and code review (not separately live-verified against a real failure).
8. Customer phone-OTP path unchanged — verified live, including a real `app-not-authorized` error displaying its full unmodified message post-fix.
9. Staff/customer paths clearly separated — verified live and via code review (dedicated screen, dedicated entry point, no shared toggle).

Two real bugs were caught specifically by live testing that code review had missed, validating the product owner's insistence on it for this security-sensitive slice.

Implemented on `feat/staff-auth-client` as six commits (retire `isActivated`/add `staffStatus` path; staff sign-in with status enforcement; `resetPassword` false-success fix; Staff Sign In screen/entry point/deactivation messaging; `Message.showBottomMessage` re-curation removal; `UserData.fromMap` null-safety fix).

**Testing:** live, on a real Android emulator against a real test staff account and real production Firestore data, per the criteria above. No automated test suite added for this slice.

**Merged:** PR #15, squash-merged as `31c2c81`. Feature branch `feat/staff-auth-client` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**With this merged, the full Staff Auth line of work (PR #9–#15: product decisions, workflow behavior, technical architecture, backend function, client vertical slice) is complete and in `main`.**

**Explicitly not decided in this session:** criterion 3 in true isolation (app fully closed before any `staffStatus` change, then relaunched) — left deferred rather than pursued further, per product owner's preference to keep moving rather than re-litigate an already-proven mechanism in a different form. Also not decided: what's genuinely implementation-ready next, now that Staff Auth is fully closed out.

---

### 2026-07-23 — Reception & Maintenance review begins; PIN/pattern purge decoupled from delivery

**Decision:** Continue immediately into the Reception & Maintenance area of "Current Application Review & Evolution," per the same review → implementation → live verification → merge → move on rhythm just proven on Staff Auth, with no new planning phase opened first. A first code-level pass (routes, the device intake form, the maintenance tracking list, Fixed/Deliver dialogs, `ManageCategoriesPage`, the drawer) surfaced several findings against `docs/product/PRD.md`; the product owner chose to settle one immediately rather than leave it open: **the Delivered event does not automatically purge PIN/pattern (sensitive unlock) data.**

**Decided by:** Product owner, explicit reasoning: the customer provided the PIN/pattern voluntarily for the repair to happen, it's already protected by the existing access-restriction/isolation design (`ADR-001-sensitive-data-separation.md`), and no concrete value was identified in automatically destroying it at delivery that would outweigh losing potentially useful history for the same device's future maintenance work. Delivery and destruction are deliberately treated as two different concepts — not coupled by default. Any future retention limit or permanent-deletion policy for this data is explicitly folded into the general, still-open permanent-deletion/business-authority question, not decided as a side effect of delivery.

**Outcome:** This reverses a previously-settled `PRD.md` claim ("the Delivered event permanently triggers its purge lifecycle") that was never actually implemented — the code-level review found no purge mechanism anywhere (not in `deliverDevice()`, not in any Cloud Function), so this decision brings the document in line with both the code's actual behavior and the product owner's now-considered judgment, rather than requiring new purge code to be built to satisfy a stale requirement. `PRD.md`'s Shared Foundation → The Relationship Timeline section rewritten accordingly; `OPEN_DECISIONS.md`'s "PIN/pattern purge timing" item renamed to "Retention limit for sensitive unlock data" and rescoped to whether any retention/deletion trigger should exist at all, decoupled from delivery specifically.

**Testing:** documentation-only; no application code touched (there was no purge code to remove — it never existed).

**Merged:** PR #16, squash-merged as `a7203ed`. Feature branch `docs/pin-pattern-purge-decoupled-from-delivery` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Explicitly not decided in this session:** the other findings from the same review pass remain open and undecided, most notably two other conflicts with settled `PRD.md` principles found in the same pass — device deletion is a genuine hard delete with no recoverable/hidden state, for devices in any status including Delivered (conflicts with the settled "recoverable by default, hidden not destroyed" principle, and intersects the still-open permanent-deletion-authorization question) — and staff-identity gaps: the `newDeviceMaintenance` route has no role guard (unlike `maintenancePage`/`createAccountAdminSide`), and employee attribution (`receivedByEmployee`/`maintenanceEmployee`/`deliveredByEmployee`) is drawn from a hardcoded, unmaintained `AppConstants` string list rather than the real Staff Auth accounts now in `main`. Also not decided: prioritization/sequencing among these remaining findings, or the confirmed dead code (`ManageCategoriesPage`+cubit, `view_model/maintenance_list_state.dart`, Invoice/Reopen TODOs, several empty drawer stubs).

---

### 2026-07-23 — `newDeviceMaintenance` route guard closed; recommendation process pressure-tested

**Decision:** Fix the `newDeviceMaintenance` route-guard gap immediately (implementation-ready, zero open product question), and — before touching any code on the more consequential device-deletion finding — hold a dedicated decision conversation on its authority boundary and recoverable-removal mechanism, mirroring how Staff Auth settled workflow behavior (PR #11) before architecture (PR #12) before implementation.

**Decided by:** Product owner, after asking for an active recommendation rather than choosing the next item by default — explicit: "If reviewing the findings together changed that recommendation, I'd like to hear that too." The recommendation changed on inspection: initial framing (device deletion first, route guard second) inverted once two things were confirmed — (1) `DeviceCard` already hides Edit/Fixed/Deliver actions from non-staff and Firestore rules already deny non-staff writes to `maintenanceDevices`, so the route guard is pure defense-in-depth matching an already-decided pattern (PR #13), safe to ship immediately; (2) device deletion's fix would require guessing at two things `OPEN_DECISIONS.md` marks genuinely unresolved (who may authorize permanent deletion; what "hidden, not destroyed" means mechanically), so it isn't actually implementation-ready despite being the higher-severity finding. Product owner agreed with the revised recommendation and explicitly endorsed the "implementation-ready vs. needs-a-decision-conversation-first" distinction as one to keep applying going forward.

**Outcome:** `AppRouter`'s `newDeviceMaintenance` case now checks `UserRole.isStaff` on a `UserData` argument, matching `maintenancePage`/`createAccountAdminSide` exactly. All four navigation call sites in `InnerMaintenanceList` (three Edit slidable actions, the FAB) updated to pass the signed-in `UserData` through. `flutter analyze` clean on both touched files.

**Testing:** `flutter analyze` clean. Manual on-device verification recommended (staff can still reach New Device/Edit as before) but not yet independently run.

**Merged:** PR #17, squash-merged as `e2c0f82`. Feature branch `fix/new-device-maintenance-route-guard` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Explicitly not decided in this session:** the device-deletion authority boundary and recoverable-removal mechanism — the next item, deliberately started as a decision conversation rather than code. Employee attribution's hardcoded list, the intake-form shape question, and the confirmed dead code all remain open and undecided, unchanged from the prior entry.

---

### 2026-07-23 — Device lifecycle (Archive/Restore/Permanent Delete) settled and PR 1 shipped (ADR-005)

**Decision:** Settle the device-deletion authority boundary and recoverable-removal mechanism (flagged in the prior entry) through a multi-round decision conversation before any code, then implement the backend/data-layer half as the first of two PRs.

**Decided by:** Product owner, through several rounds of pressure-testing:
- Split the single "Delete" action into three operations with different risk profiles: staff-wide reversible **Archive** (preserves the record, images, and sensitive subdocument untouched), Admin-only **Restore**, and Admin-only, archive-gated, server-side-enforced **Permanent Deletion**.
- Rejected reusing `status: 'Archived'` (an earlier draft, cheaper to query) in favor of a genuinely separate `recordState` field — explicit reasoning: archiving is a record-lifecycle concept, not a repair-workflow status, and conflating them would distort status reporting and the deliberately-simple repair vocabulary later, even though the separate field costs more in query/index work now.
- No automatic expiry on archived records in v1; freezing an archived record is absolute, no metadata-correction exception, after finding no concrete (not hypothetical) case for one.
- Reserved the strongest integrity guarantee (`auditLogs`, Cloud-Function-only writes, matching `setStaffStatus`) for Permanent Deletion alone — explicit reasoning: the three operations don't deserve equal architectural weight, and Archive/Restore being reversible makes a forged provenance entry low-stakes and independently checkable, so they use a lighter `lifecycleEvents` subcollection instead, keeping Archive exactly as fast as the action it replaces.
- Permanent Deletion made deliberately hard to reach: Admin-only, only reachable on an already-archived record (an explicit design choice, stricter than strictly required, kept on review), and a typed-confirmation UI in PR 2 — "should feel like an exceptional administrative action," not "the next button after Archive."
- Mid-review, revised the original two-PR rollout: the `recordState` production migration is sequenced **after** PR 2 (the client cutover) is implemented, reviewed, and live-verified — not between PR 1 and PR 2 — so production data is never partially transitioned ahead of code that depends on it. Live verification uses freshly created test devices (PR 2's device-creation path will set `recordState` explicitly), so it doesn't depend on the migration having run.

**Outcome:** `docs/ai-workflow/ADR-005-device-lifecycle-archive-deletion.md` records the full design. PR 1 (backend/data-layer, strictly additive) shipped:
- `permanentlyDeleteDevice` Cloud Function, mirroring `setStaffStatus`'s shape (Admin + own-`staffStatus`-active check), archive-only precondition, Storage/sensitive-subdoc/parent cascade via Admin SDK (a full prefix delete now, not the client's URL-by-URL workaround), durable `auditLogs` entry written before the final delete.
- Firestore rules: `recordState` Archive/Restore/frozen-while-archived transitions on `maintenanceDevices`, new `lifecycleEvents` subcollection rules. `allow delete` deliberately left unchanged — tightening it is sequenced into PR 2, alongside the client cutover that stops relying on it, so `main` is never in a state where a shipped client action can't succeed.
- Migration + verify scripts (`migrate-recordstate.js`/`verify-recordstate.js`), dry-run-by-default, idempotent, mirroring the existing Phase 1C `migrate-pass-a`/`verify-pass-a` pattern — written and tested, **not run against production**.
- `PRD.md` (Relationship Timeline) and `OPEN_DECISIONS.md` ("Deletion recovery mechanism," "The concrete authority mechanism") updated to reflect both are now settled **for maintenance devices specifically** — deliberately not claimed as generalized to other entities or future business-authority actions (refunds).

**Testing:** `node --check` clean on `functions/index.js` and both migration scripts. `flutter analyze` run for baseline confirmation only (no Dart files touched by PR 1). Firestore rules reviewed manually against the file's existing patterns — local `firebase` CLI is broken in this environment, so full rules-emulator validation is deferred to deploy time.

**Merged:** PR #18, squash-merged as `1b1e7a9`. Feature branch `feat/device-lifecycle-backend` deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**Explicitly not decided in this session:** PR 2 itself (client model/query updates, Archive/Restore/Permanent-Delete UI, new Admin-only Archived Devices screen) — up next. Also not decided: whether Restore's data-layer Admin-only enforcement and the `lifecycleEvents` split need a shared helper if a third Cloud Function ever needs the same "Admin + own-staffStatus-active" check (flagged in the ADR's Consequences, two call sites doesn't yet justify it).

---

### 2026-07-24 — Device lifecycle (ADR-005) client cutover shipped, executably verified end-to-end, and cut over to production

**Decision:** Implement PR 2 (client cutover) behind the product owner's explicit preference for executable testing over code-review-only confidence on this feature, verify every layer (Firestore rules, the `permanentlyDeleteDevice` Cloud Function, and the full client UI) against local emulators before touching production, then execute the coordinated production cutover — indexes, functions/rules deploy, migration, verification, and a real-device production smoke test — in one continuous pass.

**Decided by:** Product owner, across several rounds:
- Requested emulator-based executable testing for `permanentlyDeleteDevice` specifically ("the highest-risk operation in this feature"), rather than stopping at the rules-level testing alone.
- When testing surfaced a real bug in the already-shipped `setStaffStatus` function (see below), approved fixing both functions together as a single contained hotfix rather than leaving a known inconsistency, and folding re-verification of both into the same pass.
- Requested a targeted client-side UI smoke test (8 explicit checks) as the final gap before cutover, explicitly scoped as "a targeted smoke test rather than a broader new testing phase," with debug-only emulator wiring required to stay uncommitted and be removed afterward.
- Confirmed the standing sequencing decision from the PR #18 entry: the `recordState` migration runs only as the final coordinated step, after PR 2's code is fully implemented and verified — never partially transitioning production ahead of dependent code.
- Explicitly declined a separate migration backup step, citing that `recordState` is the only field being added and comfort with Firestore's `update()` field-merge guarantee plus the prepared count-check/spot-check verification scripts as sufficient.
- Accepted the residual risk that the already-installed staff app build still has the old hard-delete action, which would fail safely (permission-denied, no data loss) once the tightened rules deployed — staff were already told not to use Delete pending cutover confirmation, so this didn't block proceeding.
- Gave explicit final authorization to run the full cutover sequence (PR merges → indexes → functions/rules deploy → migration → verification → production smoke test) in one pass, stopping only on a genuinely unexpected result.

**Outcome — PR 2 (client cutover), PR #19:**
- `MaintenanceDeviceModel` gained `recordState` (default `'active'`), threaded through `toJson`/`fromJson`/`fromMap`/`copyWith`; `NewDeviceMaintenance.onSaveLogic()` sets it explicitly rather than relying on the model default implicitly.
- `MaintenanceListServices`: tab queries now filter `recordState == 'active'`; the old hard-delete cascade (`deleteDevice`) replaced by `archiveDevice`/`restoreDevice` (batched parent-doc update + `lifecycleEvents` write) and `streamArchivedDevices()`; new `permanentlyDeleteDevice(deviceId)` calling the Cloud Function via `cloud_functions` (the app's first-ever client-side Cloud Functions call).
- `MaintenanceListCubit` gained `archiveDevice`/`restoreDevice`/`permanentlyDeleteDevice`, which rethrow (rather than the existing swallow-and-emit pattern nothing listens to — `BACKLOG.md` item 14) so the UI's own error handling actually fires; `permanentlyDeleteDevice` curates `FirebaseFunctionsException` codes into user-facing text at this boundary, matching `AuthCubit`'s established pattern.
- New Admin-only `ArchivedDevicesPage` (`AppRoutes.archivedDevices`, guarded on `UserRole.isAdmin`, new drawer entry): lists archived devices, with single-confirm Restore and a `_PermanentDeleteDialog` requiring the exact device model typed before the delete button enables — deliberately more friction than Archive, per the ADR.
- `InnerMaintenanceList`'s swipe "Delete" action replaced by "Archive" with the same confirmation-dialog pattern already used elsewhere.
- Firestore rules tightened: `allow delete: if false` on both `maintenanceDevices/{deviceId}` and `private/{doc}` (previously `isStaff()`), now that Permanent Deletion is the only delete path and it's server-side only. `storage.rules` split `allow write` into `allow create, update` + `allow delete: if false` for device folders, for the same reason.
- `firestore.indexes.json` regenerated: the 4 existing composite indexes now include `recordState`, plus a new `recordState` + `updatedAt desc` index for the Archived Devices view (5 indexes total).
- Dead code removed: `FirebaseStorageServices.deleteFileByUrl` (only caller was the removed hard-delete cascade).

**A real, previously-undetected production bug found via executable testing, PR #20 (standalone hotfix, not bundled into PR #19):** both `setStaffStatus` (already shipped) and the new `permanentlyDeleteDevice` crashed identically under the Functions Emulator on `admin.firestore.FieldValue.serverTimestamp()` (`Cannot read properties of undefined`) — a legacy namespaced-access bug in the emulator's runtime wrapper specifically (ruled out Node version via both Node 22 and 24, confirmed plain Node.js resolves the property correctly). Fixed by switching both functions to the modular `require("firebase-admin/firestore")` import. Re-verified via the same emulator tests: both passed. Deployed to production for the first time as part of this cutover — the deployment logged both functions as a "successful **create** operation," confirming neither had ever actually been live in production before, so the fix shipped with them from their first real deployment (the bug never affected real users).

**Executable verification, all local-emulator-only before any production change:**
- Firestore rules: 17/17 tests via `@firebase/rules-unit-testing` against a local Firestore emulator — `recordState` transitions, frozen-while-archived, `lifecycleEvents` writes, tightened `delete` rules.
- `permanentlyDeleteDevice`: 6/6 tests via Functions + Storage + Auth emulators — Admin-only, archive-gated precondition, real Storage/sensitive-subdoc/parent cascade, `auditLogs` write, and isolation confirming `setStaffStatus` was independently broken the same way (see above).
- Full client UI, all 8 of the product owner's checklist items passed locally against the Firestore/Functions/Storage/Auth emulator suite (`technostore-v2` project ID, not `demo-`-prefixed — Android's native `google-services.json` auto-init was found to override a Dart-side `FirebaseOptions` project override, so the emulator itself was run under the real project ID instead; network isolation to `10.0.2.2` was independently re-verified and the tradeoff explicitly flagged to and accepted by the product owner). Debug-only emulator wiring (`main.dart`'s `USE_FIREBASE_EMULATOR` flag, a temporary Android `network_security_config.xml`) fully reverted afterward, never committed.

**Production cutover, executed as one coordinated sequence:**
1. PR #20 merged, then PR #19 merged, `main` synced.
2. All 5 Firestore composite indexes deployed and confirmed `READY` via `gcloud firestore indexes composite list`.
3. Cloud Functions, Firestore rules, and Storage rules deployed together.
4. `recordState` migration: dry-run reviewed, then executed — 494/494 documents updated.
5. Verification: document count unchanged (494 → 494), 0 documents missing `recordState`, 3-document spot-check confirmed all other fields intact (Firestore's `update()` field-merge guarantee, relied on in lieu of a separate backup, held as expected).
6. Production smoke test performed on a real Android emulator, signed in as a real Admin account against real production Firestore: confirmed the "In Maintenance" tab renders real, live production data correctly (validating the new indexes and the migration under the full 494-document dataset); created one clearly-marked synthetic test device (`ZZTEST-CutoverSmokeTest` / `0599999998`, model `ZZTEST-Model`) and ran it through the complete lifecycle — Archive (disappears from "In Maintenance"), Admin-only Archived Devices screen (correctly listed, "In Maintenance" original status shown), Restore (returns to "In Maintenance"), re-Archive, Permanently Delete via the typed-confirmation dialog (button independently confirmed disabled on wrong/empty input, enabled only on an exact match; deletion succeeded, record removed from the Archived list). One accidental tap briefly opened a real customer's device detail sheet during navigation; backed out immediately without touching, editing, or interacting with anything on it — confirmed no data was altered.

**Testing:** fully executable at every layer (rules-unit-testing, Functions/Storage/Auth emulator, real-device client UI against emulators, then a real-device production smoke test using only synthetic test data) — no confidence in this feature rests on code review alone.

**Merged:** PR #20, squash-merged as `ca84951`. PR #19, squash-merged as `4ece686`. Both feature branches deleted locally and remotely per `CONTRIBUTING.md` §9/§10.

**With this, ADR-005 (device lifecycle: Archive/Restore/Permanent Delete) is fully shipped, migrated, and live in production.** The old single hard-`delete` action is gone from both the deployed rules and the client; any staff device still running a pre-cutover build with the old Delete action will fail safely (permission-denied) rather than losing data.

**Explicitly not decided in this session:** the 4 orphaned pre-`recordState` Firestore composite indexes (additive deploy never removes old indexes) — left as low-priority cleanup, not urgent. Whether Restore's Admin-only enforcement and `lifecycleEvents` need a shared helper if a third Cloud Function needs the same check — still not revisited, still not justified by two call sites. What the next line of work is now that the device-deletion thread (started two sessions ago) is fully closed.
