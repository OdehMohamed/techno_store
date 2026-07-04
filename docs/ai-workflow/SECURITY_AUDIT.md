# SECURITY_AUDIT.md

**Scope:** Security & Data Architecture Audit — Firestore, Firebase Storage, and client-side authorization as implemented in this codebase.
**Date:** 2026-07-03. **Method:** direct source inspection (every service, cubit, model, and route that touches Firebase) plus project-wide `grep` verification of call sites. No code was modified. No rules were written.
**Working assumption per instruction:** no Firestore/Storage security rules or indexes exist for this project. Nothing below assumes server-side protection unless explicitly noted as unverifiable-from-repo.

Every finding is labeled **Fact** (directly observed), **Assumption** (plausible, unconfirmed), **Unknown** (open question), or **Risk**. For permissions specifically, findings are split into **Current** (what the code allows today), **Intended** (the apparent business expectation), and **Recommended** (what should be enforced server-side) — full per-role detail is in `PERMISSIONS_MATRIX.md`; this document focuses on the narrative risk analysis.

---

## TL;DR — Critical findings

1. **CRITICAL — Client-writable role field.** `UserData.type` (the field that encodes Admin/Customer/Reception/Maintenance/Guest) is written by an ordinary client-side `Firestore.set()` call with no validation. With no security rules in place, any authenticated user can, by calling the Firestore SDK/REST API directly (bypassing the app UI), set their own `type` to `0` (Admin) and self-promote. See §5a.
2. **CRITICAL — Sensitive fields are not separable from customer-visible fields.** Device PINs, pattern locks, and internal staff notes (`pin`, `patternLock`, `notesHidden`) live in the *same* Firestore document as fields customers legitimately need to read (`status`, `price`, `model`). Firestore security rules are document-level for reads — you cannot grant read access to some fields and deny others in the same document via rules alone. See §6.
3. **HIGH — Guest role is inadvertently granted staff-level visibility in the client.** At least three places in the app gate staff-only behavior with `type != 1` (i.e., "anyone but Customer"), which includes `GuestAccount` (`9`). This means guests currently see the unrestricted, system-wide device stream, can trigger "add new device," and can see PINs/pattern locks/hidden notes in the device details UI. See §5c.
4. **HIGH — No route-level authorization exists at all.** `AppRouter.onGenerateRoute` builds any screen for any named route with no role check. Screens are only "protected" by not rendering a button that navigates to them. See §4.

---

## 1. Firestore collections and read/write patterns

**Facts** — every collection actually read or written in this codebase, with the calling code:

| Path | Read by | Written by |
|---|---|---|
| `users/{uid}` | `FirestoreServices.getUserData` (called from `AuthServices.fetchCurrentUserData`, `AuthCubit.verifySMSCode`) | `FirestoreServices.saveUserData` (called from `AuthServices.completeUserProfile`); `NewDeviceServices.getUserIdByPhoneNumber` (query, read-only) |
| `users/{uid}/meta/isActivated` | `FirestoreServices.getUserData` (one-shot); `AuthCubit._listenToActivation` (live listener) | Never written anywhere in this codebase — no code sets `isActivated`. Its only writer must be external (Console/Admin SDK/Cloud Function not present in this repo). **Unknown**: how a user is ever activated. |
| `maintenanceDevices/{deviceId}` | `MaintenanceListServices.streamMaintenanceDevices` (live, collection-wide or filtered by `userId`), `fetchMaintenanceDevices`/`fetchMaintenanceDevicesPaginated` (dormant — see `PROJECT_CONTEXT.md`), `CreateUserAccountServices.findUserDevices` (query by `phoneNumber`) | `NewDeviceServices.addNewDevice`/`updateDevice`, `CreateUserAccountServices.updateDeviceInfo` (patches `userId` only), `MaintenanceListServices.updateDeviceStatus`/`updateDeviceAsFixed`/`updateFixedDeviceDetails`/`deliverDevice`/`deleteDevice` |
| `users/{uid}/devices/` | Defined in `FirestoreApiPath` and read by the two dormant methods above | Never written (write calls exist but are commented out in both `NewDeviceServices` and `CreateUserAccountServices`) |

**Not implemented (facts, for completeness):** `FirestoreApiPath` has commented-out path builders for `products`, `shippingAddresses`, `paymentMethods`, `favorites`, `cart`. `ManageCategoriesServices` is an empty class with no methods. `ManageCategoriesCubit.loadCategories()` never calls any service. `ProductModel` is entirely commented out. The "Add new Product" drawer item has an empty `onTap: () {}`. **There is currently no live Firestore path for the retail catalog (products/categories/brands) at all** — this reduces present-day attack surface for that domain, but any rules work done now should still account for it before it's built, per `RULES.md` (prefer designing this in before launch rather than retrofitting).

**Risk:** `FirestoreServices` (the generic wrapper) and direct `FirebaseFirestore.instance` calls are both used, sometimes in the same service class (`MaintenanceListServices`, `NewDeviceServices`). This doesn't change what's possible from a rules perspective (rules apply regardless of which client-side helper is used), but it means there is no single chokepoint in the Dart code to add client-side guards even as a stopgap — rules are the only consistent enforcement point available.

## 2. Storage read/write patterns

**Facts:**
- `profiles_photos/{uid}/{uuid}` — written by `AuthServices.completeUserProfile` via `FirebaseStorageServices.uploadFile`. Filename is a random UUID, not derived from any user input (no path traversal risk from filename).
- `maintenance_devices/{deviceId}/{before_receiving|after_delivery}/{uuid}` — written by `NewDeviceServices`/`MaintenanceListServices` via the same `uploadFile` helper. `deviceId` is a Firestore-generated document ID, not user input.
- `FirebaseStorageServices.uploadFile` uploads the raw picked file with no client-side compression/resizing.
- `deleteFileByPath`/`deleteImageByUrl` exist but are **never called from `deleteDevice`** — deleting a `maintenanceDevices` document does not delete its associated Storage images. Confirmed: `MaintenanceListServices.deleteDevice` only calls `.delete()` on the Firestore document.
- No `storage.rules` file exists anywhere in this repository (only unrelated example files inside third-party SDK checkouts under `build/`).

**Risk:** Absent Storage rules, and given the folder paths are guessable (`maintenance_devices/{deviceId}/before_receiving/`, once a `deviceId` is known — which is visible in the `maintenanceDevices` Firestore documents any signed-in user can currently read per §1), any authenticated user could potentially read or overwrite another customer's device photos directly via the Storage SDK, independent of anything the app UI does.

## 3. Required permissions per role

Full per-resource, per-operation breakdown is in `PERMISSIONS_MATRIX.md`. Summary of business-relevant boundaries as best understood from code + confirmed role names (Admin=0, Customer=1, Reception=2, Maintenance=3, Guest=9):

- **Admin (0):** apparent superset — can add employees (UI entry point exists, though non-functional, see §5e), manage categories/products (UI entry point exists, non-functional), sees the full unrestricted device stream.
- **Customer (1):** should see and manage only their own profile and their own devices; should not see other customers' devices, PINs, pattern locks, or internal notes.
- **Reception (2):** sees the full device stream, can navigate to category management (Admin-parity for that feature); no evidence in code of a narrower scope than Admin for maintenance data.
- **Maintenance (3):** sees the full device stream; excluded from Store/Favorite navigation items (`type != 3` checks in `main_drawer2.dart`), suggesting a narrower, technician-focused role — but has the same unrestricted read access to all devices' sensitive fields as Admin/Reception in every code path found.
- **Guest (9):** business intent is presumably minimal/no privilege (it's the only role explicitly annotated in code, as `// 9 for guest`, and it's excluded from the Favorite drawer item). **Current code contradicts this intent** — see §5c.

**Unknown:** Whether Reception and Maintenance are meant to have identical access to sensitive device fields (PIN, pattern lock, notes) as Admin, or whether they should be scoped down (e.g., Maintenance technicians shouldn't need to see a customer's device PIN once it's already been captured by Reception at intake). This is a business question, not something inferable from code.

## 4. Current client-side permission enforcement

**Facts — every enforcement point found, all client-side only:**
- `main_drawer2.dart` — controls which drawer items render, via direct `type` comparisons (lines ~74–150).
- `main_screen.dart:60` — `listenToMaintenanceDevices(state.userData!.type == 1 ? state.userData!.uid : null)`: only Customer gets a `userId`-filtered stream; every other role gets the entire collection, unfiltered.
- `inner_maintenance_list.dart` — `isEmployee = homeState.userData.type != 1` gates the "add device" floating action button.
- `device_details_sheet.dart` — receives `isEmployee` as a parameter (sourced from the same `type != 1` check) and uses it to conditionally render `pin`, `patternLock`, and `notesHidden` in the UI.
- `AppRouter.onGenerateRoute` (`lib/core/route/app_router.dart`) — **performs no role check whatsoever** for any route, including `AppRoutes.createAccountAdminSide` (the admin-account-creation screen) and `AppRoutes.newDeviceMaintenance`. Any code that can call `Navigator.pushNamed` with these route names gets the screen built, regardless of the current user's role.

**Risk:** All of the above is "security by not showing a button." None of it is enforced anywhere the client doesn't control — not in Firestore rules (none exist), not in Cloud Functions (none exist in this repo), and not in the router. This is consistent with the audit's working assumption and confirms it should be treated as **no real enforcement exists today**.

## 5. Potential privilege escalation scenarios

**(a) CRITICAL — Self-promotion via direct Firestore write.**
`AuthServices.completeUserProfile` always constructs `UserData(..., type: 1)` (hardcoded) when a customer completes their profile through the app — that specific code path is safe by construction. But `FirestoreServices.saveUserData` → `setData` performs an unrestricted `.set()` on `users/{uid}` with whatever `UserData.toMap()` produces, and nothing anywhere validates the `type` field server-side. Any authenticated user who calls the Firestore SDK or REST API directly with their own ID token (e.g., via a Flutter Web build's browser console, a decompiled/patched mobile build, or a hand-crafted REST request) can write `{ type: 0, ... }` to their own `users/{uid}` document. Every subsequent read of their role (`AuthServices.fetchCurrentUserData`, `HomeServices.getUserData`) simply trusts whatever is stored. **This is the single highest-severity finding in this audit.**

**(b) HIGH — No route-level authorization backstop.**
Independent of (a): even if the role field were somehow tamper-proof, reaching `AppRoutes.createAccountAdminSide` or any other route today requires only calling `Navigator.pushNamed` with the right constant — trivially discoverable by reading this open-source-structured app's compiled route table. Low practical impact *today* only because the screen it leads to is non-functional (§5e) — but this is an architectural gap that would immediately matter the moment any currently-stubbed admin feature is wired up.

**(c) HIGH — Guest role granted unintended staff-level visibility (client-side logic defect, not a rules gap).**
Every `type != 1` check treats `GuestAccount` (`9`) identically to Admin/Reception/Maintenance. Concretely, today, a Guest-role account:
- Receives the entire unfiltered `maintenanceDevices` stream (`main_screen.dart:60`), i.e., every customer's device records.
- Sees the "add new device" FAB (`inner_maintenance_list.dart`).
- Sees PIN, pattern lock, and hidden staff notes in the device details sheet (`device_details_sheet.dart`), since its `isEmployee` flag is derived from the same `type != 1` logic.

This is a defect in the client's role logic itself — it would need correcting regardless of what Firestore rules eventually say, since rules would need to know to treat Guest differently from real staff, and the client would still need to stop *presenting* sensitive data to guests in its own UI even if rules happened to allow the read.

**(d) MEDIUM — Phone-number-based account/device linking has no verification against Auth identity.**
`NewDeviceServices.getUserIdByPhoneNumber` and `CreateUserAccountServices.findUserDevices` both match on a plain Firestore string field (`phoneNumber`), not on Firebase Auth's verified phone-number claim for the current session. If `phoneNumber` on `users` or `maintenanceDevices` were writable by a client without server-side validation (true today, absent rules), a user could cause devices to be linked to the wrong account, or pull another customer's device history into their own view by matching on a phone number they don't actually own.

**(e) MEDIUM (latent) — The intended admin-account-creation flow doesn't work, so its real-world replacement is unknown.**
`NewUserAdminSide`'s "Create Account" button has its actual `authCubit.signUp(...)` call commented out (`lib/features/new_user_admin_side/view/new_user_admin_side.dart:412-418`); `AuthCubit.signUp` and `AuthServices.signUpWithEmailAndPassword` are both fully commented out too. **There is currently no functional in-app path to create Admin/Reception/Maintenance accounts.** Any such accounts that exist in production today were created some other way (Firebase Console, an internal script, direct Firestore write) that is invisible to this repository. **Unknown, needs product-owner input:** what is that actual mechanism, and is it itself secured?

## 6. Data integrity risks

- **Sensitive/non-sensitive fields share one document.** `pin`, `patternLock`, and `notesHidden` sit alongside `status`, `price`, `model`, `estimatedTime` in the same `maintenanceDevices/{deviceId}` document. Firestore rules cannot grant read access to a document while hiding specific fields from specific roles — `allow read` is document-level. Achieving "Customer can read price/status but not PIN/pattern/hidden notes" **requires a data model change** (e.g., split sensitive fields into a separate document/subcollection with its own rules) or a backend redaction layer (callable Cloud Function or similar) — it cannot be done with rules alone on the current schema. This is a data-architecture decision for the product owner/tech lead to make, not a rules-writing task. Flagged here because it changes the shape of any future implementation work, not just the rules file.
- `notesHidden`'s name implies it's hidden from customers, but nothing hides it today beyond client-side conditional rendering — anyone with document read access sees it in the raw payload.
- No write-side validation anywhere (client or server) on `status` strings, `price` values (no bounds check — negative or absurd prices are structurally possible), or any other field. Combined with §5a/§5d, a malicious or buggy client can write arbitrary values to any field.
- Phone-number-based linking (§5d) is also a plain data-integrity risk independent of malicious intent — legitimate phone number reuse/reassignment (carrier recycling, customer changes number) could misattribute devices to the wrong account.
- The pre-existing `status` vocabulary inconsistency and the dormant `users/{uid}/devices` subcollection defect are documented in `PROJECT_CONTEXT.md` and are relevant here too: any rules written against the *current* schema should account for the fact that `status` values are not constrained to a known set, and that the `users/{uid}/devices` path is currently dead — writing rules for a path nothing uses would be wasted effort, or worse, would create a false sense that it's a supported access pattern.

## 7. Firebase cost risks

Summarized here; full detail in `FIREBASE_COST_REVIEW.md`. Headline risk: `streamMaintenanceDevices(null)` — the path used for every role except Customer — opens a live, unfiltered, unlimited listener on the entire `maintenanceDevices` collection, which re-delivers data to every connected staff/guest client on every single write to any device. This is a cost multiplier that scales with both collection size and concurrent staff/guest sessions.

## 8. Index requirements

Summarized here; full detail in `FIREBASE_COST_REVIEW.md`. Two composite indexes are implied by current queries (`status` + `receivedAt` on `fetchDevicesByStatus`; `userId` + `receivedAt` on the live `streamMaintenanceDevices` customer path). No `firestore.indexes.json` exists in this repo, so these indexes — if they exist at all — exist only as manually-created entries in the Firebase Console, invisible to this review. **This needs verification from the Firebase Console directly; it cannot be confirmed from the repository.**

## 9. Migration and rollout risks if rules are introduced

Because no rules exist today, **introducing any restrictive rule set is a breaking change by definition** — every access pattern documented above was built assuming unrestricted access. Specific risks to sequence around:

- **`AuthCubit._listenToActivation`'s stream has no `onError` handler.** If a future rule denies read access to `users/{uid}/meta/isActivated` for any currently-valid session (e.g., a rules bug during rollout), the stream would error rather than cleanly signal "not activated" — the app has no defined behavior for that today; it would likely surface as an unhandled exception rather than a clean sign-out. Any rules rollout must specifically test this listener.
- **The unrestricted `streamMaintenanceDevices(null)` path** (used by every non-Customer role today) will need a rule that can evaluate the caller's role. If that's implemented via a rules-side `get()` lookup of `users/{uid}` inside the `maintenanceDevices` rule (rather than custom claims), note that **rules-internal `get()`/`exists()` calls are themselves billed as document reads** — this affects the cost analysis in `FIREBASE_COST_REVIEW.md`, not just correctness.
- **Existing production documents predate any role enforcement.** If new write rules validate fields like `receivedByEmployee` against `request.auth`-derived identity, pre-existing documents (written under today's unrestrained model) may not conform, and could fail future update rules even though they're legitimate — a migration/backfill may be needed before rules go live, not after.
- **The dormant `users/{uid}/devices` subcollection** should be explicitly resolved (fixed or removed — see `BACKLOG.md` item 4) before rules are written, so effort isn't spent writing rules for a path that may not even be part of the go-forward design.
- **No automated tests exist** (`RULES.md`, `PROJECT_CONTEXT.md`) to validate rules changes against real access patterns before rollout. Recommend using the Firestore Rules simulator/emulator against the access patterns catalogued in this document and in `PERMISSIONS_MATRIX.md` as a manual test plan, since there's no existing suite to extend.

**Recommended rollout sequence (high-level; not an implementation plan):** (1) resolve the dormant subcollection and status-vocabulary issues first so rules target a stable schema; (2) decide the sensitive-field data-architecture question (§6) before writing rules for `maintenanceDevices`, since the schema itself may need to change; (3) write rules against the confirmed role mapping and the intended-behavior column of `PERMISSIONS_MATRIX.md` once the product owner confirms it; (4) validate every path in this document against the rules using the emulator/simulator; (5) roll out, watching for the activation-listener and route-navigation edge cases called out above.
