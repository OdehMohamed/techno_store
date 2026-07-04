#!/usr/bin/env node
/**
 * Read-only. Post-Pass-B verification per
 * docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md checks 5-6: confirms zero
 * maintenanceDevices documents still carry pin/patternLock/notesHidden,
 * and reports the total document count for comparison against the N
 * recorded by inventory.js.
 */
const { initAdmin } = require('./lib/admin');
const { hasSensitiveData } = require('./lib/sensitive_data');

async function main() {
  const admin = initAdmin();
  const db = admin.firestore();

  const snapshot = await db.collection('maintenanceDevices').get();

  // IMPORTANT: use the same hasSensitiveData() definition as inventory.js /
  // migrate-pass-a.js / verify-pass-a.js (a real, non-empty value) — not a
  // raw "does the key exist" check. A device that had e.g. `patternLock: []`
  // or `notesHidden: ''` was correctly never migrated (nothing to migrate)
  // and correctly never touched by Pass B, so a raw key-presence check
  // would wrongly flag it as "lingering" even though nothing is wrong.
  // (Found and fixed via the Phase 1B migration rehearsal — see
  // docs/ai-workflow/DECISIONS_LOG.md.)
  const lingering = [];
  snapshot.forEach((doc) => {
    if (hasSensitiveData(doc.data())) {
      lingering.push(doc.id);
    }
  });

  console.log(`Total maintenanceDevices documents: ${snapshot.size}`);
  console.log(`Documents with lingering sensitive fields: ${lingering.length}`);
  lingering.forEach((id) => console.log(`  - ${id}`));

  if (lingering.length > 0) {
    console.error('');
    console.error('VERIFICATION FAILED: Pass B did not fully complete.');
    console.error('Do NOT deploy Firestore/Storage rules yet — see');
    console.error('docs/ai-workflow/MIGRATION_SUCCESS_CRITERIA.md §4.');
    process.exit(1);
  }

  console.log('');
  console.log('Pass B verification PASSED.');
  console.log(
    `Compare the total count above (${snapshot.size}) against the N recorded by inventory.js.`,
  );
}

main().catch((err) => {
  console.error('Verification failed:', err);
  process.exit(1);
});
