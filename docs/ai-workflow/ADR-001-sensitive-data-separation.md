# ADR-001: Sensitive Maintenance Data Separation

**Status:** Approved and implemented (Option A — subcollection under the device). Shipped as part of Phase 1B, 2026-07-03. See `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` and the 2026-07-03 entries in `docs/ai-workflow/DECISIONS_LOG.md` for the confirmed outcome.
**Date:** 2026-07-03
**Related:** `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md` §6, `docs/ai-workflow/PERMISSIONS_MATRIX.md` (maintenanceDevices — sensitive fields)

## Context

`maintenanceDevices/{deviceId}` is a single flat Firestore document holding ~25 fields, including:
- Customer-visible fields: `status`, `price`, `model`, `brand`, `estimatedTime`, `additionalNotes`, `imagesBeforeReceiving`, `imagesAfterDelivery`.
- Sensitive fields: `pin`, `patternLock`, `notesHidden` (internal staff notes).

**Product-owner clarification (2026-07-03):** customers must **never** view `pin`, `patternLock`, or `notesHidden` after submitting them — including the customer who submitted their own device. This is stronger than a typical "owner can read their own record" rule: it's a permanent, role-based denial regardless of ownership.

Firestore security rules evaluate `allow read` at the **document level**. A rule cannot say "let this caller read `status` and `price` but not `pin` and `patternLock`" within a single `get`/`list` on one document — if a role can read the document at all, it gets every field in it. This means the current schema is structurally incompatible with the confirmed business requirement, independent of how well any rule is written. A schema change (or a backend intermediary that never lets the client read the raw document at all) is required.

## Current schema (fact)

```
maintenanceDevices/{deviceId}
  ├─ userId, name, phoneNumber                     (identity)
  ├─ brand, model, colorHex, imeiNumber             (device info)
  ├─ pin, patternLock                               ← SENSITIVE
  ├─ problems, status, accessories, deviceStatusReceived
  ├─ notesHidden                                    ← SENSITIVE
  ├─ additionalNotes                                (customer-visible)
  ├─ price, estimatedTime
  ├─ imagesBeforeReceiving, imagesAfterDelivery
  ├─ assignedTechnicianId, receivedByEmployee, deliveredByEmployee, maintenanceEmployee, installedPartCodes
  └─ receivedAt, deliveredAt, fixedAt, timeToFix, updatedAt
```

Written by `NewDeviceServices.addNewDevice`/`updateDevice` (full document via `MaintenanceDeviceModel.toJson()`); read by `MaintenanceListServices.streamMaintenanceDevices` and displayed conditionally (client-side only) in `device_details_sheet.dart`.

## Options considered

### Option A — Move sensitive fields to a subcollection under the same device

`maintenanceDevices/{deviceId}/private/security` holding `pin`, `patternLock`, `notesHidden`. The parent document keeps everything else.

- **Pros:** Firestore rules trivially express "deny all client reads of this subcollection except staff roles" independent of the parent document's rules (subcollection rules are written and evaluated separately — this is exactly what Firestore's document model is designed for). Keeps sensitive data physically scoped under its owning device in the data model, which is intuitive to navigate. No new infrastructure (no Cloud Functions) required. Customer-facing real-time listeners on the parent document are untouched.
- **Cons:** Requires a one-time data migration (see below). Every write path that currently sets these three fields must be updated to write to the subcollection instead. Staff-facing reads that need both the device and its sensitive data require two reads (or a client-side join) instead of one. **Firestore does not cascade-delete subcollections when the parent document is deleted** — `deleteDevice` would need to be updated to explicitly delete the subcollection document too, or the sensitive data becomes orphaned (a new instance of the exact class of bug already found in Storage cleanup, per `FIREBASE_COST_REVIEW.md` §2 — worth fixing both at once).

### Option B — Move sensitive fields to a separate top-level collection

`deviceSecurityData/{deviceId}` (same document ID as the corresponding `maintenanceDevices/{deviceId}`, but not a subcollection).

- **Pros:** Same rules-expressiveness benefit as Option A. Rules for this collection are visually and structurally obvious as "a wholly separate, independently-secured resource" in the rules file, reducing the chance a future engineer mistakes it for inheriting the parent's permissions. Decouples this data's lifecycle from the device record — e.g., if a future compliance requirement calls for auto-expiring stored PINs/pattern locks after a device is delivered (a reasonable data-minimization practice for device-unlock credentials), that's simpler to implement against an independent collection than a nested one.
- **Cons:** Same migration and write-path-update cost as Option A. Same orphan-on-delete risk as Option A (deleting the parent `maintenanceDevices` doc does not delete the sibling `deviceSecurityData` doc either — must be handled explicitly in both options). Requires deliberately keeping document IDs in sync between the two collections (a convention to enforce in one service method, not a structural guarantee).

### Option C — Keep one document; redact sensitive fields via a backend intermediary (Cloud Function)

Clients never read `maintenanceDevices` directly; a callable Cloud Function returns a role-appropriate, redacted view.

- **Pros:** No schema change, no migration, single source of truth.
- **Cons:** Requires introducing Cloud Functions to a project that has none today (build/deploy pipeline, cold starts, monitoring — a materially bigger infrastructure commitment than a schema change). Breaks the currently-used real-time `snapshots()` listener pattern for customers — a callable function is request/response, not a live stream, so customer-facing "watch my device status update live" would need re-architecting (e.g., polling, or a separate realtime mechanism). **Does not eliminate the need for Firestore rules anyway**: unless direct client reads of the raw `maintenanceDevices` collection are also denied by rules, a customer could bypass the function entirely and read the unredacted document straight from the Firestore SDK. Since rules are required either way, this option is strictly more work than A/B for the same outcome, not less.

### Option D — Keep one document; encrypt sensitive fields client-side

Store `pin`/`patternLock`/`notesHidden` as ciphertext; only staff clients hold the decryption key.

- **Pros:** No schema restructuring.
- **Cons:** Key management is a real unsolved problem here — a key bundled in the staff app binary can be extracted; a proper per-user wrapped-key scheme is significant cryptographic engineering, well beyond what a Firestore rule accomplishes for the same problem. This also doesn't address the actual root cause (access control), since Firestore already encrypts data at rest server-side — the risk here is *who can read the field*, not *whether it's stored in plaintext at the infrastructure level*. Not recommended as a primary fix; could be considered later as an additional defense-in-depth layer on top of A/B, not a replacement for them.

## Recommendation

**Option A** (subcollection under the device), as the primary recommendation, with **Option B** as an acceptable alternative if independent data-retention/lifecycle policies for PINs/pattern locks become an explicit future requirement — that's the one scenario where B's decoupling clearly earns its slightly higher structural distinctness.

Rationale: A and B are very close in cost and both correctly solve the stated requirement; C is dominated by A/B (strictly more infrastructure for no reduction in required rules work); D doesn't address the actual problem. Given this codebase has no Cloud Functions today and the goal is to close a confirmed CRITICAL/HIGH-severity gap with the smallest reliable change, a schema split (A or B) enforced by Firestore rules is the right-sized solution.

## Consequences

- `MaintenanceDeviceModel` needs to be split into two models (or the sensitive fields extracted into a new model), and every read/write site that currently touches `pin`, `patternLock`, or `notesHidden` needs to be updated in lockstep: `NewDeviceServices.addNewDevice`/`updateDevice` (writes), `device_details_sheet.dart` (reads/displays for staff).
- `deleteDevice` must be updated to also delete the corresponding sensitive-data document (subcollection or sibling collection) — otherwise this recreates the same orphaned-data pattern already found for Storage images.
- Firestore rules for `maintenanceDevices` (customer-visible fields) and the new sensitive-data location can now be written independently and correctly — this was not possible on the current schema.
- Any future retail-catalog or reporting feature that reads `maintenanceDevices` for aggregate/analytics purposes will no longer risk incidentally exposing PINs/pattern locks/notes, since they won't be present in that document at all.

## Migration risks

- **Data migration required.** A one-time script (Admin SDK, run by a trusted operator — not a client-facing feature) must copy `pin`, `patternLock`, `notesHidden` from every existing `maintenanceDevices` document into the new location, verify the copy, and only then strip those fields from the parent document. Copy-then-verify-then-strip (not delete-and-recreate) to avoid data loss if the script has a bug.
- **Write-path inventory.** All call sites that currently set these three fields must be identified and updated together — doing this piecemeal risks a window where some devices have sensitive data in the old location and others in the new one, with reads inconsistently finding it.
- **Deployment sequencing.** Rules and code must be coordinated: if new rules (denying `pin`/`patternLock`/`notesHidden` on the parent document) go live before the code stops writing them there, writes will start failing; if code stops writing them to the old location before rules are updated, nothing breaks security-wise but the old fields simply go stale — the safer sequence is code-writes-both-locations briefly, or a single coordinated deploy window, given this is an internal-tooling-style app without strict staged mobile rollout constraints.
- **This must happen before `maintenanceDevices` rules are written**, not after — per `SECURITY_AUDIT.md` §9's recommended rollout sequence, rules should target the final schema, not the interim one.

## Open questions for product owner

- Preference between Option A (subcollection) and Option B (sibling collection) — either is acceptable; A is the default recommendation absent a stated need for independent retention policy on this data.
- Should there be a data-retention/expiration policy for `pin`/`patternLock` (e.g., purge after device delivered + N days)? This doesn't need to be answered before implementing the split, but affects whether B's independent-lifecycle advantage is worth prioritizing now versus later.
