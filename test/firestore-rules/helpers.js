'use strict';

const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');

// Mirrors lib/core/utils/user_role.dart — kept as plain constants here
// rather than importing Dart, since this is a standalone Node project.
const ROLE = Object.freeze({
  ADMIN: 0,
  CUSTOMER: 1,
  RECEPTION: 2,
  MAINTENANCE: 3,
});

const UID = Object.freeze({
  ADMIN: 'test-admin-uid',
  RECEPTION: 'test-reception-uid',
  MAINTENANCE: 'test-maintenance-uid',
  CUSTOMER_A: 'test-customer-a-uid',
  CUSTOMER_B: 'test-customer-b-uid',
});

async function makeEnv() {
  return initializeTestEnvironment({
    projectId: 'demo-technostore-rules-test',
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../firestore.rules'),
        'utf8'
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

// Re-seeds the standard cast of role personas. Call after every
// clearFirestore() — clearing wipes seeded fixtures too, not just data
// written during the test itself.
async function seedUsers(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', UID.ADMIN), { type: ROLE.ADMIN });
    await setDoc(doc(db, 'users', UID.RECEPTION), { type: ROLE.RECEPTION });
    await setDoc(doc(db, 'users', UID.MAINTENANCE), {
      type: ROLE.MAINTENANCE,
    });
    await setDoc(doc(db, 'users', UID.CUSTOMER_A), { type: ROLE.CUSTOMER });
    await setDoc(doc(db, 'users', UID.CUSTOMER_B), { type: ROLE.CUSTOMER });
  });
}

// Seeds one maintenanceDevices (Visit) document, via a rules-disabled
// context (fixture setup, not the thing under test). Returns the visit ID.
async function seedVisit(testEnv, visitId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'maintenanceDevices', visitId), {
      userId: UID.CUSTOMER_A,
      name: 'Test Customer',
      phoneNumber: '+970500000000',
      model: 'Test Model',
      colorHex: '#000000',
      problems: [],
      status: 'In Progress',
      accessories: [],
      deviceStatusReceived: [],
      recordState: 'active',
      receivedByEmployee: 'Test Staff',
      receivedAt: new Date().toISOString(),
      ...overrides,
    });
  });
}

// Seeds one devices/{id} document via a rules-disabled context. Returns
// the generated ID.
async function seedDevice(testEnv, overrides = {}) {
  const id = `device-${Math.random().toString(36).slice(2)}`;
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'devices', id), {
      model: 'Seed Model',
      colorHex: '#222222',
      createdAt: new Date(),
      updatedAt: new Date(),
      ...overrides,
    });
  });
  return id;
}

// Seeds one estimates/{id} document under the given Visit via a
// rules-disabled context. Returns the generated ID.
async function seedEstimate(testEnv, visitId, overrides = {}) {
  const id = `estimate-${Math.random().toString(36).slice(2)}`;
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        'maintenanceDevices',
        visitId,
        'estimates',
        id
      ),
      {
        proposedScope: 'Seed scope',
        proposedAmount: 50,
        createdByUid: UID.MAINTENANCE,
        createdAt: new Date(),
        outcome: 'pending',
        ...overrides,
      }
    );
  });
  return id;
}

function firestoreAs(testEnv, uid) {
  if (uid === null) return testEnv.unauthenticatedContext().firestore();
  return testEnv.authenticatedContext(uid).firestore();
}

module.exports = {
  ROLE,
  UID,
  makeEnv,
  seedUsers,
  seedVisit,
  seedDevice,
  seedEstimate,
  firestoreAs,
  assertSucceeds,
  assertFails,
};
