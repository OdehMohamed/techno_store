'use strict';

// Proves the actual Firestore whereIn query behind ADR-007 Phase 2's
// compatibility tabs — not just DeviceStatus.isInGroup()'s boolean logic
// (see ../../test/core/utils/device_status_test.dart for that). Mirrors
// the compatibility groups defined in lib/core/utils/device_status.dart;
// kept as plain constants here since this is a standalone Node project
// (same pattern as ROLE in helpers.js mirroring UserRole).

const { test, before, beforeEach, after } = require('node:test');
const assert = require('node:assert/strict');
const { collection, query, where, getDocs } = require('firebase/firestore');
const { UID, makeEnv, seedUsers, seedVisit, firestoreAs } = require('./helpers');

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

const IN_MAINTENANCE_GROUP = ['In Maintenance', 'In Progress', 'Awaiting Approval'];
const FIXED_GROUP = ['Fixed', 'Ready for Handback'];
const DELIVERED_GROUP = ['Delivered'];

// One Visit per literal across both vocabularies, all active — matches
// what _deviceTabQuery filters on (status whereIn + recordState active).
const VISITS_BY_STATUS = {
  'v-legacy-in-maintenance': 'In Maintenance',
  'v-new-in-progress': 'In Progress',
  'v-new-awaiting-approval': 'Awaiting Approval',
  'v-legacy-fixed': 'Fixed',
  'v-new-ready-for-handback': 'Ready for Handback',
  'v-legacy-delivered': 'Delivered',
};

async function seedAllStatuses() {
  for (const [id, status] of Object.entries(VISITS_BY_STATUS)) {
    await seedVisit(testEnv, id, { status });
  }
}

// Reproduces MaintenanceListServices._deviceTabQuery's status+recordState
// shape exactly (whereIn + active), run as a real authenticated staff
// user so this also exercises the actual security rules, not just data
// shape — matching how maintenance-devices-regression.test.js operates.
async function statusGroupIds(group) {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  const q = query(
    collection(db, 'maintenanceDevices'),
    where('status', 'in', group),
    where('recordState', '==', 'active')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map((d) => d.id).sort();
}

test('In Maintenance compatibility query returns legacy In Maintenance + new In Progress + new Awaiting Approval, and nothing else', async () => {
  await seedAllStatuses();
  const ids = await statusGroupIds(IN_MAINTENANCE_GROUP);
  assert.deepEqual(
    ids,
    ['v-legacy-in-maintenance', 'v-new-awaiting-approval', 'v-new-in-progress'].sort()
  );
});

test('Fixed compatibility query returns legacy Fixed + new Ready for Handback, and nothing else', async () => {
  await seedAllStatuses();
  const ids = await statusGroupIds(FIXED_GROUP);
  assert.deepEqual(ids, ['v-legacy-fixed', 'v-new-ready-for-handback'].sort());
});

test('Delivered compatibility query returns only Delivered', async () => {
  await seedAllStatuses();
  const ids = await statusGroupIds(DELIVERED_GROUP);
  assert.deepEqual(ids, ['v-legacy-delivered']);
});

test('an unrelated status is not returned by any compatibility group query', async () => {
  await seedVisit(testEnv, 'v-unrelated', { status: 'Cancelled' });
  for (const group of [IN_MAINTENANCE_GROUP, FIXED_GROUP, DELIVERED_GROUP]) {
    const ids = await statusGroupIds(group);
    assert.ok(
      !ids.includes('v-unrelated'),
      `'Cancelled' incorrectly matched group ${JSON.stringify(group)}`
    );
  }
});

test('a device in one group is never returned by a different group\'s query', async () => {
  await seedAllStatuses();
  const fixedIds = await statusGroupIds(FIXED_GROUP);
  for (const id of ['v-legacy-in-maintenance', 'v-new-in-progress', 'v-new-awaiting-approval', 'v-legacy-delivered']) {
    assert.ok(!fixedIds.includes(id), `${id} leaked into the Fixed group query`);
  }
});
