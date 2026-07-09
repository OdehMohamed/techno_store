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
