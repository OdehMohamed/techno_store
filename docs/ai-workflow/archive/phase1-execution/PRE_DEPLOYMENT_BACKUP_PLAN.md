# PRE_DEPLOYMENT_BACKUP_PLAN.md

> - **Archived:** 2026-07-17
> - **Historical reference only.**
> - Reflects the project's state before the Phase 1 remediation work was completed. This plan's own "Status" line below (written 2026-07-03) predates execution — the backup was taken and the migration it protected has since completed and been verified; see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md`.
> - **Must not be treated as the current source of truth.** For current information, see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` (what shipped) and `docs/ai-workflow/DECISIONS_LOG.md` (the full decision record). Retained as historical reference documentation — parts of it may be useful when planning a future migration or deployment, but it should not be treated as a current or authoritative migration procedure.

**Status:** Planning artifact, required before Phase 1 implementation begins per product-owner approval (2026-07-03). **Not yet executed.**
**Scope:** data backups only. Firestore/Storage **security rules** have their own, already-adequate rollback mechanism — Firebase retains rules version history natively, and reverting to the prior (no-rules) version is a single deploy action, already documented in `PHASE1_IMPLEMENTATION_PLAN.md` §8. This document does not duplicate that; it covers **data**, which has no equivalent built-in undo.

This backup must be taken **once, immediately before Migration Pass A begins** (`PHASE1_IMPLEMENTATION_PLAN.md` §4, step 2). No second backup is needed between Pass A and Pass B — Pass A is additive only (it copies data into the new subcollection but changes nothing on the parent documents), so the single pre-Pass-A backup remains a valid "before we touched anything" checkpoint all the way through Pass B, which is the only destructive step.

## 1. Exactly what will be backed up

| Item | Why | Priority |
|---|---|---|
| **Full `maintenanceDevices` collection** (every document, every field) | The only collection undergoing a **destructive** change — Pass B permanently removes `pin`, `patternLock`, `notesHidden` from every parent document. This is the backup that actually matters for migration safety. | **Critical** |
| **Full `users` collection** | Not touched destructively by this migration, but bundled in as near-zero-cost insurance given rules are being deployed against it in the same window. | Secondary |
| **Storage objects under `maintenance_devices/`** (and, for completeness, `profiles_photos/`) | Not touched by the *migration* at all — but this phase also ships new cascade-delete code (`deleteDevice` now deletes Storage files). A bug in that newly-shipped code during the rollout window is a plausible failure mode a backup can protect against, distinct from the migration itself. | Defense-in-depth, not migration-critical |

**Explicitly not backed up, with reasoning:** the `users/{uid}/devices` subcollection (confirmed in the original audit to have no code path writing to it — believed empty; if a stray manually-created test document exists there, it is out of Phase 1's scope regardless) and the retail-catalog collections (`products`/`categories` — confirmed to have no live data or write path in this codebase today).

## 2. How the backup will be taken

Two formats, for two different purposes — both required, not either/or:

**A. Managed Firestore export (authoritative, for full restoration):**
```
gcloud firestore export gs://<backup-bucket>/firestore/<timestamp>/ \
  --collection-ids=maintenanceDevices,users \
  --project=technostore-v2
```
This is Google's native point-in-time-consistent export mechanism. It's the authoritative artifact for a full restore (via `gcloud firestore import`), and doesn't require any custom scripting to produce or trust.

**B. Human-readable JSON dump (secondary, for targeted restoration and diffing):**
An Admin SDK script (the same trusted-operator tooling already planned for the migration itself — not shipped in the Flutter app) reads every document in `maintenanceDevices` and `users` and writes them to timestamped JSON files. This is **not** a replacement for the managed export — it exists because a full `gcloud firestore import` restore is a blunt instrument (see §4), and having a precise, field-level JSON copy enables a much safer *targeted* restoration of just the three sensitive fields on just the affected documents, without disturbing any legitimate data written after the backup was taken. This JSON dump is also exactly the source of truth the migration's own "Pass A verification step" (`PHASE1_IMPLEMENTATION_PLAN.md` §4) should diff against, and what `MIGRATION_SUCCESS_CRITERIA.md`'s verification queries reference.

**C. Storage snapshot (defense-in-depth):**
```
gsutil -m rsync -r gs://<live-bucket>/maintenance_devices gs://<backup-bucket>/storage-snapshot/<timestamp>/maintenance_devices
gsutil -m rsync -r gs://<live-bucket>/profiles_photos gs://<backup-bucket>/storage-snapshot/<timestamp>/profiles_photos
```
A straightforward copy, not a live sync — taken once, at the same time as the Firestore backup, before any rules or cascade-delete code goes live in production.

**Recommended practice, not optional:** before relying on any of this in a real incident, **test the restoration procedure once against a non-production Firebase project** (or the Firestore Emulator) using a small sample export — confirm the import/restore mechanics actually work as expected. A backup that has never been test-restored is an assumption, not a safety net.

## 3. Where it will be stored

- A **dedicated GCS backup bucket**, separate from the live Storage bucket (e.g. `gs://technostore-v2-phase1-backups/`) — not a folder inside the live bucket, so that an errant recursive delete against the live bucket cannot also reach the backup copy.
- IAM access to this bucket restricted to the trusted operator(s) performing the migration — not exposed to the app, not broadly readable.
- Layout:
  - `gs://technostore-v2-phase1-backups/firestore-export/<timestamp>/` — the managed export (format A).
  - `gs://technostore-v2-phase1-backups/firestore-json/<timestamp>/maintenanceDevices.json`, `.../users.json` — the JSON dump (format B).
  - `gs://technostore-v2-phase1-backups/storage-snapshot/<timestamp>/` — the Storage copy (format C).
- **Retention:** this specific pre-migration backup should be retained indefinitely, or at minimum for a defined grace period (recommend 90 days past the point the migration and rules rollout are confirmed stable) — it must not be subject to any generic short-retention lifecycle policy that might otherwise apply to routine backups, since it is currently the *only* recovery path for the one truly destructive step in this phase (Pass B).

## 4. Restoration procedure

**If Pass B has not yet run:** there is nothing to restore — the original fields are still untouched on the parent documents. The correct response to a problem at this stage is to stop the migration and revert client code, per `PHASE1_IMPLEMENTATION_PLAN.md` §8, not a data restore.

**If Pass B has already run and a problem is discovered**, in order of preference:

1. **Targeted restore (preferred, lower-risk):** using the JSON dump (format B) as the source, write a script that, for each affected `deviceId`, sets `pin`, `patternLock`, `notesHidden` back onto the parent document from the backup values, and/or corrects the corresponding `private/sensitive` subdocument if that's what's wrong. This only touches the three sensitive fields on the specific documents affected — it cannot clobber any device created or legitimately updated after the backup was taken, which is the main risk of the alternative below.
2. **Full managed import (last resort, higher-risk):** `gcloud firestore import gs://<backup-bucket>/firestore-export/<timestamp>/` restores the exported collections from that point in time. **Caution, to be verified against current GCP documentation and a test run before relying on it in a real incident:** a Firestore import restores documents as they existed at export time; it should not be assumed to intelligently merge with data written after the backup. If any `maintenanceDevices` documents were created or legitimately updated between the backup and the restore, a full-collection import risks reverting or conflicting with that newer, legitimate data. This is why the targeted restore above is the preferred path for the realistic failure mode (a bug in Pass B affecting the three sensitive fields specifically) — full import is reserved for a worse scenario (e.g., broad data corruption unrelated to the specific fields).
3. **Storage restore**, if a cascade-delete bug incorrectly removed images: `gsutil cp`/`rsync` the affected `deviceId` folder(s) back from `storage-snapshot/<timestamp>/` to their original live paths.
4. After any restore, **root-cause the original failure before re-attempting migration** — do not blindly re-run Pass A/Pass B without understanding why the first attempt produced an inconsistent result; re-running against an already-partially-migrated or since-restored dataset without understanding the failure mode risks repeating it.

**Who performs this:** the same trusted operator role established throughout this plan (Admin SDK / `gcloud` CLI access) — never the app itself, and never a client-facing feature.
