#!/usr/bin/env node
/**
 * Read-only. Counts total maintenanceDevices documents (N) and how many
 * have at least one non-empty sensitive field (M). Makes no writes — safe
 * to run at any time, including in production, before anything else.
 *
 * See docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md §1.
 */
const { initAdmin } = require('./lib/admin');
const { hasSensitiveData } = require('./lib/sensitive_data');

async function main() {
  const admin = initAdmin();
  const db = admin.firestore();

  const snapshot = await db.collection('maintenanceDevices').get();

  let total = 0;
  let withSensitiveData = 0;

  snapshot.forEach((doc) => {
    total += 1;
    if (hasSensitiveData(doc.data())) {
      withSensitiveData += 1;
    }
  });

  console.log('--- Inventory report ---');
  console.log(`Total maintenanceDevices documents (N): ${total}`);
  console.log(`Documents with sensitive data (M):       ${withSensitiveData}`);
  console.log('');
  console.log('Record these numbers now — they are the baseline every');
  console.log('later verification step in MIGRATION_SUCCESS_CRITERIA.md compares against.');
}

main().catch((err) => {
  console.error('Inventory failed:', err);
  process.exit(1);
});
