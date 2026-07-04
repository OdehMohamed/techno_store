# Phase 1C Migration Scripts

**Status: prepared during Phase 1B, NOT executed.** These implement the migration described in `docs/ai-workflow/PHASE1_IMPLEMENTATION_PLAN.md` §4, validated against `docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md`. They are plain Node.js — **not part of the Flutter app**; nothing under `lib/` imports or depends on anything here.

## Before running anything

1. Read `docs/ai-workflow/PRE_DEPLOYMENT_BACKUP_PLAN.md` and `docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md` in full.
2. Authenticate via Application Default Credentials (ADC) — pick one:
   - **Recommended:** `gcloud auth application-default login`, signing in with an account that has Firestore access to `technostore-v2`. No key file is created or stored anywhere. Verify you're on the right account with `gcloud auth list` before running anything.
   - Or, if a service account key file already exists for this purpose: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json`. **Never commit that file or any credentials to this repo.**
   Either way, the scripts always target the `technostore-v2` project explicitly (see `lib/admin.js`) — they don't rely on whatever your ambient gcloud default project happens to be.
3. `npm install` in this directory.

## Order of operations

1. `npm run inventory` — read-only. Records N (total devices) and M (devices with sensitive data). **Always run this first.**
2. Take the managed Firestore export (backup format A) via the `gcloud` CLI per `PRE_DEPLOYMENT_BACKUP_PLAN.md` §2 — **not scripted here**, run it directly:
   ```
   gcloud firestore export gs://<backup-bucket>/firestore/<timestamp>/ \
     --collection-ids=maintenanceDevices,users --project=technostore-v2
   ```
3. `npm run backup` — writes a local JSON dump (backup format B) to `backups/<timestamp>/`. Upload this directory to the backup GCS bucket per `PRE_DEPLOYMENT_BACKUP_PLAN.md` §3. **Do not proceed past this step without both backups in place.**
4. `npm run migrate:a` — dry-run by default (prints intended writes, writes nothing). Review the output, then run `node migrate-pass-a.js --execute` to actually create the `private/sensitive` subdocuments. Non-destructive — never touches the parent documents.
5. `npm run verify:a` — read-only. Must report **zero mismatches** before proceeding. If it fails, stop and investigate per `MIGRATION_SUCCESS_CRITERIA.md` §4 — do not continue to step 6.
6. `npm run migrate:b` — dry-run by default. **This step is destructive**: it removes `pin`/`patternLock`/`notesHidden` from the parent documents. It re-runs Pass A's verification itself immediately before writing and refuses to execute if that fails. Run `node migrate-pass-b.js --execute` only after reviewing the dry-run output and confirming the backups from step 3 are in place.
7. `npm run verify:b` — read-only. Confirms zero lingering sensitive fields and that the total document count matches step 1's N.

Only after step 7 passes should Firestore/Storage rules be deployed (a separate step, per `PHASE1_IMPLEMENTATION_PLAN.md` §7 — not part of this directory at all).

## If something goes wrong

See `PRE_DEPLOYMENT_BACKUP_PLAN.md` §4 (restoration procedure) and `PHASE1_IMPLEMENTATION_PLAN.md` §8 (rollback order). Prefer the targeted restore (using the JSON backup from step 3) over a full `gcloud firestore import` — see the backup plan's rationale for why a blind full import risks reverting legitimate data created after the backup.

## What this does NOT do

- Does not deploy Firestore or Storage rules.
- Does not touch Storage/images.
- Does not touch the dormant `users/{uid}/devices` subcollection (separate, pre-existing backlog item).
- Does not check that a backup exists before Pass B — that verification is the operator's responsibility.
