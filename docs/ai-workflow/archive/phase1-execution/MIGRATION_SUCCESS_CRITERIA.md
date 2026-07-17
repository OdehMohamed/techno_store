# MIGRATION_SUCCESS_CRITERIA.md

> - **Archived:** 2026-07-17
> - **Historical reference only.**
> - Reflects the project's state before the Phase 1 remediation work was completed. This document's own "Status" line below (written 2026-07-03) predates execution — every check below passed against production; see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md`.
> - **Must not be treated as the current source of truth.** For current information, see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` (what shipped) and `docs/ai-workflow/DECISIONS_LOG.md` (the full decision record). Retained as historical reference documentation — parts of it may be useful when planning a future migration or deployment, but it should not be treated as a current or authoritative migration procedure.

**Status:** Planning artifact, required before Phase 1 implementation begins per product-owner approval (2026-07-03). **Not yet executed.**
**Scope:** the sensitive-data migration described in `PHASE1_IMPLEMENTATION_PLAN.md` §4 (Pass A copy → verify → Pass B strip) and its backup in `PRE_DEPLOYMENT_BACKUP_PLAN.md`.

**Important honesty note on "expected document counts":** this review has no access to the live production database, so it cannot state actual numbers (e.g., "there are 340 devices"). What follows instead defines the **counts that must be captured at execution time** and the **invariant relationships between them** that constitute success — the criteria are measurable and precise, but the baseline values themselves are only known once the Inventory step actually runs against production. Do not substitute an assumed or estimated number for an actual captured count.

## 1. Baseline counts to capture (before touching anything)

Run these against production as part of the Inventory step (`PHASE1_IMPLEMENTATION_PLAN.md` §4, step 1), and record the results — they are the fixed reference point every later check compares against:

- **N** = total document count in `maintenanceDevices`.
- **M** = count of `maintenanceDevices` documents where at least one of `pin`, `patternLock`, `notesHidden` is non-null/non-empty. (M ≤ N.) This is the number of `private/sensitive` subdocuments Pass A is expected to create — devices with none of the three fields set should **not** get an empty placeholder subdocument, consistent with not adding structure that isn't needed.

Recommend computing M via a full collection read with client-side filtering in the same Admin SDK script used for the JSON backup dump, rather than composing an `OR` query — simpler, and adequate at this app's scale (a small business's device records, not a high-volume collection).

## 2. Measurable validation checks, in execution order

| # | Check | Method | Pass condition |
|---|---|---|---|
| 1 | Pre-migration inventory captured | Full scan of `maintenanceDevices`, count total (N) and sensitive-field-present (M) | N and M recorded and sanity-checked (e.g., M ≤ N, both non-negative) before Pass A begins |
| 2 | Pass A subdocument count | Count `private/sensitive` documents created across all devices | Equals **exactly M** — not more, not less |
| 3 | Pass A field-level accuracy | For every one of the M devices, diff the new `private/sensitive` document's `pin`/`patternLock`/`notesHidden` against the pre-migration JSON backup's values for that same device | **100% exact match** for all three fields, for all M devices — zero tolerated mismatches |
| 4 | Pass A non-interference | For a sample of parent documents (see §3), confirm every field *other than* the three sensitive ones is byte-for-byte unchanged from the backup | No unrelated field was touched, added, or dropped |
| 5 | Pass B strip completeness | Query `maintenanceDevices` for any document where `pin`, `patternLock`, or `notesHidden` is still present/non-null | **Zero** matching documents |
| 6 | Total document count invariant | Count `maintenanceDevices` after the full migration | Equals **exactly N** — migration must never add, remove, or duplicate a parent document, only modify fields on existing ones |
| 7 | Functional read-path check | In a staging/test session (or emulator), open the device details screen as a staff account for a migrated device, and as the owning customer | Staff sees PIN/pattern lock/notes correctly, sourced from the new location; customer sees none of the three, and all other fields (status, price, model) render normally |

## 3. Verification sampling

In addition to the exhaustive checks above (2, 3, 5, 6, which cover every document, not a sample — this dataset is expected to be small enough that 100% coverage is feasible and is what's required, not spot-checking alone), perform a **manual, human-eyes** spot-check in the Firebase Console on a sample of at least **20 documents, or 10% of M, whichever is larger** — this exists to catch a bug in the *automated verification script itself*, not just the migration. For each sampled document, confirm by eye: the parent document no longer shows the three fields, the `private/sensitive` subdocument exists with the expected values, and unrelated fields (status, price, receivedByEmployee, etc.) look untouched.

## 4. Failure criteria — when to stop

Any of the following is a **hard stop**, not a "proceed with a note":

- Check 2 fails (subdocument count ≠ M) → **do not proceed to Pass B.** Investigate before continuing.
- Check 3 fails for even a single document (any field-level mismatch) → **do not proceed to Pass B**, even if every other document passed. This is customer-sensitive data (device PINs, pattern locks); "mostly correct" is not an acceptable outcome. Investigate that specific document before continuing.
- Check 4 fails (an unrelated field was altered) → stop and investigate; this indicates a bug in the migration script's write logic that could be actively corrupting data, not just a migration-scope issue.
- Check 6 fails at any point (parent document count changed) → stop immediately; this means the script did something outside its intended scope (created or deleted parent documents), which is a serious signal something is wrong with the script itself, not just this run.
- Any unhandled exception during Pass A or Pass B → stop and investigate. Given the expected dataset size for a small business's device records, there is no "acceptable error rate" to tolerate here — any unhandled error risks exactly the kind of silent partial completion this whole verification process exists to catch.
- Check 5 fails after Pass B (any lingering sensitive field on a parent document) → **do not deploy the Firestore/Storage rules yet.** The rules deployment assumes the schema migration is complete; deploying against an incompletely-migrated dataset breaks the sequencing established in `PHASE1_IMPLEMENTATION_PLAN.md` §7, even though the specific rules drafted don't directly re-expose the lingering fields to a new audience.

## 5. Rollback triggers

Conditions that trigger the rollback procedure in `PHASE1_IMPLEMENTATION_PLAN.md` §8 / `PRE_DEPLOYMENT_BACKUP_PLAN.md` §4, rather than a simple "fix and retry":

- Any failure criterion above is discovered **after Pass B has already run** (i.e., not caught by the pre-Pass-B checks, but found afterward) — triggers the targeted-restore procedure in `PRE_DEPLOYMENT_BACKUP_PLAN.md` §4 using the JSON backup.
- Post-rules-deployment, the manual verification checklist (`PHASE1_IMPLEMENTATION_PLAN.md` §6) reveals staff cannot read sensitive data for devices that were supposedly successfully migrated — triggers a rules rollback first (fast, per §8), then an investigation into whether the migration was actually complete before re-attempting rules deployment.
- Post-rules-deployment, any customer reports an error loading their own device list (the query-shape compatibility risk flagged in §2/§6) — triggers an immediate rules rollback; this is a customer-facing regression, not something to leave live while investigating.
- Discovery, at any point, that the total parent-document count (check 6) no longer matches N, even after the migration was believed complete and rules were already deployed — triggers a full incident review: this indicates something wrote to `maintenanceDevices` outside the expected code paths during the migration window, which is a data-integrity concern broader than the migration itself.
