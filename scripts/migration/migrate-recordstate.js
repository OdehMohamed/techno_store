#!/usr/bin/env node
/**
 * Device Lifecycle migration (ADR-005): backfills `recordState: 'active'`
 * onto every maintenanceDevices document that doesn't already have a
 * recordState field. Required before the client ships any query filtering
 * on recordState — Firestore equality filters don't match documents where
 * the field is entirely absent, so without this backfill every existing
 * device would silently vanish from all three staff tabs (and the
 * customer's own view) the moment the new query code ships.
 *
 * SAFETY: defaults to dry-run (prints what it would do, writes nothing).
 * Pass --execute to actually write. Idempotent — already-migrated documents
 * (recordState already present, any value) are skipped, so this is safe to
 * re-run.
 *
 * Independent of the Phase 1C sensitive-data migration scripts in this same
 * directory — shares only lib/admin.js. Take a fresh backup (see backup.js
 * and docs/ai-workflow/PRE_DEPLOYMENT_BACKUP_PLAN.md) and get explicit
 * product-owner approval before running with --execute against production.
 * See docs/ai-workflow/ADR-005-device-lifecycle-archive-deletion.md
 * "Migration".
 */
const { initAdmin } = require('./lib/admin');

async function main() {
  const execute = process.argv.includes('--execute');
  const admin = initAdmin();
  const db = admin.firestore();

  const snapshot = await db.collection('maintenanceDevices').get();

  let total = 0;
  let toMigrate = 0;
  let migrated = 0;
  let alreadyMigrated = 0;

  const batchSize = 400; // Firestore batch limit is 500; stay well under it.
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    total += 1;
    const data = doc.data();
    if (Object.prototype.hasOwnProperty.call(data, 'recordState')) {
      alreadyMigrated += 1;
      continue;
    }
    toMigrate += 1;

    if (execute) {
      batch.update(doc.ref, { recordState: 'active' });
      batchCount += 1;
      if (batchCount >= batchSize) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
      console.log(`[MIGRATED] ${doc.id}`);
    } else {
      console.log(`[DRY-RUN] Would set ${doc.id}.recordState = 'active'`);
    }
    migrated += 1;
  }

  if (execute && batchCount > 0) {
    await batch.commit();
  }

  console.log('');
  console.log(`Mode: ${execute ? 'EXECUTE' : 'DRY-RUN (pass --execute to write)'}`);
  console.log(`Total maintenanceDevices documents: ${total}`);
  console.log(`Already had recordState (skipped): ${alreadyMigrated}`);
  console.log(`Missing recordState: ${toMigrate}`);
  console.log(`${execute ? 'Migrated' : 'Would migrate'}: ${migrated}`);
  console.log('');
  console.log('Next: run verify-recordstate.js and confirm zero documents');
  console.log('missing recordState before deploying any client code that');
  console.log('queries on it.');
}

main().catch((err) => {
  console.error('recordState migration failed:', err);
  process.exit(1);
});
