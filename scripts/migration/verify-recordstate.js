#!/usr/bin/env node
/**
 * Read-only. Verifies the Device Lifecycle migration (ADR-005): confirms
 * every maintenanceDevices document has a recordState field. Exits
 * non-zero if any document is still missing it — per this repo's migration
 * discipline (see verify-pass-a.js), a hard stop, not a warning.
 */
const { initAdmin } = require('./lib/admin');

async function main() {
  const admin = initAdmin();
  const db = admin.firestore();

  const snapshot = await db.collection('maintenanceDevices').get();

  let total = 0;
  const missing = [];

  snapshot.forEach((doc) => {
    total += 1;
    const data = doc.data();
    if (!Object.prototype.hasOwnProperty.call(data, 'recordState')) {
      missing.push(doc.id);
    }
  });

  console.log(`Total maintenanceDevices documents: ${total}`);
  console.log(`Missing recordState: ${missing.length}`);
  missing.forEach((id) => console.log(`  - ${id}`));

  if (missing.length > 0) {
    console.error('');
    console.error('VERIFICATION FAILED. Do not deploy client code that');
    console.error('queries on recordState until this is zero — every');
    console.error('device listed above would silently vanish from all');
    console.error('staff tabs and the customer\'s own view.');
    process.exit(1);
  }

  console.log('');
  console.log('VERIFICATION PASSED. Every device has a recordState.');
}

main().catch((err) => {
  console.error('recordState verification failed:', err);
  process.exit(1);
});
