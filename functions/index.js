const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

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
