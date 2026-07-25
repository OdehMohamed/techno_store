const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
// Modular import, not the legacy admin.firestore.FieldValue namespaced
// access — found via executable emulator testing (2026-07-24) to be
// unreliable under firebase-tools' Functions Emulator runtime for this
// firebase-admin/firebase-functions version combination (setStaffStatus's
// own serverTimestamp() call failed identically: "Cannot read properties
// of undefined (reading 'serverTimestamp')"). Modular import sidesteps the
// lazy static-property attachment this depended on, regardless of root
// cause — this was setStaffStatus's first-ever executable test since it
// shipped in PR #14; every status change before this was a direct
// Firestore/Console edit that bypassed the function entirely.
const { FieldValue } = require("firebase-admin/firestore");

admin.initializeApp();

// Role storage: users/{uid}.type (int). 0=Admin, 1=Customer, 2=Reception,
// 3=Maintenance, 9=Guest — matches firestore.rules' top-of-file mapping.

/**
 * Links maintenance devices received before a customer had an account to
 * that account once it's created.
 *
 * Devices intake'd by Reception before a customer signs up are stored with
 * a `phoneNumber` but no `userId` (see NewDeviceServices.addNewDevice /
 * updateDevice in the Flutter app, which already link a device's `userId`
 * immediately whenever a matching customer account already exists at
 * intake/update time — that staff-side path is unaffected by this
 * function). This function covers the remaining case: a device existed
 * first, and the customer registers afterward.
 *
 * This intentionally runs server-side rather than in the client app: it
 * requires (1) querying maintenanceDevices by phoneNumber, which a customer
 * is not authorized to do (customers may only read their own device by
 * uid), and (2) writing maintenanceDevices.userId, which is a staff-only
 * write under the deployed Firestore rules. Performing this as the customer
 * would require weakening those rules. Running it here, with the Admin SDK,
 * requires no rule changes.
 *
 * The match key is the phone number Firebase Auth verified via OTP for this
 * uid (read directly from the Auth user record) — not the `phoneNumber`
 * field on the Firestore users/{uid} document, even though the deployed
 * Firestore rules require those two to match at profile creation. Reading
 * from Auth directly means this function's correctness never depends on
 * that rule staying in place.
 */
exports.linkDevicesToNewCustomer = onDocumentCreated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    // Tracked outside the try block so the catch-block log always has it,
    // even if the failure happens before the phone number is resolved.
    let verifiedPhone;

    try {
      const userRecord = await admin.auth().getUser(uid);
      verifiedPhone = userRecord.phoneNumber;

      if (!verifiedPhone) {
        logger.info(`users/${uid} has no verified phone number — nothing to link.`);
        return;
      }

      const db = admin.firestore();
      const unlinkedDevicesSnapshot = await db
        .collection("maintenanceDevices")
        .where("phoneNumber", "==", verifiedPhone)
        .where("userId", "==", null)
        .get();

      if (unlinkedDevicesSnapshot.empty) {
        logger.info(
          `No unlinked devices found for users/${uid} (phone ${verifiedPhone}).`
        );
        return;
      }

      const batch = db.batch();
      unlinkedDevicesSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, { userId: uid });
      });
      await batch.commit();

      logger.info(
        `Linked ${unlinkedDevicesSnapshot.size} device(s) to users/${uid} ` +
          `(phone ${verifiedPhone}): ` +
          unlinkedDevicesSnapshot.docs.map((d) => d.id).join(", ")
      );
    } catch (error) {
      // This is the only mechanism that links a device received before its
      // owner registered — a silent failure here means that device stays
      // unlinked with no other path to notice. Log uid/phone context
      // explicitly (a bare stack trace alone won't tell a future reader
      // which customer/device was involved) and rethrow so Cloud Functions
      // still records the invocation as failed for monitoring/alerting.
      logger.error(
        `linkDevicesToNewCustomer FAILED for users/${uid} ` +
          `(verifiedPhone=${verifiedPhone ?? "unresolved"}): ${error}`,
        { uid, verifiedPhone, error }
      );
      throw error;
    }
  }
);

/**
 * Sets a staff account's active/inactive status. The only write path for
 * users/{uid}/meta/staffStatus — the deployed Firestore rules deny every
 * client write to anything under users/{uid}/meta (see firestore.rules),
 * so any change, including one made by a legitimately authenticated Admin,
 * must go through this function. See ADR-004 ("Staff Status Architecture
 * Pass", 2026-07-23) and docs/product/PRD.md (Auth & Account Lifecycle).
 *
 * Authorization requires two things, not just one: the caller must be
 * Admin (users/{callerUid}.type == 0), AND the caller's own staffStatus
 * must currently be "active". Checking only the role would let a
 * deactivated Admin who still holds a valid Firebase Auth session keep
 * changing other staff members' status — the second check closes that.
 *
 * staffStatus applies to staff accounts only (Admin, Reception,
 * Maintenance) — deliberately not the retired isActivated field and not a
 * concept customers carry (see PRD.md's "Retired" note).
 *
 * Every change writes an audit log entry (auditLogs/{autoId}) — no client
 * can read or write that collection (default-deny in firestore.rules);
 * only this function, via the Admin SDK, does.
 */
exports.setStaffStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }

  const { uid: targetUid, status } = request.data ?? {};
  if (typeof targetUid !== "string" || targetUid.length === 0) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }
  if (status !== "active" && status !== "inactive") {
    throw new HttpsError(
      "invalid-argument",
      "status must be 'active' or 'inactive'."
    );
  }

  const callerUid = request.auth.uid;
  const db = admin.firestore();

  const callerSnap = await db.doc(`users/${callerUid}`).get();
  if (!callerSnap.exists || callerSnap.data().type !== 0) {
    throw new HttpsError(
      "permission-denied",
      "Only Admin may change staff status."
    );
  }

  const callerStatusSnap = await db
    .doc(`users/${callerUid}/meta/staffStatus`)
    .get();
  const callerStatus = callerStatusSnap.exists
    ? callerStatusSnap.data().status
    : null;
  if (callerStatus !== "active") {
    throw new HttpsError(
      "permission-denied",
      "Caller's own staff status is not active."
    );
  }

  const targetSnap = await db.doc(`users/${targetUid}`).get();
  if (!targetSnap.exists) {
    throw new HttpsError("not-found", "Target user does not exist.");
  }
  const targetType = targetSnap.data().type;
  if (targetType !== 0 && targetType !== 2 && targetType !== 3) {
    throw new HttpsError(
      "failed-precondition",
      "staffStatus applies to staff accounts only (Admin, Reception, Maintenance)."
    );
  }

  const statusRef = db.doc(`users/${targetUid}/meta/staffStatus`);
  const previousSnap = await statusRef.get();
  const previousStatus = previousSnap.exists
    ? previousSnap.data().status ?? null
    : null;

  await statusRef.set({
    status,
    updatedAt: FieldValue.serverTimestamp(),
    updatedBy: callerUid,
  });

  await db.collection("auditLogs").add({
    actingAdminUid: callerUid,
    targetUid,
    field: "staffStatus",
    oldValue: previousStatus,
    newValue: status,
    timestamp: FieldValue.serverTimestamp(),
  });

  logger.info("setStaffStatus", {
    callerUid,
    targetUid,
    previousStatus,
    newStatus: status,
  });

  return { status };
});

/**
 * Permanently deletes a maintenance device: Storage images, the
 * private/sensitive subdocument, and the parent document — irreversible.
 * See ADR-005 ("Maintenance Device Lifecycle", 2026-07-23).
 *
 * This is the sole path for permanent deletion once the second ADR-005
 * rollout PR removes the client's direct `delete` permission on
 * maintenanceDevices (see that PR's Firestore rules change) — until then,
 * this function and the legacy client-side cascade both exist, but nothing
 * in the client calls this function yet.
 *
 * Authorization mirrors setStaffStatus: caller must be Admin
 * (users/{callerUid}.type == 0) AND the caller's own staffStatus must
 * currently be "active" — closes the same deactivated-Admin-with-a-
 * lingering-session gap.
 *
 * Precondition: the target device's recordState must already be
 * "archived" — permanent deletion is never reachable directly from a live
 * operational record, by design (ADR-005, "Permanent Deletion").
 *
 * Writes a durable auditLogs entry (device id, model, customer name/phone,
 * acting admin uid, timestamp) BEFORE deleting the parent document, so a
 * crash between steps leaves, at worst, a stray audit entry for a device
 * that still exists (noticeable, recoverable) rather than a silently
 * destroyed record with no trace at all.
 */
exports.permanentlyDeleteDevice = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }

  const { deviceId } = request.data ?? {};
  if (typeof deviceId !== "string" || deviceId.length === 0) {
    throw new HttpsError("invalid-argument", "deviceId is required.");
  }

  const callerUid = request.auth.uid;
  const db = admin.firestore();

  const callerSnap = await db.doc(`users/${callerUid}`).get();
  if (!callerSnap.exists || callerSnap.data().type !== 0) {
    throw new HttpsError(
      "permission-denied",
      "Only Admin may permanently delete a device."
    );
  }

  const callerStatusSnap = await db
    .doc(`users/${callerUid}/meta/staffStatus`)
    .get();
  const callerStatus = callerStatusSnap.exists
    ? callerStatusSnap.data().status
    : null;
  if (callerStatus !== "active") {
    throw new HttpsError(
      "permission-denied",
      "Caller's own staff status is not active."
    );
  }

  const deviceRef = db.doc(`maintenanceDevices/${deviceId}`);
  const deviceSnap = await deviceRef.get();
  if (!deviceSnap.exists) {
    throw new HttpsError("not-found", "Device does not exist.");
  }
  const deviceData = deviceSnap.data();
  if (deviceData.recordState !== "archived") {
    throw new HttpsError(
      "failed-precondition",
      "Device must be archived before it can be permanently deleted."
    );
  }

  // Storage first: if this step fails partway, the worst-case leftover is
  // orphaned non-sensitive images — low severity, same ordering rationale
  // as the original client-side cascade (see
  // PHASE1_IMPLEMENTATION_PLAN.md "Cascade deletion behavior"). Unlike the
  // client's URL-by-URL delete, the Admin SDK isn't subject to the missing
  // `list`-permission limitation that forced that workaround, so this can
  // delete the whole device folder by prefix in one call.
  try {
    await admin
      .storage()
      .bucket()
      .deleteFiles({ prefix: `maintenance_devices/${deviceId}/` });
  } catch (error) {
    throw new HttpsError(
      "internal",
      `Failed to delete Storage images: ${error.message}`
    );
  }

  await db.doc(`maintenanceDevices/${deviceId}/private/sensitive`).delete();

  await db.collection("auditLogs").add({
    actingAdminUid: callerUid,
    deviceId,
    deviceModel: deviceData.model ?? null,
    customerName: deviceData.name ?? null,
    customerPhone: deviceData.phoneNumber ?? null,
    action: "permanentlyDeleteDevice",
    timestamp: FieldValue.serverTimestamp(),
  });

  await deviceRef.delete();

  logger.info("permanentlyDeleteDevice", {
    callerUid,
    deviceId,
    deviceModel: deviceData.model ?? null,
  });

  return { deviceId };
});

/**
 * Creates a new staff account (Admin, Reception, or Maintenance) — Auth
 * user + users/{uid} profile + users/{uid}/meta/staffStatus, initialized
 * active. See ADR-004 ("Staff Account Creation & Management Surface",
 * 2026-07-25).
 *
 * This is the only path that can create a staff-typed users/{uid} document:
 * the deployed Firestore rules hard-require `type == 1` on client `create`,
 * and even if they didn't, a client-side Auth user creation would sign the
 * calling Admin's own session out and into the new account. Both problems
 * are solved by doing this entirely server-side with the Admin SDK.
 *
 * Authorization mirrors setStaffStatus/permanentlyDeleteDevice: caller must
 * be Admin (users/{callerUid}.type == 0) AND the caller's own staffStatus
 * must currently be "active".
 *
 * IDENTITY MODEL — read this before changing anything below. `requestId`
 * (client-generated, one per creation attempt, resent unchanged on retry)
 * is the only thing that identifies "this attempt", never email/role
 * content: two unrelated creation attempts can legitimately share an email
 * or a role, and matching on content alone could silently resolve an
 * unrelated pre-existing account as a false "success". A durable
 * staffAccountCreationRequests/{requestId} doc is claimed atomically
 * (Firestore `create()`, not `set()`) before any Auth user is created, so
 * request identity survives even a crash before a Firestore profile exists.
 * See ADR-004's five-case table for the exact resolution rules.
 *
 * Every change writes an auditLogs entry, same as the other trusted
 * functions in this file — default-denied to all client reads/writes.
 */
exports.createStaffAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }

  const { requestId, name, email, password, type } = request.data ?? {};

  if (typeof requestId !== "string" || requestId.length === 0) {
    throw new HttpsError("invalid-argument", "requestId is required.");
  }
  if (typeof name !== "string" || name.trim().length === 0) {
    throw new HttpsError("invalid-argument", "name is required.");
  }
  if (typeof email !== "string" || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "A valid email is required.");
  }
  if (typeof password !== "string" || password.length < 8 || password.includes(" ")) {
    throw new HttpsError(
      "invalid-argument",
      "password must be at least 8 characters and contain no spaces."
    );
  }
  if (type !== 0 && type !== 2 && type !== 3) {
    throw new HttpsError(
      "invalid-argument",
      "type must be 0 (Admin), 2 (Reception), or 3 (Maintenance)."
    );
  }

  const callerUid = request.auth.uid;
  const db = admin.firestore();

  const callerSnap = await db.doc(`users/${callerUid}`).get();
  if (!callerSnap.exists || callerSnap.data().type !== 0) {
    throw new HttpsError(
      "permission-denied",
      "Only Admin may create staff accounts."
    );
  }

  const callerStatusSnap = await db
    .doc(`users/${callerUid}/meta/staffStatus`)
    .get();
  const callerStatus = callerStatusSnap.exists
    ? callerStatusSnap.data().status
    : null;
  if (callerStatus !== "active") {
    throw new HttpsError(
      "permission-denied",
      "Caller's own staff status is not active."
    );
  }

  // Claim requestId atomically. create() throws ALREADY_EXISTS (gRPC code 6)
  // if another call already claimed it — that's the expected, handled path
  // for a retry, not an error condition.
  const requestRef = db.doc(`staffAccountCreationRequests/${requestId}`);
  let requestData;
  try {
    const newRequestData = {
      email,
      type,
      name,
      callerUid,
      status: "pending",
      uid: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    await requestRef.create(newRequestData);
    requestData = newRequestData;
  } catch (error) {
    if (error.code !== 6) {
      throw new HttpsError(
        "internal",
        `Failed to claim creation request: ${error.message}`
      );
    }
    const existingSnap = await requestRef.get();
    requestData = existingSnap.data();
  }

  // Defensive: requestId reused with different content is a client bug, not
  // a legitimate retry — never act on stale/mismatched identity.
  if (requestData.email !== email || requestData.type !== type) {
    throw new HttpsError(
      "failed-precondition",
      "This requestId was already used for a different account request."
    );
  }

  // Completed same-request retry: idempotent success, no writes at all.
  if (requestData.status === "completed" && requestData.uid) {
    return { uid: requestData.uid };
  }

  let uid;
  if (requestData.status === "authCreated" && requestData.uid) {
    // Orphaned Auth user → resume, anchored strictly to this request's own
    // tracked uid — never re-derived from email, so it can never adopt an
    // unrelated request's orphan.
    try {
      await admin.auth().getUser(requestData.uid);
      uid = requestData.uid;
    } catch (error) {
      throw new HttpsError(
        "internal",
        "Tracked Auth user for this request no longer exists; cannot resume."
      );
    }
  } else {
    // Fresh claim: fast-fail pre-check for a genuinely unrelated pre-existing
    // account. Not the authoritative guard — admin.auth().createUser()'s own
    // email-already-exists error is — but gives a clean error without an
    // unnecessary Auth-create attempt in the common case.
    try {
      await admin.auth().getUserByEmail(email);
      throw new HttpsError(
        "already-exists",
        "An account with this email already exists."
      );
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      // auth/user-not-found is the expected, non-error outcome here.
    }

    let userRecord;
    try {
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: name,
      });
    } catch (error) {
      if (error.code === "auth/email-already-exists") {
        throw new HttpsError(
          "already-exists",
          "An account with this email already exists."
        );
      }
      throw new HttpsError(
        "internal",
        `Failed to create the Auth account: ${error.message}`
      );
    }
    uid = userRecord.uid;

    await requestRef.update({
      status: "authCreated",
      uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  try {
    // TEST-ONLY failure injection — must live INSIDE this try block so it
    // exercises the same catch (and compensating delete) a real Firestore
    // failure would hit; placing it before the try would bypass that catch
    // entirely. Both conditions must hold; FUNCTIONS_EMULATOR is set by the
    // Firebase emulator harness and cannot be true in a real deployed
    // function, so this is unreachable in production regardless of what a
    // caller sends. See ADR-004.
    if (
      process.env.FUNCTIONS_EMULATOR === "true" &&
      request.data.__testInjectFailure === "afterAuthBeforeFirestore"
    ) {
      throw new Error("Injected test failure (emulator only)");
    }

    const batch = db.batch();
    batch.set(db.doc(`users/${uid}`), { name, email, type });
    batch.set(db.doc(`users/${uid}/meta/staffStatus`), {
      status: "active",
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: callerUid,
    });
    batch.update(requestRef, {
      status: "completed",
      updatedAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
  } catch (error) {
    try {
      await admin.auth().deleteUser(uid);
      await requestRef.update({
        status: "pending",
        uid: null,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (cleanupError) {
      // Compensating delete itself failed — leave the tracking doc at
      // authCreated/uid so the next retry with the same requestId resumes
      // via the branch above instead of requiring manual cleanup.
      logger.error("createStaffAccount: compensating delete failed", {
        uid,
        requestId,
        cleanupError: cleanupError.message,
      });
    }
    throw new HttpsError(
      "internal",
      `Failed to initialize account data: ${error.message}`
    );
  }

  await db.collection("auditLogs").add({
    actingAdminUid: callerUid,
    targetUid: uid,
    action: "createStaffAccount",
    role: type,
    timestamp: FieldValue.serverTimestamp(),
  });

  logger.info("createStaffAccount", { callerUid, uid, type });

  return { uid };
});
