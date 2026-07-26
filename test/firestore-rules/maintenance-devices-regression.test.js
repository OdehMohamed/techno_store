'use strict';

// Small regression subset confirming the pre-existing maintenanceDevices
// rules are undisturbed by adding the new devices/estimates match blocks —
// not a re-run of BACKLOG #0a's full 74-case matrix.

const { test, before, beforeEach, after } = require('node:test');
const { doc, getDoc, setDoc, updateDoc } = require('firebase/firestore');
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
const VISIT_ID = 'visit-regression';

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

test('staff can create a Visit', async () => {
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    setDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      userId: UID.CUSTOMER_A,
      name: 'Regression Customer',
      phoneNumber: '+970500000000',
      model: 'Regression Model',
      colorHex: '#000000',
      problems: [],
      status: 'In Progress',
      accessories: [],
      deviceStatusReceived: [],
      recordState: 'active',
      receivedByEmployee: 'Test Staff',
      receivedAt: new Date().toISOString(),
    })
  );
});

test('Customer cannot create a Visit', async () => {
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  await assertFails(
    setDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      userId: UID.CUSTOMER_A,
      name: 'Regression Customer',
      phoneNumber: '+970500000000',
      model: 'Regression Model',
      colorHex: '#000000',
      problems: [],
      status: 'In Progress',
      accessories: [],
      deviceStatusReceived: [],
      recordState: 'active',
      receivedByEmployee: 'Test Staff',
      receivedAt: new Date().toISOString(),
    })
  );
});

test('staff can read any Visit', async () => {
  await seedVisit(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertSucceeds(getDoc(doc(db, 'maintenanceDevices', VISIT_ID)));
});

test('the owning customer can read their own Visit', async () => {
  await seedVisit(testEnv, VISIT_ID); // owned by CUSTOMER_A
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  await assertSucceeds(getDoc(doc(db, 'maintenanceDevices', VISIT_ID)));
});

test('a different customer cannot read someone else\'s Visit', async () => {
  await seedVisit(testEnv, VISIT_ID); // owned by CUSTOMER_A
  const db = firestoreAs(testEnv, UID.CUSTOMER_B);
  await assertFails(getDoc(doc(db, 'maintenanceDevices', VISIT_ID)));
});

test('staff can archive an active Visit', async () => {
  await seedVisit(testEnv, VISIT_ID, { recordState: 'active' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      recordState: 'archived',
    })
  );
});

test('Reception cannot restore an archived Visit (Admin-only)', async () => {
  await seedVisit(testEnv, VISIT_ID, { recordState: 'archived' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      recordState: 'active',
    })
  );
});

test('Admin can restore an archived Visit', async () => {
  await seedVisit(testEnv, VISIT_ID, { recordState: 'archived' });
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      recordState: 'active',
    })
  );
});

// ---- ordinary edits, and the archived-record freeze (ADR-005) ----
// Added alongside the ADR-007 targeted integrity rules (deviceId
// immutability, technicalFinding authority) to prove the pre-existing
// "ordinary edit" branch of the update rule — the one both new
// constraints are AND-ed onto — is still reachable and unbroken for
// every role and record state it always supported.

test('Reception can perform an ordinary edit on an active Visit', async () => {
  await seedVisit(testEnv, VISIT_ID, { recordState: 'active' });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { price: 55 })
  );
});

test('Maintenance can perform an ordinary edit on an active Visit', async () => {
  await seedVisit(testEnv, VISIT_ID, { recordState: 'active' });
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertSucceeds(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), {
      maintenanceEmployee: 'Test Tech',
    })
  );
});

test('an ordinary edit on an archived Visit is rejected — frozen until restored (no metadata-correction exception)', async () => {
  await seedVisit(testEnv, VISIT_ID, { recordState: 'archived' });
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    updateDoc(doc(db, 'maintenanceDevices', VISIT_ID), { price: 55 })
  );
});
