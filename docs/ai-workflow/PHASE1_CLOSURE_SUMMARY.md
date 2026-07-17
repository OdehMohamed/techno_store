# PHASE1_CLOSURE_SUMMARY.md

**Status: Phase 1 closed, 2026-07-04.** This is the capstone reference for the whole effort — what shipped, what was verified, and what's explicitly deferred. See the linked documents for full detail; this is the map, not the territory.

## What Phase 1 was

A security and data-architecture remediation, triggered by a baseline audit (`SECURITY_AUDIT.md`) that found: no Firestore/Storage security rules existed at all, device PINs/pattern locks/staff notes were stored inline alongside customer-visible fields with no way to restrict them via rules, role permissions were enforced only by which UI buttons happened to render, and a `GuestAccount` role was inadvertently receiving staff-level data access.

## What shipped

- **ADR-001–004**: sensitive-data schema separation, role-immutability design, GuestAccount handling, future admin-panel design (deferred).
- **Phase 1A**: client-side role-check fixes (`UserRole` allow-list helper, GuestAccount exposure fixed, `completeUserProfile` type-preservation fix).
- **Phase 1B**: sensitive-data schema split (`maintenanceDevices/{id}/private/sensitive`), cascade delete (Storage + subdocument + parent, with confirmation UX and idempotent retries), migration scripts prepared.
- **Phase 1C**: executed against production in five gated checkpoints —
  - **Checkpoint 0**: backups verified (managed export + JSON dump, both in `gs://technostore-v2-firestore-backups/`), inventory taken (N=430, M=85).
  - **Checkpoint 1**: Pass A run and verified (85/85, 0 mismatches, 20-device human spot-check confirmed).
  - **Checkpoint 2**: Pass B run and verified (84 stripped after a legitimate device deletion during the live window reduced M from 85→84 — root-caused precisely, not assumed). Final state: N=432, M=0.
  - **Checkpoint 3**: `firestore.rules`/`storage.rules` deployed to `technostore-v2` and independently verified byte-for-byte against the live Firebase Rules API. Composite index question (open since the original audit) resolved: confirmed present and `READY`.
  - **Checkpoint 4**: functional validation performed by the product owner directly against the live app across all roles — confirmed working as expected.

## Explicitly deferred (tracked, not forgotten)

1. **Direct/bypass-the-UI authorization testing** — functional validation confirmed the *app* behaves correctly; it did not test whether the *deployed rules themselves* correctly deny a client that skips the UI and calls Firestore/Storage directly. This is the specific guarantee Phase 1's rules exist to provide, and it remains unverified at that level. See `BACKLOG.md` item 0a. *(As documented at Phase 1 closure, this was "must be completed before any public production release." Superseded 2026-07-09: product owner accepted this as a residual risk rather than a release blocker — see `BACKLOG.md` item 0a and the corresponding `DECISIONS_LOG.md` entry for the current status and rationale.)*
2. **One orphaned `private/sensitive` subdocument** (device `Sd7A3a1jMByVEy9vKcfP`, deleted outside the app's cascade-delete flow — likely a direct Console deletion, which never cascades to subcollections). Inert, blocks nothing, but should be cleaned up. See `BACKLOG.md`.
3. Everything already tracked pre-Phase-1 and not in scope: `ADR-002` Phase 2 (Custom Claims), `ADR-004`'s admin user-management feature, field-level write validation, the dormant `users/{uid}/devices` subcollection, `status` vocabulary cleanup.

## Where things are, for whoever picks this up next

- Rules: live in production, committed to the repo (`firestore.rules`, `storage.rules`, `firebase.json`).
- Migration scripts: `scripts/migration/` (kept for reference / any future similar migration; not needed for ongoing operation).
- All planning/audit/decision history: `docs/ai-workflow/` —
  - **Active:** `RULES.md`, `PERMISSIONS_MATRIX.md` (kept current, refreshed against deployed rules), `ADR-001` through `ADR-004`, `DECISIONS_LOG.md` (full chronological record).
  - **Archived** (2026-07-17, historical reference only — each carries a status banner): `archive/phase1-audit/PROJECT_CONTEXT.md`, `archive/phase1-audit/SECURITY_AUDIT.md`, `archive/phase1-audit/FIREBASE_COST_REVIEW.md`, `archive/phase1-execution/PHASE1_IMPLEMENTATION_PLAN.md`, `archive/phase1-execution/PRE_DEPLOYMENT_BACKUP_PLAN.md`, `archive/phase1-execution/MIGRATION_SUCCESS_CRITERIA.md`, `archive/phase1-execution/PHASE1C_EXECUTION_RUNBOOK.md`.
