# Changelog

All notable changes to this project are documented in this file. Format loosely follows [Keep a Changelog](https://keepachangelog.com/); versioning follows [Semantic Versioning](https://semver.org/). History prior to v1.0.0 predates this changelog and is not reconstructed here — see git history for that period.

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
