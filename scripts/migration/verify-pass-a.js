#!/usr/bin/env node
/**
 * Read-only. Verifies Migration Pass A per
 * docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md checks 2-4:
 *   - private/sensitive subdocument count equals M exactly
 *   - every migrated field matches the source byte-for-byte
 *   - (implicitly) nothing on the parent document was touched, since this
 *     script reads but never writes
 *
 * Exits non-zero on ANY failure — per that document's "hard stop" rule,
 * even a single mismatched document blocks proceeding to Pass B.
 */
const { initAdmin } = require('./lib/admin');
const { hasSensitiveData, deepEqual } = require('./lib/sensitive_data');

async function main() {
  const admin = initAdmin();
  const db = admin.firestore();

  const snapshot = await db.collection('maintenanceDevices').get();

  let expectedSubdocs = 0;
  let actualSubdocsFound = 0;
  const mismatches = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!hasSensitiveData(data)) continue;
    expectedSubdocs += 1;

    const sensitiveSnap = await doc.ref.collection('private').doc('sensitive').get();
    if (!sensitiveSnap.exists) {
      mismatches.push(`${doc.id}: expected private/sensitive to exist, but it doesn't`);
      continue;
    }
    actualSubdocsFound += 1;

    const sub = sensitiveSnap.data();
    if (!deepEqual(sub.pin ?? null, data.pin ?? null)) {
      mismatches.push(`${doc.id}: pin mismatch`);
    }
    if (!deepEqual(sub.patternLock ?? null, data.patternLock ?? null)) {
      mismatches.push(`${doc.id}: patternLock mismatch`);
    }
    if (!deepEqual(sub.notesHidden ?? null, data.notesHidden ?? null)) {
      mismatches.push(`${doc.id}: notesHidden mismatch`);
    }
  }

  console.log(`Expected private/sensitive subdocuments (M): ${expectedSubdocs}`);
  console.log(`Found:                                        ${actualSubdocsFound}`);
  console.log(`Mismatches:                                   ${mismatches.length}`);
  mismatches.forEach((m) => console.log(`  - ${m}`));

  if (expectedSubdocs !== actualSubdocsFound || mismatches.length > 0) {
    console.error('');
    console.error('VERIFICATION FAILED. Do NOT proceed to migrate-pass-b.js.');
    console.error('See docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md §4.');
    process.exit(1);
  }

  console.log('');
  console.log('Pass A verification PASSED. Safe to proceed to migrate-pass-b.js.');
}

main().catch((err) => {
  console.error('Verification failed:', err);
  process.exit(1);
});
