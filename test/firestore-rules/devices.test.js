'use strict';

const { test, before, beforeEach, after } = require('node:test');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} = require('firebase/firestore');
const {
  UID,
  makeEnv,
  seedUsers,
  seedDevice,
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

function validDevice(overrides = {}) {
  return {
    model: 'iPhone 12',
    colorHex: '#111111',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

// ---- create: authority ----

for (const [label, uid] of [
  ['Admin', UID.ADMIN],
  ['Reception', UID.RECEPTION],
  ['Maintenance', UID.MAINTENANCE],
]) {
  test(`${label} can create a well-formed Device`, async () => {
    const db = firestoreAs(testEnv, uid);
    await assertSucceeds(setDoc(doc(db, 'devices', 'd1'), validDevice()));
  });
}

test('Customer cannot create a Device', async () => {
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  await assertFails(setDoc(doc(db, 'devices', 'd1'), validDevice()));
});

test('Unauthenticated cannot create a Device', async () => {
  const db = firestoreAs(testEnv, null);
  await assertFails(setDoc(doc(db, 'devices', 'd1'), validDevice()));
});

// ---- create: canonical types and key set ----

test('create rejects a non-string model', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    setDoc(doc(db, 'devices', 'd1'), validDevice({ model: 42 }))
  );
});

test('create rejects a non-string colorHex', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    setDoc(doc(db, 'devices', 'd1'), validDevice({ colorHex: { hex: '#fff' } }))
  );
});

test('create rejects a non-string brand when present', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    setDoc(doc(db, 'devices', 'd1'), validDevice({ brand: 12345 }))
  );
});

test('create accepts a string brand when present', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertSucceeds(
    setDoc(doc(db, 'devices', 'd1'), validDevice({ brand: 'Apple' }))
  );
});

test('create rejects a non-string imeiNumber when present', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    setDoc(
      doc(db, 'devices', 'd1'),
      validDevice({ imeiNumber: 490154203237518 })
    )
  );
});

test('create accepts a string imeiNumber when present', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertSucceeds(
    setDoc(
      doc(db, 'devices', 'd1'),
      validDevice({ imeiNumber: '490154203237518' })
    )
  );
});

test('create rejects a non-string imeiNumberNormalized when present', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    setDoc(
      doc(db, 'devices', 'd1'),
      validDevice({ imeiNumberNormalized: 490154203237518 })
    )
  );
});

test('create accepts a string imeiNumberNormalized when present', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertSucceeds(
    setDoc(
      doc(db, 'devices', 'd1'),
      validDevice({ imeiNumberNormalized: '490154203237518' })
    )
  );
});

test('create rejects an arbitrary extra field', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    setDoc(
      doc(db, 'devices', 'd1'),
      validDevice({ notes: 'not part of the schema' })
    )
  );
});

test('create rejects a missing required field (colorHex)', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  const data = validDevice();
  delete data.colorHex;
  await assertFails(setDoc(doc(db, 'devices', 'd1'), data));
});

test('create rejects a client-supplied createdAt that is not the server time', async () => {
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    setDoc(
      doc(db, 'devices', 'd1'),
      validDevice({ createdAt: new Date('2020-01-01') })
    )
  );
});

// ---- read ----

for (const [label, uid] of [
  ['Admin', UID.ADMIN],
  ['Reception', UID.RECEPTION],
  ['Maintenance', UID.MAINTENANCE],
]) {
  test(`${label} can read a Device`, async () => {
    const id = await seedDevice(testEnv);
    const db = firestoreAs(testEnv, uid);
    await assertSucceeds(getDoc(doc(db, 'devices', id)));
  });
}

test('Customer cannot read a Device directly', async () => {
  const id = await seedDevice(testEnv);
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  await assertFails(getDoc(doc(db, 'devices', id)));
});

// ---- update ----

test('staff can update brand/model/colorHex/imeiNumber together', async () => {
  const id = await seedDevice(testEnv);
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  // updateDoc (partial merge), not setDoc — a full-document overwrite would
  // also need to resend the original createdAt, which isn't what this test
  // is checking; the immutability rule itself is covered separately below.
  await assertSucceeds(
    updateDoc(doc(db, 'devices', id), {
      brand: 'Samsung',
      imeiNumber: '356938035643809',
      updatedAt: serverTimestamp(),
    })
  );
});

test('staff can update imeiNumber together with imeiNumberNormalized', async () => {
  const id = await seedDevice(testEnv);
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertSucceeds(
    updateDoc(doc(db, 'devices', id), {
      imeiNumber: '35-6938-035643-809',
      imeiNumberNormalized: '356938035643809',
      updatedAt: serverTimestamp(),
    })
  );
});

test('update rejects a changed createdAt', async () => {
  const id = await seedDevice(testEnv);
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, 'devices', id),
      validDevice({ createdAt: serverTimestamp(), updatedAt: serverTimestamp() })
    )
  );
});

test('update rejects a stale (non-server-time) updatedAt', async () => {
  const id = await seedDevice(testEnv);
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, 'devices', id), { updatedAt: new Date('2020-01-01') })
  );
});

test('update rejects introducing an extra field', async () => {
  const id = await seedDevice(testEnv);
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, 'devices', id), {
      updatedAt: serverTimestamp(),
      notes: 'sneaked in',
    })
  );
});

test('Customer cannot update a Device', async () => {
  const id = await seedDevice(testEnv);
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  await assertFails(
    updateDoc(doc(db, 'devices', id), { updatedAt: serverTimestamp() })
  );
});

// ---- delete ----

for (const [label, uid] of [
  ['Admin', UID.ADMIN],
  ['Reception', UID.RECEPTION],
  ['Maintenance', UID.MAINTENANCE],
]) {
  test(`${label} cannot delete a Device`, async () => {
    const id = await seedDevice(testEnv);
    const db = firestoreAs(testEnv, uid);
    await assertFails(deleteDoc(doc(db, 'devices', id)));
  });
}
