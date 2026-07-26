'use strict';

// ADR-007 Phase 4 PR 2 — proves the atomic Device+Visit creation shape
// NewDeviceServices.addNewDevice uses when staff choose "Create New
// Device" at intake: a single WriteBatch spanning both the new
// devices/{id} document and the maintenanceDevices/{id} (Visit) document
// referencing it. Neither collection's create rule depends on reading the
// other, so this is genuinely new coverage — nothing else in this suite
// exercises a batch spanning two different top-level collections.

const { test, before, beforeEach, after } = require('node:test');
const { doc, writeBatch, getDoc, setDoc, serverTimestamp } = require('firebase/firestore');
const {
  UID,
  makeEnv,
  seedUsers,
  firestoreAs,
  assertSucceeds,
  assertFails,
} = require('./helpers');

let testEnv;

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

function validVisit(deviceId, overrides = {}) {
  return {
    userId: UID.CUSTOMER_A,
    name: 'Batch Test Customer',
    phoneNumber: '+970500000000',
    model: 'Batch Test Model',
    colorHex: '#000000',
    deviceId,
    problems: [],
    status: 'In Progress',
    accessories: [],
    deviceStatusReceived: [],
    recordState: 'active',
    receivedByEmployee: 'Test Staff',
    receivedAt: new Date().toISOString(),
    ...overrides,
  };
}

test('staff can atomically create a new Device and its Visit in one batch', async () => {
  const db = firestoreAs(testEnv, UID.RECEPTION);
  const deviceRef = doc(db, 'devices', 'batch-device-1');
  const visitRef = doc(db, 'maintenanceDevices', 'batch-visit-1');

  const batch = writeBatch(db);
  batch.set(deviceRef, {
    model: 'iPhone 12',
    colorHex: '#111111',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(visitRef, validVisit('batch-device-1'));

  await assertSucceeds(batch.commit());
});

test('an invalid Device payload inside the batch rejects the whole batch — the otherwise-valid Visit never lands either', async () => {
  const db = firestoreAs(testEnv, UID.RECEPTION);
  const deviceRef = doc(db, 'devices', 'batch-device-2');
  const visitRef = doc(db, 'maintenanceDevices', 'batch-visit-2');

  const batch = writeBatch(db);
  batch.set(deviceRef, {
    // missing required colorHex — the Device write alone would be
    // rejected by firestore.rules' hasAll() check.
    model: 'iPhone 12',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(visitRef, validVisit('batch-device-2'));

  await assertFails(batch.commit());

  // Prove atomicity concretely, not just infer it from the rejected
  // promise: read back with rules disabled and confirm NEITHER document
  // exists — the individually-valid Visit write didn't partially land.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const rawDb = context.firestore();
    const deviceSnap = await getDoc(doc(rawDb, 'devices', 'batch-device-2'));
    const visitSnap = await getDoc(doc(rawDb, 'maintenanceDevices', 'batch-visit-2'));
    if (deviceSnap.exists() || visitSnap.exists()) {
      throw new Error('Batch partially committed — atomicity violated');
    }
  });
});

test('Customer cannot commit a Device+Visit creation batch', async () => {
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  const deviceRef = doc(db, 'devices', 'batch-device-3');
  const visitRef = doc(db, 'maintenanceDevices', 'batch-visit-3');

  const batch = writeBatch(db);
  batch.set(deviceRef, {
    model: 'iPhone 12',
    colorHex: '#111111',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.set(visitRef, validVisit('batch-device-3'));

  await assertFails(batch.commit());
});

test('selecting an existing Device needs no batch — a single Visit write referencing it succeeds', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'devices', 'existing-device-1'), {
      model: 'Pre-existing Device',
      colorHex: '#222222',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });

  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    setDoc(
      doc(db, 'maintenanceDevices', 'visit-referencing-existing'),
      validVisit('existing-device-1')
    )
  );
});
