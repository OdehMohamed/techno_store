#!/usr/bin/env node
/**
 * Migration Pass B (strip): removes pin, patternLock, notesHidden from
 * every maintenanceDevices parent document, now that Pass A has copied
 * them to the private/sensitive subdocument.
 *
 * THIS STEP IS DESTRUCTIVE. Do not run --execute without a verified
 * backup — see docs/ai-workflow/PRE_DEPLOYMENT_BACKUP_PLAN.md.
 *
 * SAFETY:
 *  - Defaults to dry-run. Pass --execute to actually write.
 *  - Refuses to run in --execute mode unless Pass A's verification passes
 *    again, right here, immediately before writing — this script does not
 *    trust that verify-pass-a.js was run earlier and still holds true.
 *  - Confirms the total document count is unchanged after stripping, per
 *    docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md check 6.
 *  - Does NOT check that a backup exists — that is the operator's
 *    responsibility per PRE_DEPLOYMENT_BACKUP_PLAN.md.
 */
const { initAdmin } = require('./lib/admin');
const { hasSensitiveData, deepEqual } = require('./lib/sensitive_data');

async function verifyPassA(snapshot) {
  let expected = 0;
  let found = 0;
  const mismatches = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!hasSensitiveData(data)) continue;
    expected += 1;

    const sensitiveSnap = await doc.ref.collection('private').doc('sensitive').get();
    if (!sensitiveSnap.exists) {
      mismatches.push(`${doc.id}: private/sensitive missing`);
      continue;
    }
    found += 1;
    const sub = sensitiveSnap.data();
    if (
      !deepEqual(sub.pin ?? null, data.pin ?? null) ||
      !deepEqual(sub.patternLock ?? null, data.patternLock ?? null) ||
      !deepEqual(sub.notesHidden ?? null, data.notesHidden ?? null)
    ) {
      mismatches.push(`${doc.id}: field mismatch`);
    }
  }

  return { expected, found, mismatches };
}

async function main() {
  const execute = process.argv.includes('--execute');
  const admin = initAdmin();
  const db = admin.firestore();

  const snapshot = await db.collection('maintenanceDevices').get();
  const totalBefore = snapshot.size;

  console.log('Re-verifying Pass A before proceeding (not optional, not skippable)...');
  const { expected, found, mismatches } = await verifyPassA(snapshot);
  console.log(`Expected: ${expected}, Found: ${found}, Mismatches: ${mismatches.length}`);

  if (expected !== found || mismatches.length > 0) {
    console.error('');
    console.error('Pass A verification failed. REFUSING to run Pass B.');
    mismatches.forEach((m) => console.error(`  - ${m}`));
    process.exit(1);
  }

  let stripped = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!hasSensitiveData(data)) continue;

    if (execute) {
      await doc.ref.update({
        pin: admin.firestore.FieldValue.delete(),
        patternLock: admin.firestore.FieldValue.delete(),
        notesHidden: admin.firestore.FieldValue.delete(),
      });
      console.log(`[STRIPPED] ${doc.id}`);
    } else {
      console.log(`[DRY-RUN] Would strip pin/patternLock/notesHidden from ${doc.id}`);
    }
    stripped += 1;
  }

  console.log('');
  console.log(`Mode: ${execute ? 'EXECUTE' : 'DRY-RUN (pass --execute to write)'}`);
  console.log(`${execute ? 'Stripped' : 'Would strip'}: ${stripped} documents`);

  if (execute) {
    const afterSnapshot = await db.collection('maintenanceDevices').get();
    if (afterSnapshot.size !== totalBefore) {
      console.error('');
      console.error(
        `COUNT MISMATCH: had ${totalBefore} documents before, ${afterSnapshot.size} after. ` +
          'This should never happen for an update-only operation — stop and investigate ' +
          'immediately. See docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md §4/§5.',
      );
      process.exit(1);
    }
    console.log(`Document count unchanged (N = ${totalBefore}). Run verify-pass-b.js next.`);
  }
}

main().catch((err) => {
  console.error('Pass B failed:', err);
  process.exit(1);
});
