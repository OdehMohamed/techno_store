const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

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
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: callerUid,
  });

  await db.collection("auditLogs").add({
    actingAdminUid: callerUid,
    targetUid,
    field: "staffStatus",
    oldValue: previousStatus,
    newValue: status,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info("setStaffStatus", {
    callerUid,
    targetUid,
    previousStatus,
    newStatus: status,
  });

  return { status };
});
