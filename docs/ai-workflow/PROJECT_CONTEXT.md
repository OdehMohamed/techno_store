# PROJECT_CONTEXT.md

Status: reconstructed from direct source-code inspection on 2026-07-03. This file did not previously exist in the repository (no trace in git history). Everything below is either a **Fact** (directly observed in code), an **Assumption** (a plausible inference not confirmed anywhere in code or docs), an **Unknown** (a genuine open question), or a **Risk** (a concrete way things can currently go wrong). Do not treat Assumptions as Facts when making decisions — confirm with the product owner first.

## What the app is

**Facts:**
- Flutter app named `techno_store` (`pubspec.yaml`), backed entirely by Firebase: Cloud Firestore, Firebase Auth, Firebase Storage (`pubspec.yaml` dependencies; `lib/firebase_options.dart`; `firebase.json`).
- Two intertwined domains exist in the codebase:
  1. **Retail catalog** — products, categories/subcategories, brands (`lib/core/model/productModel.dart`, `category_and_sub_category_model.dart`, `brand_model.dart`, feature folder `lib/features/manage_category/`, `lib/features/store_page/`, `lib/features/product_details.dart/`).
  2. **Device maintenance workflow** — customers/employees register a device for repair; it's tracked through a status lifecycle, with photos, PIN/pattern-lock capture, technician assignment, pricing, and time-to-fix (`lib/core/model/maintenance_device_model.dart`, features `new_device_maintenance/`, `maintenance_list/`).
- Auth is phone-number OTP as the primary flow (`AuthServices.signInWithPhoneNumber` / `verifySMSCode`), plus an email/password path used for admin account creation (`AuthServices.signInWithEmailAndPassword`, feature `new_user_admin_side/`).
- New users complete a profile (name, nickname, location, photo) after phone verification, before being treated as fully onboarded (`AuthCubit.completeUserProfile`, `AuthServices.completeUserProfile`).
- Localization: `easy_localization`, locales `en` and `ar`, translation files at `assets/translations/{en,ar}.json`.
- Platforms scaffolded: Android, iOS, macOS, Linux, Windows, Web — but Android/iOS are the platforms with active native configuration changes in recent history (per current git status of `android/`, `ios/`).

**Assumptions:**
- The maintenance workflow is the actively developed part of the app (most recent commits: `feature/maintenance/list-devices`, "Assign devices on signup", "add device to list"). The retail catalog side appears comparatively static in recent history, but this has not been verified via full `git log` per-directory analysis.

**Unknowns:**
- Overall product positioning (single shop vs. multi-branch/franchise) — nothing in code indicates multi-tenancy.

## Roles and permissions

**PRODUCT-OWNER-CONFIRMED (2026-07-03) — not inferred from code:**

| `UserData.type` | Role |
|---|---|
| `0` | Admin |
| `1` | CustomerAccount |
| `2` | ReceptionAccount |
| `3` | MaintenanceAccount |
| `9` | GuestAccount |

This mapping was provided directly by the product owner and supersedes the prior "Assumptions/Unknowns" for role meaning below. It has **not yet been reflected in code** — the codebase still has no enum or named constants for these values (see Facts and Risks).

**Facts:**
- `UserData.type` (`int`, default `1`) is the only role/permission field in the data model (`lib/core/model/user_data.dart`).
- It is read via raw magic-number comparisons in at least three places: `lib/core/widgets/main_drawer2.dart` (the live drawer), `lib/core/widgets/main_drawer.dart` (confirmed dead — see Risks), and `lib/features/maintenance_list/view/inner_maintenance_list.dart` (`isEmployee = type != 1`).
- Observed values in comparisons: `0`, `1`, `2`, `3`, `9`. Only one was annotated in code: `// 9 for guest`. The full mapping above is now confirmed by the product owner, not by code.
- There is no enum, no named constants, and no central role-mapping anywhere in the codebase as of this writing — the confirmed mapping above exists only in this document until implemented.
- Permission enforcement observed in code is **UI-only** (which drawer items / widgets render). No repository-side authorization layer was found.
- `isEmployee = type != 1` in `inner_maintenance_list.dart` is consistent with the confirmed mapping: every non-`CustomerAccount` type (`Admin`, `ReceptionAccount`, `MaintenanceAccount`) is treated as staff there. Note it does **not** exclude `GuestAccount` (`9`) from being counted as "employee" by that specific check — worth flagging as a possible edge case once the role enum is implemented (a guest is presumably not staff, but this line's boolean logic would currently disagree). Not fixing this now — flagged for BACKLOG.

**Unknowns (still open):**
- Whether role is meant to gate more than navigation visibility (e.g., should it also gate which Firestore writes are allowed). The confirmed mapping tells us *what* the roles are, not yet *what each one is authorized to do*.

**Risks:**
- Because there are no Firestore/Storage security rules files found anywhere in this repository (see "Firebase data model" below), if role-based restrictions exist only in Dart UI code, any authenticated user could potentially read/write any document directly against Firestore, regardless of their `type`. This is unconfirmed — it depends on rules that may exist only in the Firebase Console, which this review had no access to. This risk is now more concrete given the confirmed mapping: e.g. it's currently unverified whether a `CustomerAccount` (`1`) could write directly to fields intended to be `MaintenanceAccount`-only (like `notesHidden`, pricing, or `installedPartCodes`) if they bypassed the UI.
- The `isEmployee` edge case noted above (`GuestAccount` counted as employee by `type != 1`) — low confirmed impact so far since no other logic depends on it yet, but should be corrected when the role model is formalized in code.

## Firebase collections and data flow

**Facts** (from `lib/core/utils/firestore_api_path.dart`, `lib/core/utils/storage_api_path.dart`, and the services that actually call Firestore):

- `users/{uid}` — `UserData` profile document.
- `users/{uid}/meta/isActivated` — separate activation flag document, merged into `UserData` client-side by `FirestoreServices.getUserData()`.
- `maintenanceDevices/{deviceId}` — the single, actual store for `MaintenanceDeviceModel`. Confirmed by reading both write paths: `NewDeviceServices.addNewDevice` / `updateDevice` write only here.
- `users/{uid}/devices/` — defined in `FirestoreApiPath.userDevices` / `userDevice`, and read by `MaintenanceListServices.fetchMaintenanceDevices` / `fetchMaintenanceDevicesPaginated`, but **nothing in the codebase writes to this subcollection** — the write calls exist in `NewDeviceServices.addNewDevice` and `CreateUserAccountServices.updateDeviceInfo` but are commented out in both places.
- Device-to-owner linking is by **phone-number match**, not by write-time association:
  - `NewDeviceServices.getUserIdByPhoneNumber` looks up `users` where `phoneNumber == device.phoneNumber` at device-creation time.
  - `CreateUserAccountServices.findUserDevices` runs the reverse lookup at signup completion, patching `userId` onto existing `maintenanceDevices` docs whose `phoneNumber` matches the new user's phone number.
- `MaintenanceDeviceModel.status` is a free-form string, not an enum. Observed vocabularies in active code:
  - Model default: `'pending'`.
  - `DeviceStatus` class constants: `'In Maintenance'`, `'Fixed'`, `'Delivered'`.
  - Switch-statement matching (lowercased) in `MaintenanceListServices`: `'in maintenance'`, `'pending'`, `'received'`, `'fixed'`, `'delivered'`, and a legacy typo `'derived'` explicitly kept "for backward compatibility."
- Storage paths: `profiles_photos/{uid}/`, `maintenance_devices/{deviceId}/{before_receiving|after_delivery}/`.
- All Firestore access is intended to route through `FirestoreServices` (`lib/core/services/firestore_services.dart`, a singleton with generic `get/set/delete/stream` helpers), but in practice `MaintenanceListServices` and `NewDeviceServices` also hold a direct `FirebaseFirestore.instance` reference and call `.collection(...)` directly in several methods — the abstraction is not used consistently.

**Risks:**
- `MaintenanceListServices.fetchMaintenanceDevices(uid)` and `fetchMaintenanceDevicesPaginated(uid: ...)` query the `users/{uid}/devices` subcollection, which — per the fact above — is never populated. **Verified**: `fetchMaintenanceDevices` is called from `MaintenanceListCubit.fetchGroupedMaintenanceDevices(uid)`, but that cubit method itself has **no call sites anywhere in the UI** (confirmed via project-wide grep). `fetchMaintenanceDevicesPaginated` has no call sites at all. So this is currently a **dormant defect, not a live bug**: it will silently return an empty device list for any given `uid` the moment someone wires it up (e.g., to a pull-to-refresh action), because they'd reasonably assume it does the same thing as the working, actually-used path (`MaintenanceListCubit.listenToMaintenanceDevices` → `MaintenanceListServices.streamMaintenanceDevices`, which correctly queries the top-level `maintenanceDevices` collection filtered by `where('userId', isEqualTo: uid)`).
- Status field's inconsistent vocabulary is a data-integrity risk: nothing enforces which strings are valid at write time, so future writes could introduce yet another variant that existing read-side switch statements don't recognize (they default to `inMaintenance` silently on unknown status, which could misclassify a device).

## Architecture / state management

**Facts:**
- Feature-first layout: `lib/features/<feature>/{view,widgets,cubit,services}`; shared code in `lib/core/`.
- State management: `flutter_bloc` Cubits paired with sealed state classes declared via `part` / `part of` (`XxxInitial` / `XxxLoading` / `XxxSuccess` / `XxxError` pattern).
- Cubits are provided per-route inside `AppRouter.onGenerateRoute` (`lib/core/route/app_router.dart`), not at the app root. Some routes forward already-instantiated cubits through `settings.arguments` and re-provide them via `BlocProvider.value`, so multiple screens can share one cubit instance across a navigation stack (e.g. `AppRoutes.maintenancePage`).
- Local caching: `CacheServices` wraps `SharedPreferences` for offline-available profile fields. `CacheServices.getUserData()` uses non-null assertions (`uid!`, `isActivated!`, `type!`). It is called from `HomeServices.getUserData()`, but only after confirming the cached `uid` matches the currently authenticated `uid` — which reduces but does not eliminate the crash risk (e.g. if `saveUserData` previously failed partway through, or wrote before the `type` field existed in an earlier app version).
- `view_model/` folders exist in a few features (`home_page`, `maintenance_list`, `new_device_maintenance`) but contain fully commented-out, unused `ChangeNotifier` code left over from a pre-Cubit pattern.
- Two near-identical drawer widgets exist: `lib/core/widgets/main_drawer.dart` and `main_drawer2.dart`. Confirmed via grep: only `MainDrawer2` is actually instantiated (`home_page.dart:91`); `MainDrawer(` appears only inside commented-out code. `main_drawer.dart` is dead code.
- No Firestore/Storage security rules files exist anywhere in this repository. The only `firestore.rules` / `storage.rules` / `firestore.indexes.json` files found are inside third-party SDK example checkouts under `build/ios/SourcePackages/...` — unrelated to this project.
- No CI configuration found. No test coverage beyond the default Flutter-generated counter widget test (`test/widget_test.dart`).

See `CLAUDE.md` at the repo root for the full architecture reference (routing, Cubit pattern, Firestore access pattern) intended for engineers/AI agents working in this repo day-to-day. This document (`PROJECT_CONTEXT.md`) is the business/domain-level companion to it.

## Sources reviewed for this document

`pubspec.yaml`, `firebase.json`, `lib/main.dart`, `lib/core/route/app_router.dart`, `lib/core/route/app_routes.dart`, `lib/core/model/user_data.dart`, `lib/core/model/maintenance_device_model.dart`, `lib/core/services/firestore_services.dart`, `lib/core/services/auth_services.dart`, `lib/core/services/cache_services.dart`, `lib/core/utils/firestore_api_path.dart`, `lib/core/utils/storage_api_path.dart`, `lib/core/widgets/main_drawer.dart`, `lib/core/widgets/main_drawer2.dart`, `lib/features/main_screen/cubit/auth_cubit.dart`, `lib/features/maintenance_list/cubit/maintenance_list_cubit.dart`, `lib/features/maintenance_list/services/maintenance_list_services.dart`, `lib/features/new_device_maintenance/cubit/new_device_cubit.dart`, `lib/features/new_device_maintenance/services/new_device_services.dart`, `lib/features/create_user_account/services/create_user_account_services.dart`, `lib/features/home_page/services/home_services.dart`, `docs/LOCATION_SYSTEM.md`, plus project-wide `grep` searches for role/status usage and call-site verification.
