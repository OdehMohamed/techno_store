'use strict';

// Targeted integrity rules added ahead of ADR-007 capability-client work
// (PR 1 of 4): deviceId immutability after creation, and Maintenance+Admin
// -only authority over technicalFinding/technicalWorkConcludedAt. Both
// apply now, not deferred to Phase 6 — see ADR-007's Final authorization
// matrix and Rollout section.

const { test, before, beforeEach, after } = require('node:test');
const { doc, updateDoc, deleteField } = require('firebase/firestore');
const {
  UID,
  makeEnv,
  seedUsers,
  seedVisit,
  firestoreAs,
  assertSucceeds,
  assertFails,
} = require('./helpers');

let testEnv;
const VISIT_ID = 'visit-adr007-fields';

before(async () => {
  testEnv = await makeEnv();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedUsers(testEnv);
});

after(async () => {
  await testEnv.cleanup();
});

// ---- deviceId immutability ----

test('Reception can edit price on a legacy Visit without touching deviceId, which stays absent', async () => {
  await seedVisit(testEnv, VISIT_ID); // no deviceId — legacy
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { price: 42 })
  );
});

test('adding deviceId to a legacy Visit via update is rejected', async () => {
  await seedVisit(testEnv, VISIT_ID); // no deviceId — legacy
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { deviceId: 'device-1' })
  );
});

test('Reception can edit price on a new-world Visit without touching deviceId, which stays unchanged', async () => {
  await seedVisit(testEnv, VISIT_ID, { deviceId: 'device-1' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { price: 42 })
  );
});

test('reassigning deviceId on a new-world Visit via update is rejected', async () => {
  await seedVisit(testEnv, VISIT_ID, { deviceId: 'device-1' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { deviceId: 'device-2' })
  );
});

test('removing deviceId from a new-world Visit via update is rejected', async () => {
  await seedVisit(testEnv, VISIT_ID, { deviceId: 'device-1' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { deviceId: deleteField() })
  );
});

test('Admin restoring an archived new-world Visit without touching deviceId still succeeds', async () => {
  await seedVisit(testEnv, VISIT_ID, {
    deviceId: 'device-1',
    recordState: 'archived',
  });
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { recordState: 'active' })
  );
});

test('Admin cannot reassign deviceId while restoring an archived Visit — Restore is not a side door around the invariant', async () => {
  await seedVisit(testEnv, VISIT_ID, {
    deviceId: 'device-1',
    recordState: 'archived',
  });
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      recordState: 'active',
      deviceId: 'device-2',
    })
  );
});

// ---- technicalFinding / technicalWorkConcludedAt authority ----

test('Reception can edit price on a Visit with no technicalFinding set', async () => {
  await seedVisit(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { price: 42 })
  );
});

test('Reception cannot set technicalFinding', async () => {
  await seedVisit(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      technicalFinding: 'Repaired',
    })
  );
});

test('Maintenance can set technicalFinding for the first time', async () => {
  await seedVisit(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      technicalFinding: 'Repaired',
    })
  );
});

test('Admin can set technicalFinding', async () => {
  await seedVisit(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      technicalFinding: 'No Fault Found',
    })
  );
});

test('Reception can edit price on a Visit that already has technicalFinding set, without touching it', async () => {
  await seedVisit(testEnv, VISIT_ID, { technicalFinding: 'Repaired' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { price: 99 })
  );
});

test('Reception cannot change technicalWorkConcludedAt alone', async () => {
  await seedVisit(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      technicalWorkConcludedAt: new Date().toISOString(),
    })
  );
});

test('Reception cannot bundle a technicalFinding change into an otherwise-ordinary edit', async () => {
  await seedVisit(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      price: 42,
      technicalFinding: 'Repaired',
    })
  );
});

test('Reception cannot set technicalFinding while archiving a Visit — Archive is not a side door around the authority boundary', async () => {
  await seedVisit(testEnv, VISIT_ID, { recordState: 'active' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      recordState: 'archived',
      technicalFinding: 'Repaired',
    })
  );
});
