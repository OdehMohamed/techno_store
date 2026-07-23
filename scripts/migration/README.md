# Migration Scripts

Plain Node.js Admin SDK scripts for one-off production data migrations — **not part of the Flutter app**; nothing under `lib/` imports or depends on anything here. Two independent migrations currently live in this directory, sharing only `lib/admin.js` and the setup steps below:

1. **Phase 1C sensitive-data split** — prepared during Phase 1B, **NOT executed** as of this writing.
2. **ADR-005 device lifecycle `recordState` backfill** — required before the client-side Archive/Restore/Permanent Delete cutover (`ADR-005`'s "PR 2") ships.

## Before running anything (either migration)

1. Authenticate via Application Default Credentials (ADC) — pick one:
   - **Recommended:** `gcloud auth application-default login`, signing in with an account that has Firestore access to `technostore-v2`. No key file is created or stored anywhere. Verify you're on the right account with `gcloud auth list` before running anything.
   - Or, if a service account key file already exists for this purpose: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json`. **Never commit that file or any credentials to this repo.**
   Either way, the scripts always target the `technostore-v2` project explicitly (see `lib/admin.js`) — they don't rely on whatever your ambient gcloud default project happens to be.
2. `npm install` in this directory.

## Phase 1C: Sensitive-Data Split

**Status: prepared during Phase 1B, NOT executed.** Implements the migration described in `docs/ai-workflow/PHASE1_IMPLEMENTATION_PLAN.md` §4, validated against `docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md`.

### Order of operations

1. Read `docs/ai-workflow/PRE_DEPLOYMENT_BACKUP_PLAN.md` and `docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md` in full.
2. `npm run inventory` — read-only. Records N (total devices) and M (devices with sensitive data). **Always run this first.**
3. Take the managed Firestore export (backup format A) via the `gcloud` CLI per `PRE_DEPLOYMENT_BACKUP_PLAN.md` §2 — **not scripted here**, run it directly:
   ```
   gcloud firestore export gs://<backup-bucket>/firestore/<timestamp>/ \
     --collection-ids=maintenanceDevices,users --project=technostore-v2
   ```
4. `npm run backup` — writes a local JSON dump (backup format B) to `backups/<timestamp>/`. Upload this directory to the backup GCS bucket per `PRE_DEPLOYMENT_BACKUP_PLAN.md` §3. **Do not proceed past this step without both backups in place.**
5. `npm run migrate:a` — dry-run by default (prints intended writes, writes nothing). Review the output, then run `node migrate-pass-a.js --execute` to actually create the `private/sensitive` subdocuments. Non-destructive — never touches the parent documents.
6. `npm run verify:a` — read-only. Must report **zero mismatches** before proceeding. If it fails, stop and investigate per `MIGRATION_SUCCESS_CRITERIA.md` §4 — do not continue to step 7.
7. `npm run migrate:b` — dry-run by default. **This step is destructive**: it removes `pin`/`patternLock`/`notesHidden` from the parent documents. It re-runs Pass A's verification itself immediately before writing and refuses to execute if that fails. Run `node migrate-pass-b.js --execute` only after reviewing the dry-run output and confirming the backups from step 4 are in place.
8. `npm run verify:b` — read-only. Confirms zero lingering sensitive fields and that the total document count matches step 2's N.

Only after step 8 passes should Firestore/Storage rules be deployed (a separate step, per `PHASE1_IMPLEMENTATION_PLAN.md` §7 — not part of this directory at all).

### If something goes wrong

See `PRE_DEPLOYMENT_BACKUP_PLAN.md` §4 (restoration procedure) and `PHASE1_IMPLEMENTATION_PLAN.md` §8 (rollback order). Prefer the targeted restore (using the JSON backup from step 4) over a full `gcloud firestore import` — see the backup plan's rationale for why a blind full import risks reverting legitimate data created after the backup.

### What this does NOT do

- Does not deploy Firestore or Storage rules.
- Does not touch Storage/images.
- Does not touch the dormant `users/{uid}/devices` subcollection (separate, pre-existing backlog item).
- Does not check that a backup exists before Pass B — that verification is the operator's responsibility.

## ADR-005: Device Lifecycle `recordState` Backfill

**Status: written and tested (dry-run), NOT yet executed against production.** Backfills `recordState: 'active'` onto every `maintenanceDevices` document — see `docs/ai-workflow/ADR-005-device-lifecycle-archive-deletion.md` ("Migration") for the full rationale. Independent of the Phase 1C migration above; does not touch `pin`/`patternLock`/`notesHidden`/Storage/`private/sensitive` at all.

**Run this as part of final cutover, after the client-side vertical slice (ADR-005's "PR 2") is implemented, reviewed, and live-verified against production — not as a step between PR 1 and PR 2.** PR 2's new-device-creation path sets `recordState` explicitly, so live verification of Archive/Restore/Permanent Delete doesn't depend on this backfill having run yet; pre-existing devices are just expected to be temporarily absent from the tabs during that verification window.

### Order of operations

1. Confirm PR 2 has been implemented, reviewed, and live-verified per the sequence above.
2. Take a fresh backup — both the managed `gcloud firestore export` (format A, see step 3 in the Phase 1C section above, adjusted to `--collection-ids=maintenanceDevices`) and `npm run backup` (format B). Do not skip this because Phase 1C's old backups exist; those predate this data.
3. Get explicit product-owner approval to proceed — this writes to every real customer device record.
4. `npm run migrate:recordstate` — dry-run by default (prints intended writes, writes nothing). Review the output, then run `node migrate-recordstate.js --execute` to actually write. Idempotent: documents that already have a `recordState` field (from a prior partial run) are skipped, not overwritten.
5. `npm run verify:recordstate` — read-only. Must report **zero documents missing recordState**. If it fails, do not proceed — investigate and re-run step 4.
6. Merge PR 2 to `main`, closing out the vertical slice.

### What this does NOT do

- Does not deploy Firestore or Storage rules (see `ADR-005`'s own rollout PRs for that).
- Does not touch Storage/images, `private/sensitive`, or any field other than `recordState`.
- Does not set `recordState` to anything other than `'active'` — no device is archived by this script.
