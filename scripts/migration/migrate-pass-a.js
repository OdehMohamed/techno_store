#!/usr/bin/env node
/**
 * Migration Pass A (copy): for every maintenanceDevices document with any
 * sensitive field set, writes those fields into the new
 * maintenanceDevices/{id}/private/sensitive subdocument. Does NOT modify
 * the parent document — stripping it is Pass B, a separate, later,
 * destructive step.
 *
 * SAFETY: defaults to dry-run (prints what it would do, writes nothing).
 * Pass --execute to actually write.
 *
 * Run inventory.js and backup.js FIRST. See
 * docs/ai-workflow/PHASE1_IMPLEMENTATION_PLAN.md §4 and
 * docs/ai-workflow/PRE_DEPLOYMENT_BACKUP_PLAN.md before running this with
 * --execute.
 */
const { initAdmin } = require('./lib/admin');
const { hasSensitiveData, extractSensitiveData } = require('./lib/sensitive_data');

async function main() {
  const execute = process.argv.includes('--execute');
  const admin = initAdmin();
  const db = admin.firestore();

  const snapshot = await db.collection('maintenanceDevices').get();

  let toMigrate = 0;
  let migrated = 0;
  let skippedAlreadyMigrated = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!hasSensitiveData(data)) continue;
    toMigrate += 1;

    const sensitiveRef = doc.ref.collection('private').doc('sensitive');
    const existing = await sensitiveRef.get();
    if (existing.exists) {
      skippedAlreadyMigrated += 1;
      console.log(`[SKIP] ${doc.id}: private/sensitive already exists`);
      continue;
    }

    const sensitiveData = extractSensitiveData(data);
    if (execute) {
      await sensitiveRef.set(sensitiveData);
      console.log(`[MIGRATED] ${doc.id}`);
    } else {
      console.log(`[DRY-RUN] Would write ${doc.id}/private/sensitive =`, sensitiveData);
    }
    migrated += 1;
  }

  console.log('');
  console.log(`Mode: ${execute ? 'EXECUTE' : 'DRY-RUN (pass --execute to write)'}`);
  console.log(`Devices with sensitive data (M): ${toMigrate}`);
  console.log(`${execute ? 'Migrated' : 'Would migrate'}: ${migrated}`);
  console.log(`Already migrated (skipped): ${skippedAlreadyMigrated}`);
  console.log('');
  console.log('Next: run verify-pass-a.js and confirm zero mismatches before');
  console.log('running migrate-pass-b.js.');
}

main().catch((err) => {
  console.error('Pass A failed:', err);
  process.exit(1);
});
