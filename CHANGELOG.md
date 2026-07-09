# Changelog

All notable changes to this project are documented in this file. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versioning follows [Semantic Versioning](https://semver.org/). History prior to v1.0.0 predates this changelog and is not reconstructed here — see git history for that period.

## [1.1.0] - 2026-07-09

Three new features and a set of auth/storage fixes on top of the Phase 1 security foundation. Not Shorebird-patchable — this release adds native plugin dependencies (`package_info_plus`), so it requires a full new store build rather than a patch against 1.0.0.

### Added
- **Forced app update mechanism**: a Firestore-driven version gate (`appConfig/global`), enforced after Firebase Auth resolves. Fails open on any config-read or version-comparison error, so a Firestore hiccup or missing document can never block real users. The existing `in_app_update` integration is retained as a non-blocking Android nudge, no longer the enforcement path.
- **Maintenance devices search & filtering (v1)**: per-tab bounded Firestore queries (replacing a single unbounded, all-statuses stream) with structured filters (brand, maintenance employee, received date range) and client-side search (name, phone, model, IMEI). Swipe navigation between tabs is preserved; each tab lazily starts its own query only once first viewed.
- Four new Firestore composite indexes supporting the above.

### Changed
- Home page: the promotional carousel banner and Contact Us footer are now hidden for staff users (Admin/Reception/Maintenance); customers and guests see the existing experience unchanged.
- Maintenance device cards are slightly more compact, fitting more on screen with no information removed.
- The "New Device" floating action button now respects the platform safe area (gesture bar / home indicator) plus a comfortable margin, instead of a fixed offset.
- "Load more" on the maintenance devices list now appears as the natural last item of the list and preserves scroll position, instead of a button fixed below the grid.

### Fixed
- Storage image upload/delete authorization failures for staff, caused by a Storage rules limitation where cross-service role lookups don't resolve during `list`-operation evaluation, and a double-slash path bug in image uploads.
- A signup regression where profile completion attempted to write to a client-forbidden path, plus a related crash on an incompletely-populated auth state.
- Devices received by staff before a customer registered are now automatically linked to that customer's account once they sign up, via a new Cloud Function reading the Auth-verified phone number directly.
- A logout bug where the maintenance devices stream could remain active with an invalidated session.
- Customer account creation now requires the stored phone number to match the Auth-verified phone, closing a spoofing gap in device-to-customer linking.

### Internal
- `flutter analyze` was silently scanning a stray native-build artifact (a full companion Dart monorepo checked out locally into `build/ios/SourcePackages/checkouts/` by Xcode/SPM), inflating the reported issue count roughly 100x with false positives. Fixed by excluding `build/` from analysis; the project's real baseline is 48 pre-existing issues, unchanged by this release.

### Known follow-ups (tracked, not blocking this release)
- Direct/bypass-the-UI authorization testing against the deployed rules — deferred as an accepted risk for this release (internal/closed testing distribution); still required before any public store release.
- `MaintenanceListCubit`'s action methods don't propagate service-layer failures to callers, so a failed save/delete/deliver can still show a success message — tracked, not fixed here.

## [1.0.0] - 2026-07-04

This release marks the completion of the project's initial development phase and the establishment of its security foundation: a full security & data-architecture audit, remediation, and a deployed, verified permissions model, along with a permanent Git/GitHub workflow for all future work.

### Security
- Replaced role-based deny-list checks (`type != 1`) with explicit allow-lists throughout the app, fixing a defect where `GuestAccount` was inadvertently treated as staff — granted the unfiltered, system-wide device stream, the add-device action, and visibility into every customer's PIN, pattern lock, and internal notes.
- Fixed `AuthServices.completeUserProfile` unconditionally hardcoding a user's role to Customer on every write; it now preserves an existing role and only defaults for genuinely new profiles.
- Separated sensitive device fields (PIN, pattern lock, internal notes) out of the main device record into a dedicated, staff-only subcollection, so they can never be exposed to a customer — including the customer who submitted their own device — regardless of any other access granted to that record.
- Deployed Firestore and Storage security rules for the first time in this project's history, enforcing role-based access control at the database and storage layer rather than relying solely on client-side UI logic.
- Migrated all existing production device records (432 documents) to the new schema with zero data loss, verified independently via multiple methods before and after each step.

### Added
- Cascade delete for device records: deleting a device now removes its Storage images, sensitive-data subdocument, and parent record together, with confirmation UX and idempotent retry handling.
- Centralized `UserRole` helper for role checks, replacing scattered magic-number comparisons.
- Migration tooling (`scripts/migration/`) for the schema migration described above, supporting dry-run, verification, and safe re-entry.
- A permanent Git/GitHub workflow (`CONTRIBUTING.md`), covering the full feature lifecycle: planning, branching, a sensitive-files & secrets policy, commit and PR standards, merge strategy, release process, and technical debt handling.
- Full engineering documentation trail for this security effort under `docs/ai-workflow/` (audit, architecture decision records, implementation plans, migration runbook, and decision log).

### Fixed
- `.gitignore` gaps that left the Android app signing keystore and a local production-data backup directory unprotected from being accidentally committed.

### Known follow-ups (tracked, not blocking this release)
- Direct/bypass-the-UI authorization testing against the deployed rules — required before any public store release.
- One orphaned sensitive-data subdocument from a device deleted outside the app's normal flow — inert, scheduled for routine cleanup.

See `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` for the full detail behind this release.
