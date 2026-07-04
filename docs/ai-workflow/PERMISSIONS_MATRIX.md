# PERMISSIONS_MATRIX.md

Companion to `SECURITY_AUDIT.md`. For every resource and operation: **Current** (what the code actually allows/does today — a Fact, verified in source), **Intended** (the apparent business expectation — labeled Assumption unless a business rule was explicitly confirmed), and **Recommended** (what should be enforced server-side once rules are written — an engineering proposal, not yet approved).

Roles (product-owner-confirmed 2026-07-03): **Admin**=0, **Customer**=1, **Reception**=2, **Maintenance**=3, **Guest**=9.

No rules exist today. "Current" below reflects the *absence* of server-side enforcement — i.e., unless stated otherwise, every role can technically perform every operation on every resource by calling Firebase directly, because nothing stops them. Where "Current (client UI)" differs from "Current (unenforced backend)", both are shown, because the gap between them *is* the risk.

---

## Resource: `users/{uid}` (profile)

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (unenforced)** | Read/write any `users/{uid}`, incl. `type` | Read/write any `users/{uid}`, incl. `type` | Read/write any `users/{uid}`, incl. `type` | Read/write any `users/{uid}`, incl. `type` | Read/write any `users/{uid}`, incl. `type` |
| **Current — client UI** | Reads/writes only its own profile via `AuthServices`/`HomeServices`; no UI to edit another user's profile | Same | Same | Same | Same |
| **Intended** *(Assumption — not explicitly confirmed)* | Read/update own profile; read other users' basic info as needed for staff workflows (name/phone on a device record); should not be able to arbitrarily set its own or others' `type` | Read/update own profile only; must never be able to set `type` | Read own profile; read customer profiles as needed for intake; should not set `type` | Read own profile; likely doesn't need to read other users' profiles beyond what's embedded in `maintenanceDevices` | Read own profile only (if guests have profiles at all — **Unknown**, see below) |
| **Recommended (server-side)** | `type` field should be **immutable from client writes entirely** (set only via Admin SDK/Cloud Function/Console) regardless of role, including Admin's own client. Allow `update` of non-role fields on own document only. | `read`/`update` own document only; explicitly deny writing `type` at the rules level (e.g., via a rule that only allows `update` if `request.resource.data.type == resource.data.type`) | Same pattern as Customer, plus read access to other `users/{uid}` docs needed for intake workflows (scope depends on product-owner answer to the field-visibility question in `SECURITY_AUDIT.md` §6) | Same as Reception, scope TBD | Deny `type` writes entirely; scope of read/write TBD pending clarification of what a Guest account actually is (see Unknowns) |

**Unknown:** What is a `GuestAccount` in this app — an anonymous/unauthenticated session, or a real Firebase Auth user with `type: 9`? `UserData` model default is `type: 1` and there's no code path observed that ever creates a `type: 9` document. This needs product-owner clarification before Guest-specific rules can be written meaningfully.

---

## Resource: `users/{uid}/meta/isActivated`

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (unenforced)** | Read/write any user's activation flag | Read/write any user's activation flag (including their own — self-activation) | Same | Same | Same |
| **Current — client UI** | No UI writes this field anywhere in the codebase | Same (read-only, via `AuthCubit._listenToActivation`) | Same | Same | Same |
| **Intended** *(Assumption)* | Can activate/deactivate other users (this is presumably an Admin/Reception gatekeeping mechanism, given the name and that `AuthCubit` signs a user out if it becomes `false`) | Should never be able to set their own activation status | Likely can activate customers (Unknown, needs confirmation) | Likely no reason to touch this | Should never be able to set this |
| **Recommended (server-side)** | Allow `write` only for Admin (and possibly Reception, pending confirmation); the acting user must never be able to set their own `isActivated` to `true` if it's currently `false` | Read-only, own document only | TBD pending confirmation of whether Reception activates accounts | Deny write | Deny write |

**Risk restated from SECURITY_AUDIT.md:** nothing in this repository writes `isActivated` at all — its current write mechanism (if any) is entirely outside this codebase. Recommended rules above assume the intended writer is a staff role, but this must be confirmed, not assumed, since the actual mechanism is unverified.

---

## Resource: `maintenanceDevices/{deviceId}` — general fields

*(`name`, `phoneNumber`, `brand`, `model`, `colorHex`, `problems`, `status`, `accessories`, `deviceStatusReceived`, `price`, `estimatedTime`, `additionalNotes`, `imagesBeforeReceiving`, `imagesAfterDelivery`, `assignedTechnicianId`, `receivedByEmployee`, `deliveredByEmployee`, `maintenanceEmployee`, `installedPartCodes`, `receivedAt`, `deliveredAt`, `fixedAt`, `timeToFix`, `userId`)*

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (unenforced)** | Full read/write on any document | Full read/write on any document (not just their own) | Full read/write on any document | Full read/write on any document | Full read/write on any document |
| **Current — client UI** | Full CRUD via `MaintenanceListServices`/`NewDeviceServices`, no ownership filter (`main_screen.dart:60` passes `uid: null`) | Read-only view, **filtered to own `userId`** via `streamMaintenanceDevices(uid)`; can create a new device intake for themselves (`new_device_maintenance` feature is reachable from... **Unknown**: no drawer entry currently routes a Customer into `new_device_maintenance` — the "Maintenance (My Devices)" drawer item for Customer has an empty `onTap: () {}` in `main_drawer2.dart:96`. **The customer-facing device view is currently unreachable from the primary navigation**, even though the underlying `streamMaintenanceDevices(uid)` plumbing works.) | Full CRUD, no ownership filter | Full CRUD, no ownership filter | Full CRUD, no ownership filter (same unfiltered stream as staff — see SECURITY_AUDIT.md §5c) |
| **Intended** *(Assumption, consistent with role names)* | Full CRUD on all devices | Read-only, own devices only; create new intake requests for themselves; should not edit status/price/assignment | Full CRUD on all devices (front-desk intake, status updates, delivery) | Full CRUD on all devices, or possibly scoped to devices `assignedTechnicianId == self` — **Unknown, needs confirmation** | No access, or read-only on nothing (guests shouldn't see any customer's device data) |
| **Recommended (server-side)** | Allow all operations | Allow `read` only where `resource.data.userId == request.auth.uid`; allow `create` of a new document where the new document's `userId`/`phoneNumber` corresponds to the caller; deny `update`/`delete` entirely (status/price/assignment changes should be staff-only) | Allow all operations (pending confirmation this matches business intent) | Allow all operations, or scope `update` to documents where `assignedTechnicianId == request.auth.uid` if the narrower model is confirmed | Deny all operations |

---

## Resource: `maintenanceDevices/{deviceId}` — sensitive fields

*(`pin`, `patternLock`, `notesHidden`)* — called out separately because, per `SECURITY_AUDIT.md` §6, **Firestore rules cannot grant differential field-level read access within the same document.** The rows below describe what's *displayed*, which is a distinct question from what's *readable* once rules are added — this table exists to make clear that fixing the "recommended" column here requires a data model change, not just a rules change.

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (unenforced)** | Full read/write | Full read/write (same document as above — no field separation exists) | Full read/write | Full read/write | Full read/write |
| **Current — client UI display** | Shown (`isEmployee == true`) | Hidden (`isEmployee == false` for Customer) | Shown | Shown | **Shown** — Guest's `isEmployee` evaluates `true` because it's derived from `type != 1` (see SECURITY_AUDIT.md §5c) |
| **Intended** *(Assumption, strongly implied by field naming: "notesHidden", PIN/pattern being device-unlock credentials)* | Should see | Should never see | Should see (captured at intake) | Should see (needed to service device) | Should never see |
| **Recommended (server-side)** | N/A at rules level — see note below | **Cannot be enforced via Firestore rules on the current schema.** Requires moving `pin`, `patternLock`, `notesHidden` into a separate document/subcollection (e.g., `maintenanceDevices/{id}/private/{doc}`) with rules restricting it to staff roles only, or serving customer-facing reads through a backend function that redacts these fields before returning data. | N/A | N/A | Must be excluded once the data model changes; until then, no rule can prevent Guest (or any role) from reading these fields if they can read the parent document at all |

---

## Resource: Storage — `profiles_photos/{uid}/`

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (unenforced)** | Read/write any user's profile photos | Read/write any user's profile photos (not just own) | Same | Same | Same |
| **Current — client UI** | No UI reads/writes another user's photo path | Writes only own photo during profile completion | No UI interaction | No UI interaction | No UI interaction |
| **Intended** *(Assumption)* | Possibly read-only access to any profile photo (e.g., displayed alongside a device record); shouldn't need to write others' photos | Read/write own photo only | Read others' photos (displayed in staff views), not write | Same as Reception | No access |
| **Recommended (server-side)** | Allow `read`; allow `write` only to own path | Allow `read`/`write` only to `profiles_photos/{request.auth.uid}/*` | Allow `read` broadly, deny `write` outside own path | Same as Reception | Deny |

---

## Resource: Storage — `maintenance_devices/{deviceId}/{before_receiving|after_delivery}/`

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (unenforced)** | Read/write any device's images | Read/write any device's images (not just own) | Same | Same | Same |
| **Current — client UI** | Full read/write via `NewDeviceServices`/`MaintenanceListServices` | Read-only display in device details sheet, for own devices (subject to the same unreachable-navigation caveat noted above) | Full read/write | Full read/write | Full read/write — same unfiltered access as staff |
| **Intended** *(Assumption)* | Full access | Read own device's images only; should not write (photos are captured by staff at intake/delivery, per the model's field naming `receivedByEmployee`/`deliveredByEmployee`) | Full access (intake photos) | Full access (repair/delivery photos) | No access |
| **Recommended (server-side)** | Allow all | Allow `read` only where the corresponding Firestore document's `userId == request.auth.uid` (requires a `get()` check in Storage rules against Firestore — confirm cross-product rule support and its cost/latency implications); deny `write` | Allow all | Allow all | Deny |

**Also flagged in `SECURITY_AUDIT.md` §2:** deleting a `maintenanceDevices` document never deletes its associated Storage files today, for any role — an orphaned-data/cost issue independent of the permission question, tracked further in `FIREBASE_COST_REVIEW.md`.

---

## Resource: Retail catalog (products, categories, brands) — not yet implemented

No live Firestore or Storage path exists for this domain (see `SECURITY_AUDIT.md` §1). Documenting the **intended** shape now so rules can be designed in from the start rather than retrofitted:

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current** | N/A — not implemented | N/A | N/A | N/A | N/A |
| **Intended** *(Assumption, from the "Add new Product"/"Manage Categories" drawer items being gated to `type == 0 \|\| type == 2`)* | Full CRUD | Read-only (browsing the store) | Full CRUD | Likely no access (Maintenance is excluded from Store navigation via `type != 3` in `main_drawer2.dart`) | Read-only, or no access (Unknown — depends on whether guests can browse the store) |
| **Recommended (server-side, once built)** | Allow all | Allow `read` only, public or authenticated-read depending on business decision; deny all writes | Allow all | Deny, pending confirmation | Allow `read` only if guest browsing is intended; otherwise deny |

---

## Cross-cutting notes

- **Guest role definition is the single biggest open input needed.** Nearly every "Recommended" cell for Guest above is provisional because it's unclear whether `GuestAccount` represents an actual authenticated Firebase user with limited scope, or something closer to anonymous/unauthenticated browsing. This should be resolved before any rules are drafted, since it changes whether Guest-specific rules are even meaningful (`request.auth` may not exist for a true anonymous visitor).
- **The Customer→own-devices navigation is currently a dead link** (`main_drawer2.dart:96`, empty `onTap`). This is a product/UX gap independent of security, but it's worth the product owner knowing: even once rules correctly scope Customer reads to their own devices, there is currently no way for a customer to reach that screen through the app's primary navigation.
- Every "Recommended" column above is an engineering proposal for discussion, not an approved design — per `RULES.md`, no rules will be implemented until the product owner confirms the "Intended" business expectations that are currently marked as Assumptions.
