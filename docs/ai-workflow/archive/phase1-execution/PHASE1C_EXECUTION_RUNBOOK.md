# PHASE1C_EXECUTION_RUNBOOK.md

> - **Archived:** 2026-07-17
> - **Historical reference only.**
> - Reflects the project's state before the Phase 1 remediation work was completed. This runbook's own "Status" line below predates execution — all five checkpoints were run against production and confirmed GO; see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` and the 2026-07-04 entries in `docs/ai-workflow/DECISIONS_LOG.md`.
> - **Must not be treated as the current source of truth.** For current information, see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` (what shipped) and `docs/ai-workflow/DECISIONS_LOG.md` (the full decision record, including the execution log for each checkpoint). Retained as historical reference documentation — parts of it may be useful when planning a future migration or rules deployment, but it should not be treated as a current or authoritative procedure.

**Status: runbook only. Nothing in this document has been executed.**
**Scope:** Phase 1C — running the migration against production and deploying Firestore/Storage rules — per `PHASE1_IMPLEMENTATION_PLAN.md` §7, validated by the Migration Rehearsal (`DECISIONS_LOG.md`, 2026-07-03) and `MIGRATION_SUCCESS_CRITERIA.md`.

This runbook is meant to be followed literally, step by step, by whoever executes Phase 1C. Each checkpoint is a hard stop — do not proceed to the next checkpoint without an explicit GO decision recorded for the current one.

---

## Prerequisite — confirm before Checkpoint 0

**This must be answered "yes" before anything else in this runbook begins. It is not one of the five checkpoints because it isn't a Phase 1C action — it's a precondition Phase 1C's safety depends on.**

> **Is the Phase 1B app build (containing the merge-based `updateDevice` write, the sensitive-data schema split, the async edit-form fetch with error handling, and the role allow-list fixes) live and in use by all active staff sessions?**

Why this matters: `migrate-pass-b.js` removes `pin`/`patternLock`/`notesHidden` from parent documents. If any staff device is still running pre-Phase-1B code, that old code reads/writes those fields directly on the parent document — it does not know about the new subcollection. Running Pass B while old code is still active would functionally break that old client's ability to see or correctly save sensitive data. Phase 1B's own plan (§4) specified this exact precondition; this runbook is restating it as a hard gate because it's easy to lose track of across long conversations.

- [ ] Confirmed: Phase 1B code is deployed and in use by all active staff sessions.
- If this cannot be confirmed with confidence, **stop here** — do not begin Checkpoint 0. Resolve this first (e.g., force-update staff devices, or wait out the rollout window), then return to this runbook.

---

## Legend

- **Read-only**: makes no writes to production Firestore/Storage data.
- **Writes (additive)**: creates new data; does not remove or overwrite existing production fields.
- **Writes (destructive)**: removes or overwrites existing production fields. Cannot be undone by re-running the script — requires the backup-restoration procedure.
- **Config change**: does not touch document data at all; changes access-control rules.
- Time estimates assume the migration scripts' current sequential (non-parallelized) implementation — each document is processed one at a time via `await` in a loop, not in parallel batches. Actual throughput depends on network latency to the Firestore backend; treat these as planning estimates, not guarantees, and record actual observed time at Checkpoint 0/1 to calibrate expectations for later steps.

---

## Checkpoint 0 — Production backup verification, inventory, review, GO/NO-GO

| Step | Command / Action | Read-only or writes | Expected output | Est. time |
|---|---|---|---|---|
| 0.1 | Verify format A backup (managed `gcloud firestore export`) exists in the backup bucket and is readable | Read-only (against backup storage, not production) | A non-empty export directory under `gs://<backup-bucket>/firestore/<timestamp>/` with recent contents | 2–5 min (manual check) |
| 0.2 | Verify format B backup (`backup.js` JSON dump) exists; if not already produced as part of the backup already completed, run it now | Read-only against Firestore; writes only to local files / backup bucket, never to production app data | `backups/<timestamp>/maintenanceDevices.json` and `users.json`, non-empty, document counts printed to console | 1–3 min for a small collection (scales with document count — see note below) |
| 0.3 | `node inventory.js` | Read-only | Console report: `Total maintenanceDevices documents (N): <n>` and `Documents with sensitive data (M): <m>` | Well under 1 min for small/medium collections; scales with total document count |
| 0.4 | Human review of inventory output | N/A (observational) | N and M recorded in this runbook's execution log (see template at the end); sanity-checked against any independent expectation (e.g., Firebase Console's own document count for `maintenanceDevices`) | 5–10 min |
| 0.5 | GO/NO-GO decision | N/A | Recorded decision, see criteria below | — |

**Downtime:** none. Every action in this checkpoint is read-only against production (writes, if any, go only to backup storage, never to the live app's data). The app continues operating normally throughout.

**Stop conditions (pause before 0.5, investigate):**
- Format A backup cannot be located or fails a basic integrity check (e.g., empty directory, obviously truncated).
- `backup.js` (0.2) throws an error or produces a JSON file that's empty or clearly malformed.
- `inventory.js` throws an error instead of completing.
- The Firebase Console's own document count for `maintenanceDevices` does not roughly match N from `inventory.js` (a mismatch suggests the script isn't targeting the right project/collection — verify `GOOGLE_APPLICATION_CREDENTIALS` and project ID before proceeding).

**Rollback trigger:** not applicable — nothing destructive happens in this checkpoint. If something looks wrong, the only action needed is to not proceed.

**GO criteria (all must be true):**
- [ ] Format A backup confirmed present and intact.
- [ ] Format B backup confirmed present and intact (freshly produced or previously completed — either is acceptable, but its existence must be confirmed, not assumed).
- [ ] `inventory.js` completed without error.
- [ ] N and M are recorded and sanity-checked (M ≤ N, both non-negative, roughly consistent with any independent expectation of collection size).

**NO-GO action:** stop. Do not proceed to Checkpoint 1. Investigate the specific stop condition triggered. Do not delete or modify anything to "fix" a NO-GO — diagnose first.

---

## Checkpoint 1 — Pass A, verification, human review, GO/NO-GO

| Step | Command / Action | Read-only or writes | Expected output | Est. time |
|---|---|---|---|---|
| 1.1 | `node migrate-pass-a.js` (dry-run, no flag) | Read-only | Console lists `[DRY-RUN] Would write <id>/private/sensitive = {...}` for each of the M devices, and `[SKIP] <id>: private/sensitive already exists` for any already-migrated device. Summary line: `Devices with sensitive data (M): <m>`, `Would migrate: <count>` | Well under 1 min for small/medium collections; scales with M |
| 1.2 | Review the dry-run output against the M value from Checkpoint 0 | N/A (observational) | `Would migrate` + already-migrated count should sum to M | 5 min |
| 1.3 | `node migrate-pass-a.js --execute` | **Writes (additive)** — creates new `private/sensitive` subdocuments; never touches the parent document | Console: `[MIGRATED] <id>` per device, ending summary `Migrated: <count>` | Scales with M; expect roughly 1–3 minutes per 100 devices at typical Admin SDK latency, longer on a slow network — record actual time |
| 1.4 | `node verify-pass-a.js` | Read-only | `Expected private/sensitive subdocuments (M): <m>`, `Found: <m>`, `Mismatches: 0`, `Pass A verification PASSED.` Exit code 0. | Scales with M, similar order to 1.3 (it re-reads each migrated device) |
| 1.5 | Human review: spot-check a sample of at least 20 devices or 10% of M (whichever is larger) directly in the Firebase Console, per `MIGRATION_SUCCESS_CRITERIA.md` §3 | Read-only (manual) | For each sampled device: `private/sensitive` subdocument exists with the expected values; other fields on the parent document are visibly unchanged | 15–30 min depending on sample size |
| 1.6 | GO/NO-GO decision | N/A | Recorded decision | — |

**Downtime:** none. Pass A only adds a new subdocument at a path nothing in the currently-live app reads yet in a way that would conflict — the Phase 1B client code already reads sensitive data through the fallback-aware service, so newly-created subdocuments are picked up transparently. No user-facing behavior changes during this checkpoint.

**Stop conditions (pause before 1.6, do not proceed to Checkpoint 2):**
- `verify-pass-a.js` reports any mismatch count greater than 0 — **even a single document**. Per `MIGRATION_SUCCESS_CRITERIA.md` §4, this is a hard stop, not a "proceed with a note."
- `verify-pass-a.js`'s "Expected" and "Found" counts don't match.
- Any unhandled exception during 1.3 or 1.4.
- Human spot-check (1.5) finds even one discrepancy the automated verification didn't catch.

**Rollback trigger:** Pass A is non-destructive, so there is nothing to "roll back" in the data-loss sense — the parent documents are untouched. If a stop condition is triggered:
- The newly-created `private/sensitive` subdocuments are harmless to leave in place even if you decide not to proceed further right now (they simply sit unused).
- If you want to fully undo Pass A for a clean re-attempt, delete the specific `private/sensitive` subdocuments that were created in 1.3 — this is optional cleanup, not a safety requirement.
- Do not attempt to fix a mismatch by hand-editing a subdocument. Investigate the script/data root cause first (as happened during the Migration Rehearsal, where a real bug was found and fixed before Phase 1C was ever attempted against production).

**GO criteria (all must be true):**
- [ ] `verify-pass-a.js` exited 0 with `Mismatches: 0` and `Expected == Found`.
- [ ] Human spot-check sample found zero discrepancies.
- [ ] No unhandled errors during execution.

**NO-GO action:** stop. Do not run Pass B. Root-cause the failure. Re-running Pass A after a fix is safe (it skips already-migrated devices), but do not proceed to Checkpoint 2 until a clean Checkpoint 1 GO is achieved.

---

## Checkpoint 2 — Pass B, verification, GO/NO-GO

**This is the first destructive step in Phase 1C. Read this checkpoint twice before running 2.2.**

| Step | Command / Action | Read-only or writes | Expected output | Est. time |
|---|---|---|---|---|
| 2.1 | `node migrate-pass-b.js` (dry-run, no flag) | Read-only | Console: `Re-verifying Pass A before proceeding...`, `Expected: <m>, Found: <m>, Mismatches: 0`, then `[DRY-RUN] Would strip pin/patternLock/notesHidden from <id>` per device, summary `Would strip: <count>` | Similar order to Checkpoint 1's timing |
| 2.2 | `node migrate-pass-b.js --execute` | **Writes (destructive)** — removes `pin`/`patternLock`/`notesHidden` from the parent documents of every device that has them | Console: re-verification block (must show 0 mismatches — the script itself refuses to proceed otherwise, confirmed during the Migration Rehearsal with a deliberate negative test), then `[STRIPPED] <id>` per device, then `Document count unchanged (N = <n>). Run verify-pass-b.js next.` | Scales with M, similar order to Pass A's execute step |
| 2.3 | `node verify-pass-b.js` | Read-only | `Total maintenanceDevices documents: <n>` (must equal Checkpoint 0's N), `Documents with lingering sensitive fields: 0`, `Pass B verification PASSED.` Exit code 0. | Scales with N (full collection scan) |
| 2.4 | GO/NO-GO decision | N/A | Recorded decision | — |

**Downtime:** none expected, **conditional on the Prerequisite above being genuinely true**. If all active staff clients are running Phase 1B code, they already read sensitive data through the fallback-aware service and no longer read `pin`/`patternLock`/`notesHidden` from the parent document via the model at all — so removing those fields is invisible to them. If the Prerequisite does not hold, this step could cause a live client running old code to stop finding a device's PIN/pattern/notes, which is a functional regression for that session (not a full outage, but a real user-facing problem) — this is exactly why the Prerequisite is a hard gate above, not a suggestion.

**Stop conditions:**
- **2.2 will refuse to run on its own** if its internal re-verification of Pass A finds any mismatch — this is by design (confirmed working via a deliberate negative test during the Migration Rehearsal). If you see `Pass A verification failed. REFUSING to run Pass B.`, do not attempt to force it — treat this exactly like a Checkpoint 1 failure: stop, investigate, do not proceed.
- `migrate-pass-b.js --execute`'s own post-write count check reports a mismatch (`COUNT MISMATCH` error) — this indicates something wrote to `maintenanceDevices` outside the expected code paths during the operation. Stop immediately; this is a data-integrity concern broader than the migration itself.
- `verify-pass-b.js` (2.3) reports any lingering sensitive fields, or a document count different from N.

**Rollback trigger — this is the one checkpoint where "rollback" means a real data restoration, not just "stop":**
- Any stop condition above that is discovered **after** 2.2 has already run (i.e., not caught by 2.2's own internal checks, but found afterward by 2.3 or a later human observation) triggers restoration per `PRE_DEPLOYMENT_BACKUP_PLAN.md` §4:
  1. Prefer the **targeted restore** using the format B (JSON) backup from Checkpoint 0 — write the affected devices' `pin`/`patternLock`/`notesHidden` back onto their parent documents from the backup values. This was demonstrated working end-to-end during the Migration Rehearsal.
  2. Reserve a full `gcloud firestore import` (format A) for a worse scenario (broad, unexplained corruption) — a blind full-collection import risks reverting any legitimate device activity that happened after the backup was taken.
  3. After restoring, root-cause the original failure before re-attempting Pass B. Do not blindly retry.

**GO criteria (all must be true):**
- [ ] 2.2 completed without the internal re-verification refusing to run.
- [ ] 2.2's post-write document count check passed (no `COUNT MISMATCH`).
- [ ] `verify-pass-b.js` exited 0 with zero lingering fields and document count matching N.

**NO-GO action:** if caught before 2.2 (i.e., dry-run in 2.1 looked wrong): stop, do not execute, investigate. If caught after 2.2 has run: this is a **rollback trigger**, not just a NO-GO — follow the restoration procedure above before considering any further action. Do not proceed to Checkpoint 3 under any circumstances while Checkpoint 2 is in a failed or unresolved state.

---

## Checkpoint 3 — Firestore Rules deployment, Storage Rules deployment, verification

**Note:** the checkpoint outline provided didn't list an explicit GO/NO-GO line for this checkpoint, but this runbook applies one anyway, consistently with every other checkpoint — deploying access-control rules for the first time to a project that has never had any is exactly the kind of step that warrants one.

### Pre-flight (before 3.1)

- [ ] Confirm the `userId` + `receivedAt` composite index (needed for the live customer device-list query under the new rules' query-shape requirement) exists in the Firebase Console for the `technostore-v2` project. This has been an open, unverified question since the original Security Audit (`FIREBASE_COST_REVIEW.md` §3) — confirm it directly in the Console before deploying rules, since a missing index combined with the new rules could surface as customers being unable to load their device list.
- [ ] Copy `docs/ai-workflow/drafts/firestore.rules.draft` to `firestore.rules` at the repo root, and `docs/ai-workflow/drafts/storage.rules.draft` to `storage.rules` at the repo root.
- [ ] Update `firebase.json` to reference both — currently it has no `firestore` or `storage` key at all (confirmed absent). Add:
  ```json
  "firestore": { "rules": "firestore.rules" },
  "storage": { "rules": "storage.rules" }
  ```
- [ ] Run the pre-deploy checklist from `PHASE1_IMPLEMENTATION_PLAN.md` §6 against the Firestore Emulator Suite (or an equivalent validated approach — see the Migration Rehearsal's note on this environment's emulator limitations) one more time against the **final** rules files, not just the drafts as originally written.

| Step | Command / Action | Read-only or writes | Expected output | Est. time |
|---|---|---|---|---|
| 3.1 | `firebase deploy --only firestore:rules` | **Config change** — no document data touched | CLI reports successful rules deployment; new rules version visible in Firebase Console → Firestore → Rules | 1–3 min |
| 3.2 | `firebase deploy --only storage` | **Config change** — no file data touched | CLI reports successful rules deployment; new rules version visible in Firebase Console → Storage → Rules | 1–3 min |
| 3.3 | Verification — run the rules-specific checks from `PHASE1_IMPLEMENTATION_PLAN.md` §6's post-deploy checklist: customer device list still loads; customer cannot read `private/sensitive` (direct token attempt); staff can still read/write as before; a direct client write attempting to change `type` on `users/{uid}` is denied | Read-only (observational + a few explicit negative-test attempts) | All checks pass as described in §6 | 20–30 min |
| 3.4 | GO/NO-GO decision | N/A | Recorded decision | — |

**Downtime:** no full outage expected. Rules deployment takes effect within seconds to a couple of minutes and does not require an app restart. However, there is a real (not zero) risk window where a specific flow could start erroring for real users if something is misconfigured — most notably the customer device-list query-shape risk already flagged in `PHASE1_IMPLEMENTATION_PLAN.md` §2/§6. **Recommend deploying during a lower-traffic window** as a mitigation, even though this isn't a full-downtime operation.

**Stop conditions:**
- The pre-flight composite-index check cannot be confirmed.
- The emulator (or equivalent) validation pass in the pre-flight finds any denial that shouldn't happen or any grant that shouldn't happen.

**Rollback trigger:** if 3.3's verification finds ANY of the following, roll back immediately:
- A customer cannot load their own device list (query-shape or index problem).
- A customer, via any path, can read sensitive data (`private/sensitive`) — this is the single least acceptable outcome possible in this entire phase.
- Staff cannot read/write devices they should be able to.
- A direct client write can still change `type` on a `users/{uid}` document.

**Rollback action:** Firebase retains rules version history — reverting to the immediately-prior version (no rules at all, the pre-Phase-1C state) is a single action in the Firebase Console ("restore previous version") or `firebase deploy --only firestore:rules,storage` with the prior rules file restored locally. This is fast (seconds to a couple of minutes) and should be the **first** response to any unexpected denial or grant found in 3.3 — diagnose after reverting, not before, given the migration data underneath is unaffected by a rules rollback (rules and data are independent layers).

**GO criteria (all must be true):**
- [ ] Both rules deployments (3.1, 3.2) reported success.
- [ ] Every check in 3.3 passed, with zero exceptions — this is not a "mostly passing" situation given what's at stake (customer PIN/pattern/notes exposure is the specific risk this entire Phase 1 effort exists to close).

**NO-GO / rollback action:** revert rules to the prior version immediately if any 3.3 check fails. Do not proceed to Checkpoint 4 with a partially-passing Checkpoint 3.

---

## Checkpoint 4 — Post-deployment validation, customer validation, staff validation, final sign-off

| Step | Command / Action | Read-only or writes | Expected output | Est. time |
|---|---|---|---|---|
| 4.1 | Post-deployment validation — full checklist from `PHASE1_IMPLEMENTATION_PLAN.md` §6's post-deploy section (beyond the rules-specific subset already covered in 3.3): device creation/update/delete works for staff; cascade delete removes Storage images + subdocument + parent doc together; new customer signup works; migrated data spot-check against the Checkpoint 0/1 backup; no unexpected Firestore read-cost spike; the product owner's manual Console-based activation workflow still works | Read-only observation + **writes (test data only)** if exercising create/delete flows — see note below | All items pass | 30–45 min |
| 4.2 | Customer validation — from a real or dedicated test customer account: confirm device list loads, confirm no PIN/pattern/notes visible anywhere, confirm status/price/model display normally | Read-only | All confirmed | 10–15 min |
| 4.3 | Staff validation — from Admin, Reception, and Maintenance test accounts: confirm full device list loads, confirm PIN/pattern/notes visible, confirm create/update/delete all work, confirm the delete confirmation dialog shows correct customer/device details, confirm the manual-Console activation toggle still works as expected | Read-only + **writes (test data only)** | All confirmed | 20–30 min |
| 4.4 | Final sign-off | N/A | Product owner formally records Phase 1C as complete | — |

**Important note on 4.1/4.3:** if you exercise the create/update/delete flow as part of validation, **do this against a dedicated test device record, never a real customer's device** — cascade delete is irreversible (Storage images + sensitive subdocument + parent document all removed together, by design). Create a throwaway test device specifically for this validation step, and delete that one, not any real production record.

**Downtime:** none — this checkpoint is validation only.

**Stop conditions:** any check in 4.1–4.3 fails.

**Rollback trigger:** Checkpoint 4 does not introduce any new destructive action of its own, so there is no new rollback mechanism here. A failure discovered at this stage means invoking whichever earlier checkpoint's rollback is actually implicated:
- A rules-related failure (customer sees sensitive data, staff denied access, etc.) → Checkpoint 3's rollback (revert rules).
- A data-integrity failure (missing/wrong sensitive data, wrong document count) → Checkpoint 2's rollback (restore from backup).
- A cascade-delete failure (orphaned Storage files, orphaned subdocument) → not a rollback scenario per se; retry the delete (idempotent by design) and confirm it completes cleanly.

**GO criteria (all must be true) — this is the final sign-off, not just another checkpoint:**
- [ ] All of 4.1, 4.2, 4.3 passed with zero unresolved issues.
- [ ] No rollback was triggered at this checkpoint.
- [ ] Product owner explicitly signs off.

**NO-GO action:** do not consider Phase 1 complete. Route the failure to the appropriate earlier checkpoint's rollback procedure, resolve it, and re-run the relevant validation before signing off.

---

## Execution log template

Fill this in during the actual run — this is a record, not a plan.

```
Checkpoint 0: date/time _____  N=____  M=____  GO / NO-GO: ____  notes: _____
Checkpoint 1: date/time _____  execute duration=____  mismatches=____  GO / NO-GO: ____  notes: _____
Checkpoint 2: date/time _____  execute duration=____  lingering=____  GO / NO-GO: ____  notes: _____
Checkpoint 3: date/time _____  rules deployed=____  verification result=____  GO / NO-GO: ____  notes: _____
Checkpoint 4: date/time _____  validation result=____  FINAL SIGN-OFF: ____  notes: _____
```
