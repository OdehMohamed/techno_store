# PERMISSIONS_MATRIX.md

Companion to `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md`. For every resource and operation: **Current** (what the code actually allows/does today — a Fact, verified in source), **Intended** (the apparent business expectation — labeled Assumption unless a business rule was explicitly confirmed), and **Recommended** (the original engineering proposal for what should be enforced server-side — largely adopted by the rules actually deployed in Phase 1; see each "Current — backend" row for what's enforced today, since Recommended is retained here as historical design rationale, not a live proposal).

Roles (product-owner-confirmed 2026-07-03): **Admin**=0, **Customer**=1, **Reception**=2, **Maintenance**=3, **Guest**=9.

**Refreshed 2026-07-17.** Firestore and Storage security rules were deployed to production as part of Phase 1 (2026-07-04) and are committed to this repo (`firestore.rules`, `storage.rules`) — every "Current — backend (deployed rules)" row below is read directly from those files, not inferred or assumed. "Current — client UI" rows have also been re-verified directly against today's source, reflecting both the Phase 1A allow-list refactor (`lib/core/utils/user_role.dart`) and the 2026-07-09 search/filter rewrite that replaced the old unbounded `streamMaintenanceDevices` with bounded per-tab queries (`MaintenanceListServices.streamDevicesForTab`/`fetchMoreDevicesForTab`). Where "Current — client UI" differs from "Current — backend," both are shown, because the gap between them is what a role can technically do vs. what the app's UI actually lets them do.

---

## Resource: `users/{uid}` (profile)

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (deployed rules)** | Read: own profile, or any profile (`isStaff()`). Create: own uid only, `type` must be `1`, `phoneNumber` must match the Auth-verified phone — self-signup path only, not usable to provision an Admin account. Update: own profile only; `type` is immutable via any client write, including Admin's own. Delete: denied. | Read: own profile only (not staff). Create: own uid, `type: 1`, phone must match Auth-verified phone — the actual signup path. Update: own profile only; `type` immutable. Delete: denied. | Same as Admin (staff read-all; create/update/delete identical — so this path also cannot self-provision a Reception account). | Same as Admin/Reception. | Read: own profile only (not staff). Create/update: same constraints as Customer — no rule or code path produces a `type: 9` document. Delete: denied. |
| **Current — client UI** | Reads/writes only its own profile via `AuthServices`/`HomeServices`; no UI to edit another user's profile | Same | Same | Same | Same |
| **Intended** *(Assumption — not explicitly confirmed)* | Read/update own profile; read other users' basic info as needed for staff workflows (name/phone on a device record); should not be able to arbitrarily set its own or others' `type` | Read/update own profile only; must never be able to set `type` | Read own profile; read customer profiles as needed for intake; should not set `type` | Read own profile; likely doesn't need to read other users' profiles beyond what's embedded in `maintenanceDevices` | Read own profile only (if guests have profiles at all — **Unknown**, see below) |
| **Recommended (server-side)** | `type` field should be **immutable from client writes entirely** (set only via Admin SDK/Cloud Function/Console) regardless of role, including Admin's own client. Allow `update` of non-role fields on own document only. | `read`/`update` own document only; explicitly deny writing `type` at the rules level (e.g., via a rule that only allows `update` if `request.resource.data.type == resource.data.type`) | Same pattern as Customer, plus read access to other `users/{uid}` docs needed for intake workflows (scope depends on product-owner answer to the field-visibility question in `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md` §6) | Same as Reception, scope TBD | Deny `type` writes entirely; scope of read/write TBD pending clarification of what a Guest account actually is (see Unknowns) |

**Unknown:** What is a `GuestAccount` in this app — an anonymous/unauthenticated session, or a real Firebase Auth user with `type: 9`? `UserData` model default is `type: 1` and there's no code path observed that ever creates a `type: 9` document. This needs product-owner clarification before Guest-specific rules can be written meaningfully.

---

## Resource: `users/{uid}/meta/isActivated`

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (deployed rules)** | Read: own doc, or any (`isStaff()`). Write: denied for every role via any client write, including Admin's own — matches the confirmed manual Console workflow, which uses IAM access outside these rules and is unaffected. | Read: own doc only. Write: denied. | Read: own or any (staff). Write: denied. | Read: own or any (staff). Write: denied. | Read: own doc only (not staff). Write: denied. |
| **Current — client UI** | No UI writes this field anywhere in the codebase | Same (read-only, via `AuthCubit._listenToActivation` — still unwired into the sign-in flow, `BACKLOG.md` item 10) | Same | Same | Same |
| **Intended** *(Assumption)* | Can activate/deactivate other users (this is presumably an Admin/Reception gatekeeping mechanism, given the name and that `AuthCubit` signs a user out if it becomes `false`) | Should never be able to set their own activation status | Likely can activate customers (Unknown, needs confirmation) | Likely no reason to touch this | Should never be able to set this |
| **Recommended (server-side)** | Allow `write` only for Admin (and possibly Reception, pending confirmation); the acting user must never be able to set their own `isActivated` to `true` if it's currently `false` | Read-only, own document only | TBD pending confirmation of whether Reception activates accounts | Deny write | Deny write |

**Risk restated from docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md:** nothing in this repository writes `isActivated` at all — its current write mechanism (if any) is entirely outside this codebase. Recommended rules above assume the intended writer is a staff role, but this must be confirmed, not assumed, since the actual mechanism is unverified.

---

## Resource: `maintenanceDevices/{deviceId}` — general fields

*(`name`, `phoneNumber`, `brand`, `model`, `colorHex`, `problems`, `status`, `accessories`, `deviceStatusReceived`, `price`, `estimatedTime`, `additionalNotes`, `imagesBeforeReceiving`, `imagesAfterDelivery`, `assignedTechnicianId`, `receivedByEmployee`, `deliveredByEmployee`, `maintenanceEmployee`, `installedPartCodes`, `receivedAt`, `deliveredAt`, `fixedAt`, `timeToFix`, `userId`)*

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (deployed rules)** | Full read; create/update/delete allowed (`isStaff()`). | Read: own devices only (`resource.data.userId == request.auth.uid`), query must be shaped to match. Create/update/delete: denied. | Full read; create/update/delete allowed (staff-wide, uniform with Admin/Maintenance — not narrowed to intake-only). | Full read; create/update/delete allowed (staff-wide, not scoped to `assignedTechnicianId`). | Denied entirely — no read, no write. |
| **Current — client UI** | Full CRUD via `MaintenanceListServices`/`NewDeviceServices`. Device list uses bounded, per-tab queries (`streamDevicesForTab`/`fetchMoreDevicesForTab`, replacing the old unbounded `streamMaintenanceDevices`, removed 2026-07-09). `UserRole.isStaff(type)` → `isEmployee=true` (`inner_maintenance_list.dart`) → `uid: null` passed to the query → full/broader result set for the active status tab, with optional brand/employee/date-range filters plus client-side text search. FAB (new device) and Edit/Deliver/Delete slide actions all shown. | Read-only, **filtered to own `userId`** (`isEmployee=false` → `uid` = own uid). Reachable today via the Home page's embedded "Maintenance" tab (`home_page.dart`), shown unconditionally for every role — **not** via the drawer's dedicated "Maintenance (My Devices)" item, which remains a dead link (`main_drawer2.dart`, empty `onTap`, confirmed still true 2026-07-17). No FAB, no slide actions — create/edit/delete unavailable in the UI. | Full CRUD, same as Admin. | Full CRUD, same as Admin/Reception. | **Changed since the original audit.** Guest no longer falls through to the unfiltered staff-wide query — `UserRole.isStaff(9)` is false, so Guest gets the identical narrow code path as Customer (`isEmployee=false`, query filtered to Guest's own `userId`), which matches no real devices in practice (nothing assigns device ownership to a guest account), so the list renders empty. No FAB, no slide actions, no staff drawer entry. |
| **Intended** *(Assumption, consistent with role names)* | Full CRUD on all devices | Read-only, own devices only; create new intake requests for themselves; should not edit status/price/assignment | Full CRUD on all devices (front-desk intake, status updates, delivery) | Full CRUD on all devices, or possibly scoped to devices `assignedTechnicianId == self` — **Unknown, needs confirmation** | No access, or read-only on nothing (guests shouldn't see any customer's device data) |
| **Recommended (server-side)** | Allow all operations | Allow `read` only where `resource.data.userId == request.auth.uid`; allow `create` of a new document where the new document's `userId`/`phoneNumber` corresponds to the caller; deny `update`/`delete` entirely (status/price/assignment changes should be staff-only) | Allow all operations (pending confirmation this matches business intent) | Allow all operations, or scope `update` to documents where `assignedTechnicianId == request.auth.uid` if the narrower model is confirmed | Deny all operations |

---

## Resource: `maintenanceDevices/{deviceId}` — sensitive fields

*(`pin`, `patternLock`, `notesHidden`)* — called out separately because, per `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md` §6, **Firestore rules cannot grant differential field-level read access within the same document.** The rows below describe what's *displayed*, which is a distinct question from what's *readable* once rules are added — this table exists to make clear that fixing the "recommended" column here requires a data model change, not just a rules change.

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (deployed rules)** | Full read/write on the `private/sensitive` subdocument (`isStaff()`). | Denied entirely, including for their own device — no ownership exception, per explicit product-owner instruction (`ADR-001`). | Full read/write (staff-wide). | Full read/write (staff-wide). | Denied entirely. |
| **Current — client UI display** | Shown (`isEmployee == true` via `UserRole.isStaff`) — the sensitive-data fetch (`MaintenanceDeviceSensitiveDataService`) is only called `if (isEmployee)`; PIN, pattern lock, hidden notes, staff-assignment fields, and installed part codes are all gated `if (isEmployee)` in `device_details_sheet.dart`. | Hidden (`isEmployee == false`) — the sensitive-data fetch is never called. | Shown | Shown | **Fixed since the original audit.** Now hidden — `isEmployee == false` since `UserRole.isStaff(9)` is false (Guest is excluded from the allow-list). The audit's original finding (Guest's `isEmployee` evaluating `true` via the old deny-list, `type != 1`) no longer holds. |
| **Intended** *(Assumption, strongly implied by field naming: "notesHidden", PIN/pattern being device-unlock credentials)* | Should see | Should never see | Should see (captured at intake) | Should see (needed to service device) | Should never see |
| **Recommended (server-side)** | N/A at rules level — see note below | **Cannot be enforced via Firestore rules on the current schema.** Requires moving `pin`, `patternLock`, `notesHidden` into a separate document/subcollection (e.g., `maintenanceDevices/{id}/private/{doc}`) with rules restricting it to staff roles only, or serving customer-facing reads through a backend function that redacts these fields before returning data. | N/A | N/A | Must be excluded once the data model changes; until then, no rule can prevent Guest (or any role) from reading these fields if they can read the parent document at all |

---

## Resource: Storage — `profiles_photos/{uid}/`

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (deployed rules)** | Read: own path, or any (`isStaff()` = type 0/2/3). Write: own path only — this rule checks only `request.auth.uid == uid`, not role. | Read: own path only (not staff). Write: own path only. | Read: own or any (staff). Write: own path only. | Read: own or any (staff). Write: own path only. | Read: own path only (not staff — Storage's `isStaff()` recognizes only 0/2/3, same as Firestore's). Write: own path only — **permitted by the rule as written** (it isn't role-gated), though no client UI code exercises this for Guest today (see client UI row). |
| **Current — client UI** | No UI reads/writes another user's photo path | Writes only own photo during profile completion | No UI interaction | No UI interaction | No UI interaction |
| **Intended** *(Assumption)* | Possibly read-only access to any profile photo (e.g., displayed alongside a device record); shouldn't need to write others' photos | Read/write own photo only | Read others' photos (displayed in staff views), not write | Same as Reception | No access |
| **Recommended (server-side)** | Allow `read`; allow `write` only to own path | Allow `read`/`write` only to `profiles_photos/{request.auth.uid}/*` | Allow `read` broadly, deny `write` outside own path | Same as Reception | Deny |

---

## Resource: Storage — `maintenance_devices/{deviceId}/{before_receiving|after_delivery}/`

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current — backend (deployed rules)** | Read/write any device's images (`isStaff()` = 0/2/3). | Read: own device's images only, cross-referenced via a Storage-rules `firestore.get()` on the parent `maintenanceDevices/{deviceId}.userId`. Write: denied. | Read/write any device's images (staff). | Read/write any device's images (staff). | Read: denied (not staff; and even if attempted, Guest's own devices never match any `maintenanceDevices.userId`, so the ownership check never succeeds). Write: denied (not staff). |
| **Current — client UI** | Full read/write via `NewDeviceServices`/`MaintenanceListServices` — write paths (image pick/upload) are only reachable through staff-gated UI (the FAB for create, Edit/Deliver slide actions — `DeviceCard` only renders slide actions `if (isEmployee)`). | Read-only display in device details sheet (`DeviceDetailsSheet._buildImageSection`, not itself `isEmployee`-gated — any device the query surfaced is fully viewable), for own devices only, reachable via the Home page's embedded tab (same reachability caveat as the general-fields row). No write UI — no slide actions render for non-staff. | Full read/write, same as Admin. | Full read/write, same as Admin/Reception. | The same read-only viewer code as Customer is technically present, but never exercised in practice — Guest's device query matches no real devices (see general-fields row), so there are no images to display. No write UI (not staff). |
| **Intended** *(Assumption)* | Full access | Read own device's images only; should not write (photos are captured by staff at intake/delivery, per the model's field naming `receivedByEmployee`/`deliveredByEmployee`) | Full access (intake photos) | Full access (repair/delivery photos) | No access |
| **Recommended (server-side)** | Allow all | Allow `read` only where the corresponding Firestore document's `userId == request.auth.uid` (requires a `get()` check in Storage rules against Firestore — confirm cross-product rule support and its cost/latency implications); deny `write` | Allow all | Allow all | Deny |

**Resolved since the original audit.** Deleting a `maintenanceDevices` document now cascades to delete its associated Storage images (Storage images → `private/sensitive` subdocument → parent document, in that order) as part of Phase 1's cascade-delete implementation — see `ADR-001`'s Consequences and `PHASE1_CLOSURE_SUMMARY.md`. One residual gap remains and is tracked separately, not here: `BACKLOG.md` item 0c — an image uploaded but never referenced in its device document (e.g., from a partially failed upload) is not discoverable for cleanup by this path.

---

## Resource: Retail catalog (products, categories, brands) — not yet implemented

No live Firestore or Storage path exists for this domain (see `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md` §1). Documenting the **intended** shape now so rules can be designed in from the start rather than retrofitted:

| Operation | Admin | Customer | Reception | Maintenance | Guest |
|---|---|---|---|---|---|
| **Current** | N/A — not implemented | N/A | N/A | N/A | N/A |
| **Intended** *(Assumption, from the "Add new Product"/"Manage Categories" drawer items being gated to `isAdmin \|\| isReception`)* | Full CRUD | Read-only (browsing the store) | Full CRUD | Likely no access (Maintenance is excluded from the Store drawer item's `isAdmin \|\| isCustomer \|\| isReception` allow-list in `main_drawer2.dart` — simply not listed, not a `type != 3` deny-list) | Read-only, or no access (Unknown — depends on whether guests can browse the store; also excluded from that same allow-list today) |
| **Recommended (server-side, once built)** | Allow all | Allow `read` only, public or authenticated-read depending on business decision; deny all writes | Allow all | Deny, pending confirmation | Allow `read` only if guest browsing is intended; otherwise deny |

---

## Cross-cutting notes

- **Guest role definition is the single biggest open input needed.** Nearly every "Recommended" cell for Guest above is provisional because it's unclear whether `GuestAccount` represents an actual authenticated Firebase user with limited scope, or something closer to anonymous/unauthenticated browsing. This should be resolved before any rules are drafted, since it changes whether Guest-specific rules are even meaningful (`request.auth` may not exist for a true anonymous visitor).
- **The Customer→own-devices dedicated drawer item is still a dead link** (`main_drawer2.dart`, empty `onTap`, confirmed unchanged as of 2026-07-17). This no longer means customers/guests cannot view a device list at all, though: the Home page's embedded "Maintenance" tab (`home_page.dart`) is shown unconditionally to every role and already applies the correct own-`userId` scoping, so a customer can see their own devices there today — just not via the drawer's dedicated shortcut.
- Every "Recommended" column above is the original engineering proposal — largely adopted by the rules deployed in Phase 1 (see each "Current — backend" row for what's actually enforced today). Retained here as historical design rationale, not a live proposal awaiting approval.
