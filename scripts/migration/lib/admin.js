const admin = require('firebase-admin');

// The GCP project these scripts always target, pinned explicitly. This
// matters now that ADC can resolve via `gcloud auth application-default
// login`: unlike a service account key file, a gcloud user credential
// carries no embedded project id, so without this we could otherwise
// silently connect to whatever project happens to be the operator's
// ambient gcloud default — not necessarily this one.
const PROJECT_ID = 'technostore-v2';

/**
 * Initializes the Firebase Admin SDK once per process using Application
 * Default Credentials (ADC). ADC resolves, in order:
 *   1. GOOGLE_APPLICATION_CREDENTIALS, if set (a service account key file)
 *   2. gcloud user credentials from `gcloud auth application-default login`
 *      — no key file needed; recommended for interactive operator use,
 *      since it avoids creating a long-lived static secret
 *   3. An attached service account, if running on GCP infrastructure
 *      (not applicable when run from an operator's local machine)
 *
 * Neither path is validated here — if neither resolves, the calling
 * script's own Firestore call will fail with a clear auth error, caught by
 * that script's top-level `.catch()`. See ../README.md for setup either way.
 *
 * Never hardcode credentials here or anywhere in this repo.
 */
function initAdmin() {
  if (admin.apps.length > 0) return admin;

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
  });

  return admin;
}

module.exports = { initAdmin };
