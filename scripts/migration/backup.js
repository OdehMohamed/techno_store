#!/usr/bin/env node
/**
 * Read-only against Firestore; writes local JSON files. Dumps every
 * maintenanceDevices and users document — this is backup format B from
 * docs/ai-workflow/PRE_DEPLOYMENT_BACKUP_PLAN.md §2.
 *
 * This does NOT replace the managed `gcloud firestore export` (format A) —
 * that must be taken separately via the gcloud CLI. Format B exists so a
 * later restore can be *targeted* (specific fields on specific documents)
 * rather than a blunt full-collection import — see the backup plan's §4
 * rationale.
 */
const fs = require('fs');
const path = require('path');
const { initAdmin } = require('./lib/admin');

async function dumpCollection(db, collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const result = {};
  snapshot.forEach((doc) => {
    result[doc.id] = doc.data();
  });
  return result;
}

async function main() {
  const admin = initAdmin();
  const db = admin.firestore();

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outDir = path.join(__dirname, 'backups', timestamp);
  fs.mkdirSync(outDir, { recursive: true });

  console.log('Backing up maintenanceDevices...');
  const devices = await dumpCollection(db, 'maintenanceDevices');
  fs.writeFileSync(
    path.join(outDir, 'maintenanceDevices.json'),
    JSON.stringify(devices, null, 2),
  );
  console.log(`  ${Object.keys(devices).length} documents written.`);

  console.log('Backing up users...');
  const users = await dumpCollection(db, 'users');
  fs.writeFileSync(path.join(outDir, 'users.json'), JSON.stringify(users, null, 2));
  console.log(`  ${Object.keys(users).length} documents written.`);

  console.log('');
  console.log(`Backup written to: ${outDir}`);
  console.log('');
  console.log('NEXT STEPS (do not skip):');
  console.log('  1. Upload this directory to the backup GCS bucket per');
  console.log('     docs/ai-workflow/PRE_DEPLOYMENT_BACKUP_PLAN.md §3.');
  console.log('  2. Take the managed `gcloud firestore export` (format A) separately —');
  console.log('     this script does not do that for you.');
  console.log('  3. Do not rely on this local copy alone as the backup.');
}

main().catch((err) => {
  console.error('Backup failed:', err);
  process.exit(1);
});
