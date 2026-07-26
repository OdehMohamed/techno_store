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
  seedVisit,
  seedEstimate,
  firestoreAs,
  assertSucceeds,
  assertFails,
} = require('./helpers');

let testEnv;
const VISIT_ID = 'visit-1';

before(async () => {
  testEnv = await makeEnv();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedUsers(testEnv);
  await seedVisit(testEnv, VISIT_ID); // owned by UID.CUSTOMER_A
});

after(async () => {
  await testEnv.cleanup();
});

function estimatePath(id) {
  return ['maintenanceDevices', VISIT_ID, 'estimates', id];
}

function validEstimate(uid, overrides = {}) {
  return {
    proposedScope: 'Replace screen',
    proposedAmount: 75,
    createdByUid: uid,
    createdAt: serverTimestamp(),
    outcome: 'pending',
    ...overrides,
  };
}

// ==== create: authority ====

for (const [label, uid] of [
  ['Maintenance', UID.MAINTENANCE],
  ['Admin', UID.ADMIN],
]) {
  test(`${label} can create a well-formed Estimate`, async () => {
    const db = firestoreAs(testEnv, uid);
    await assertSucceeds(
      setDoc(doc(db, ...estimatePath('e1')), validEstimate(uid))
    );
  });
}

test('Reception cannot create an Estimate', async () => {
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    setDoc(doc(db, ...estimatePath('e1')), validEstimate(UID.RECEPTION))
  );
});

test('Customer cannot create an Estimate', async () => {
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  await assertFails(
    setDoc(doc(db, ...estimatePath('e1')), validEstimate(UID.CUSTOMER_A))
  );
});

test('Unauthenticated cannot create an Estimate', async () => {
  const db = firestoreAs(testEnv, null);
  await assertFails(
    setDoc(doc(db, ...estimatePath('e1')), validEstimate('anyone'))
  );
});

// ==== create: integrity ====

test('create rejects a spoofed createdByUid', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.ADMIN) // claims Admin created it, actually Maintenance is writing
    )
  );
});

test('create rejects a client-supplied createdAt that is not server time', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { createdAt: new Date('2020-01-01') })
    )
  );
});

test('create rejects outcome other than pending', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { outcome: 'approved' })
    )
  );
});

test('create rejects a non-string proposedScope', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { proposedScope: 12345 })
    )
  );
});

test('create rejects a non-numeric proposedAmount', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { proposedAmount: '75' })
    )
  );
});

test('create rejects a negative proposedAmount', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { proposedAmount: -10 })
    )
  );
});

test('create accepts a zero proposedAmount', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertSucceeds(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { proposedAmount: 0 })
    )
  );
});

test('create rejects setting resolutionOutcome directly at creation', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { resolutionOutcome: 'stop' })
    )
  );
});

test('create rejects an arbitrary extra field', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    setDoc(
      doc(db, ...estimatePath('e1')),
      validEstimate(UID.MAINTENANCE, { internalNote: 'not part of the schema' })
    )
  );
});

test('create rejects a missing required field (proposedAmount)', async () => {
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  const data = validEstimate(UID.MAINTENANCE);
  delete data.proposedAmount;
  await assertFails(setDoc(doc(db, ...estimatePath('e1')), data));
});

// ==== read ====

for (const [label, uid] of [
  ['Admin', UID.ADMIN],
  ['Reception', UID.RECEPTION],
  ['Maintenance', UID.MAINTENANCE],
]) {
  test(`${label} can read an Estimate`, async () => {
    const id = await seedEstimate(testEnv, VISIT_ID);
    const db = firestoreAs(testEnv, uid);
    await assertSucceeds(getDoc(doc(db, ...estimatePath(id))));
  });
}

test('the owning customer can read their own Visit\'s Estimate', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.CUSTOMER_A); // VISIT_ID's userId
  await assertSucceeds(getDoc(doc(db, ...estimatePath(id))));
});

test('a different customer cannot read this Visit\'s Estimate', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.CUSTOMER_B);
  await assertFails(getDoc(doc(db, ...estimatePath(id))));
});

test('unauthenticated cannot read an Estimate', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, null);
  await assertFails(getDoc(doc(db, ...estimatePath(id))));
});

// ==== decision recording: approve ====

for (const [label, uid] of [
  ['Admin', UID.ADMIN],
  ['Reception', UID.RECEPTION],
  ['Maintenance', UID.MAINTENANCE],
]) {
  test(`${label} can record an approval (staff-wide)`, async () => {
    const id = await seedEstimate(testEnv, VISIT_ID);
    const db = firestoreAs(testEnv, uid);
    await assertSucceeds(
      updateDoc(doc(db, ...estimatePath(id)), {
        outcome: 'approved',
        decidedByUid: uid,
        decidedAt: serverTimestamp(),
      })
    );
  });
}

test('Customer cannot record a decision', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.CUSTOMER_A);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'approved',
      decidedByUid: UID.CUSTOMER_A,
      decidedAt: serverTimestamp(),
    })
  );
});

test('decision recording rejects a spoofed decidedByUid', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'approved',
      decidedByUid: UID.ADMIN, // Reception is writing, claims Admin decided
      decidedAt: serverTimestamp(),
    })
  );
});

test('decision recording rejects a non-server-time decidedAt', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'approved',
      decidedByUid: UID.RECEPTION,
      decidedAt: new Date('2020-01-01'),
    })
  );
});

test('approval rejects an accompanying declineReason', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'approved',
      decidedByUid: UID.RECEPTION,
      decidedAt: serverTimestamp(),
      declineReason: 'should not be allowed here',
    })
  );
});

test('decision recording rejects mutating proposedScope in the same write', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'approved',
      decidedByUid: UID.RECEPTION,
      decidedAt: serverTimestamp(),
      proposedScope: 'Quietly changed scope',
    })
  );
});

test('decision recording rejects mutating proposedAmount in the same write', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'approved',
      decidedByUid: UID.RECEPTION,
      decidedAt: serverTimestamp(),
      proposedAmount: 9999,
    })
  );
});

test('decision recording rejects an arbitrary extra field', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'approved',
      decidedByUid: UID.RECEPTION,
      decidedAt: serverTimestamp(),
      sneaky: true,
    })
  );
});

test('a second decision attempt on an already-decided Estimate fails', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'approved',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'declined',
      decidedByUid: UID.ADMIN,
      decidedAt: serverTimestamp(),
    })
  );
});

// ==== decision recording: decline ====

test('decline accepts a string declineReason', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'declined',
      decidedByUid: UID.RECEPTION,
      decidedAt: serverTimestamp(),
      declineReason: 'Too expensive',
    })
  );
});

test('decline succeeds with no declineReason (optional)', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertSucceeds(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'declined',
      decidedByUid: UID.RECEPTION,
      decidedAt: serverTimestamp(),
    })
  );
});

test('decline rejects a non-string declineReason', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID);
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      outcome: 'declined',
      decidedByUid: UID.RECEPTION,
      decidedAt: serverTimestamp(),
      declineReason: 42,
    })
  );
});

// ==== resolution recording ====

test('Maintenance can resolve a qualifying declined Estimate to continue', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertSucceeds(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'continue',
      resolvedByUid: UID.MAINTENANCE,
      resolvedAt: serverTimestamp(),
    })
  );
});

test('Admin can resolve a qualifying declined Estimate to stop', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertSucceeds(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'stop',
      resolvedByUid: UID.ADMIN,
      resolvedAt: serverTimestamp(),
    })
  );
});

test('Reception cannot resolve a declined Estimate', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.RECEPTION);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'continue',
      resolvedByUid: UID.RECEPTION,
      resolvedAt: serverTimestamp(),
    })
  );
});

test('resolution rejects a spoofed resolvedByUid', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'continue',
      resolvedByUid: UID.ADMIN, // Maintenance is writing, claims Admin resolved
      resolvedAt: serverTimestamp(),
    })
  );
});

test('resolution rejects a non-server-time resolvedAt', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'continue',
      resolvedByUid: UID.MAINTENANCE,
      resolvedAt: new Date('2020-01-01'),
    })
  );
});

test('resolution cannot be recorded while outcome is still pending', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID); // outcome: 'pending'
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'continue',
      resolvedByUid: UID.MAINTENANCE,
      resolvedAt: serverTimestamp(),
    })
  );
});

test('resolution cannot be recorded on an approved Estimate', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'approved',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'stop',
      resolvedByUid: UID.MAINTENANCE,
      resolvedAt: serverTimestamp(),
    })
  );
});

test('a second resolution attempt on an already-resolved Estimate fails', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
    resolutionOutcome: 'continue',
    resolvedByUid: UID.MAINTENANCE,
    resolvedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.ADMIN);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'stop',
      resolvedByUid: UID.ADMIN,
      resolvedAt: serverTimestamp(),
    })
  );
});

test('resolution rejects mutating proposedAmount in the same write', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'continue',
      resolvedByUid: UID.MAINTENANCE,
      resolvedAt: serverTimestamp(),
      proposedAmount: 1,
    })
  );
});

test('resolution rejects an arbitrary extra field', async () => {
  const id = await seedEstimate(testEnv, VISIT_ID, {
    outcome: 'declined',
    decidedByUid: UID.RECEPTION,
    decidedAt: new Date(),
  });
  const db = firestoreAs(testEnv, UID.MAINTENANCE);
  await assertFails(
    updateDoc(doc(db, ...estimatePath(id)), {
      resolutionOutcome: 'continue',
      resolvedByUid: UID.MAINTENANCE,
      resolvedAt: serverTimestamp(),
      sneaky: true,
    })
  );
});

// ==== delete ====

for (const [label, uid] of [
  ['Admin', UID.ADMIN],
  ['Reception', UID.RECEPTION],
  ['Maintenance', UID.MAINTENANCE],
]) {
  test(`${label} cannot delete an Estimate`, async () => {
    const id = await seedEstimate(testEnv, VISIT_ID);
    const db = firestoreAs(testEnv, uid);
    await assertFails(deleteDoc(doc(db, ...estimatePath(id))));
  });
}
