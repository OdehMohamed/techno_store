# ADR-005: Maintenance Device Lifecycle — Archive, Restore, Permanent Deletion

**Status:** Implemented and live in production (2026-07-24). PR #18 (backend, `1b1e7a9`), PR #19 (client cutover, `4ece686`), PR #20 (`FieldValue` hotfix, `ca84951`) — all squash-merged to `main`. Executably verified end-to-end (Firestore rules, `permanentlyDeleteDevice` Cloud Function, client UI, all local-emulator) before a coordinated production cutover: `recordState` migration executed and verified (494/494), and a real-device production smoke test against a synthetic test record passed. See `docs/ai-workflow/DECISIONS_LOG.md` (2026-07-23 and 2026-07-24 entries) for the full record.
**Date:** 2026-07-23, during the Reception & Maintenance area of "Current Application Review & Evolution."
**Related:** `docs/product/PRD.md` (Shared Foundation → The Relationship Timeline), `docs/product/OPEN_DECISIONS.md` ("Deletion recovery mechanism", "Business Authority"), `ADR-001-sensitive-data-separation.md`, `ADR-004-admin-user-management-design.md` (the `setStaffStatus` Cloud Function this design mirrors), `docs/ai-workflow/archive/phase1-execution/PHASE1_IMPLEMENTATION_PLAN.md` §"Cascade deletion behavior" (the original 2026-07-03 decision this supersedes).

## Context

The Reception & Maintenance review found that `MaintenanceListServices.deleteDevice` is a genuine, unconditional hard delete — cascading through Storage images, the `private/sensitive` subdocument, and the parent document — available to any staff role (Admin, Reception, Maintenance), for a device in any status including already-Delivered ones. This was a deliberate Phase 1 trade-off (2026-07-03), not an oversight: that plan explicitly proposed a soft-delete/audit-log design as "the natural next step if accidental-deletion incidents become a real problem in practice," deferred out of Phase 1 scope. It conflicts with `PRD.md`'s later-settled principle that ordinary removal is "recoverable by default — hidden, not destroyed," and it's the concrete case behind `OPEN_DECISIONS.md`'s still-open "who may authorize permanent deletion" question.

This ADR settles both: the mechanism for recoverable removal, and the authority boundary for permanent deletion — specifically for `maintenanceDevices`. It doesn't touch the broader "business authority" question for other actions (e.g. future refunds), which stays open.

## Decision

Split the single "Delete" action into three distinct operations with different risk profiles, authority, and architectural weight — deliberately not uniform, since the operations aren't equally risky:

### 1. Archive — the normal, reversible path

- Available to Reception, Maintenance, and Admin (staff-wide, same as today's Delete).
- Sets `recordState: 'archived'` on the device document. Does **not** touch Storage images or the `private/sensitive` subdocument — the full record is preserved exactly as-is.
- A device is a **separate field**, not a repurposed `status` value. `status` (`In Maintenance` / `Fixed` / `Delivered`) is the repair workflow vocabulary `PRD.md` deliberately keeps simple; `recordState` (`active` / `archived`) is a distinct record-lifecycle concept. Conflating them (an earlier draft of this design proposed exactly that, using `status: 'Archived'`) would have been cheaper to query but would have distorted status reporting and the repair vocabulary for a data-model convenience — rejected on that basis.
- Removes the device from all three staff tabs and the customer's own timeline (same query path, uid-scoped — see "Query impact" below) — an archived record is not part of normal product truth, staff or customer-facing.
- Archived while frozen (see below).
- Provenance: a `lifecycleEvents` subcollection entry (`type: 'archived'`, acting uid, timestamp), not a durable `auditLogs` entry and not fields duplicated onto the parent document as history. The parent document only reflects current state.

### 2. Restore — uncommon, Admin-only, still reversible

- Admin-only, enforced at the Firestore rules layer (not just an Admin-only screen — a non-Admin client attempting this write is rejected regardless of what UI it comes from).
- Sets `recordState` back to `'active'`. Because `status` was never touched by Archive, the device returns to exactly the tab it was already in — no `statusBeforeArchive` bookkeeping needed.
- Same `lifecycleEvents` provenance treatment as Archive (`type: 'restored'`), not `auditLogs`.
- No automatic expiry: an archived record stays archived indefinitely until an Admin explicitly restores or permanently deletes it. No grace-period or scheduled-cleanup mechanism exists or is planned for v1.

**Why Archive/Restore use the lighter `lifecycleEvents` subcollection, not `auditLogs`:** `auditLogs` (established by `setStaffStatus`, see `ADR-004`) denies all client reads/writes — only a Cloud Function via the Admin SDK writes it, which is what makes it tamper-resistant. Routing Archive through that collection would require Archive itself to become a Cloud Function, adding a network round-trip to what's supposed to be the fast, low-friction, everyday action. The product owner's explicit reasoning for not doing that: the three operations don't deserve equal architectural weight — Archive and Restore are both reversible, so a staff client (even a compromised one) writing a false `lifecycleEvents` entry is a low-stakes forgery of a fact that's independently checkable (the document's actual `recordState` history is what it is). The strongest guarantee is reserved for the one operation where it actually matters.

### 3. Permanent Deletion — exceptional, irreversible, Admin-only, deliberately hard to reach

- Admin-only, enforced server-side: a new `permanentlyDeleteDevice` Cloud Function, mirroring `setStaffStatus`'s shape exactly — verifies the caller is Admin *and* their own `staffStatus` is currently active (closing the same deactivated-Admin-with-a-lingering-session gap), then performs the cascade (Storage images → `private/sensitive` subdocument → parent document) via the Admin SDK.
- **Prerequisite: the target must already have `recordState == 'archived'`.** Permanent deletion is never reachable directly from the three normal staff tabs, even for Admin — a device must pass through Archive first. This is a deliberate extra checkpoint, not strictly required by "Admin-only," chosen so nothing is destroyed in a single action from a live operational view.
- Writes a durable `auditLogs` entry (device id, model, customer name/phone, acting admin uid, timestamp) **before** the parent document is deleted — this is the one operation whose provenance must survive the very record it acts on, which is exactly the property `auditLogs` (Cloud-Function-only writes) provides and a plain Firestore write couldn't.
- UI carries deliberately more friction than Archive or Restore: beyond the existing identifying-details confirmation dialog, the confirm action requires typing the device's model name (or a fixed confirmation phrase) before the delete button enables — matching common patterns for irreversible destructive actions elsewhere (e.g. repository deletion in developer tools). The goal is that Permanent Delete never feels like "the next button after Archive."

### Freezing archived records — absolute, no metadata-correction exception, for v1

While `recordState == 'archived'`, no ordinary field edit is permitted (device details, Fixed/Deliver transitions) — only Restore (Admin, back to `active`) or Permanent Deletion (Admin, via the Cloud Function) are valid next actions. Considered and rejected: a narrow exception allowing metadata correction (e.g. fixing a typo) while archived. The only constructed scenario (a correction discovered after archiving) is already served by restore → edit → re-archive, a few extra Admin clicks, without introducing an "editable-while-frozen" state to design and rule-test. If a real, concrete need for such an exception surfaces in practice, it's a small, additive change to make later — deliberately not designed against a hypothetical now (consistent with the Readiness Checks discipline used elsewhere in this project's decision process — a concrete reason, not "might be useful someday").

## Data model

`MaintenanceDeviceModel` / the Firestore document gains exactly one new field: `recordState` (`'active' | 'archived'`, absent-or-`'active'` treated identically). No `archivedAt`/`archivedByUid`/`restoredAt`/`restoredByUid` on the parent document — those facts live in `lifecycleEvents`, not duplicated onto the document as a shadow history. `status`, and everything else, is unchanged.

New subcollection: `maintenanceDevices/{deviceId}/lifecycleEvents/{eventId}` — `{ type: 'archived' | 'restored', actingUid, timestamp }`. Append-only from the client's perspective (no update/delete rule granted).

## Firestore rules impact

Replaces the current unconditional `allow update: if isStaff()` on `maintenanceDevices/{deviceId}` with three explicit branches:
- **Archive:** `isStaff()`, only when `resource.data.recordState` (defaulted to `'active'` via `.get(..., 'active')` for pre-migration documents lacking the field) is not `'archived'`, and the write sets it to `'archived'`.
- **Restore:** `isAdmin()` only, only when the existing value is `'archived'` and the write sets it back to `'active'`.
- **Ordinary edits:** `isStaff()`, only while `recordState` is not `'archived'` (the freeze).

New `lifecycleEvents/{eventId}` subcollection rules: `allow read: if isStaff()`; `create` split by the event's own `type` — `isStaff()` may create a `type == 'archived'` event, `isAdmin()` only may create a `type == 'restored'` event; no `update`/`delete` granted to any client.

`allow delete` on the parent document and on `private/{doc}` both become `false` — nothing client-side calls `.delete()` on a device anymore once Permanent Deletion is server-side-only; leaving that permission open would be unused attack surface. **Sequencing note (see "Rollout" below): this specific tightening is deliberately deferred to the second PR**, not shipped alongside the additive rules above, to avoid a window where the still-shipped client UI calls a delete path the rules no longer allow.

Storage rules: staff's `write` permission on `maintenance_devices/{deviceId}/{folder}/{fileName}` no longer needs to cover deletion once Permanent Deletion moves server-side (Admin SDK bypasses Storage rules entirely) — same deferred-to-second-PR tightening.

## Query impact

Every `MaintenanceListServices._deviceTabQuery` call (staff's three tabs, and the customer's own uid-scoped view — the same component and query path serves both) adds `.where('recordState', isEqualTo: 'active')`, unconditionally. Because Firestore equality filters don't match documents where the field is entirely absent, **every existing device must be backfilled with `recordState: 'active'` before this query change ships** — this is not optional and not something the rules' `.get(..., 'active')` default (which only applies to rules evaluation, not query matching) can paper over.

This adds `recordState` as a new field to each of the four existing composite indexes (`status`+`receivedAt`, `status`+`brand`+`receivedAt`, `status`+`maintenanceEmployee`+`receivedAt`, `userId`+`receivedAt`), plus one new index for the Archived Devices admin view (`recordState`+`archivedAt`-equivalent sort — in practice this will sort by the `lifecycleEvents` subcollection or by `receivedAt`/`updatedAt` on the parent, since no `archivedAt` field exists on the parent document per the data-model decision above; finalized at implementation). Exact index shapes are best confirmed via Firestore's own missing-index errors at deploy time, the same way the original four were derived (`SEARCH_FILTER_IMPLEMENTATION_PLAN.md`).

## Migration

A one-time script (`scripts/migration/`, alongside the existing Phase 1C sensitive-data migration scripts, sharing `lib/admin.js`) backfills `recordState: 'active'` onto every `maintenanceDevices` document currently missing it. Dry-run by default, `--execute` to write, idempotent (already-migrated documents are skipped), paired with a read-only verify script — matching the existing `migrate-pass-a.js`/`verify-pass-a.js` pattern exactly.

**Sequenced as part of final cutover, not as a step between the two PRs** (revised 2026-07-23, during PR 1's review): the product owner preferred not to touch production data until the entire vertical slice — PR 2's code included — is implemented, reviewed, and live-verified, rather than partially transitioning production data ahead of code that depends on it. This is possible because PR 2's device-creation path (`NewDeviceServices.addNewDevice`) explicitly sets `recordState: 'active'` on every newly created device, independent of the migration — so live verification of the full Archive/Restore/Permanent-Delete workflow can run against production using freshly created test devices before the migration ever runs. Pre-existing devices simply won't appear in any tab during that verification window (they lack `recordState` until the migration completes) — expected, not a bug, and harmless given PR 1's rules already treat a missing field as implicitly active for every write path, so nothing breaks, it's just temporarily invisible in list queries. See "Rollout" below for the exact order.

## Rollout (two PRs, sequenced to avoid an inconsistent intermediate state)

**PR 1 — additive only:** `permanentlyDeleteDevice` Cloud Function; `lifecycleEvents` structure and the new `recordState` transition rules (all additive — no currently-shipped client code sets or relies on `recordState`, so none of this is reachable or breaking yet); the migration + verify scripts (written and tested, not run against production as part of this PR); this ADR and the `PRD.md`/`OPEN_DECISIONS.md` reconciliation. Existing client-side delete permissions (Firestore and Storage) stay exactly as they are — removing them now, before the client stops calling them, would break the shipped "Delete" action with nothing having replaced it yet.

**PR 2 — client cutover and permission tightening, implemented and code-reviewed as one PR:** model + query updates, new device creation explicitly setting `recordState: 'active'`, new composite indexes deployed, "Delete" swipe action becomes "Archive," new Admin-only `ArchivedDevicesPage` (Restore, Permanent Delete with typed confirmation), and the parent/sensitive-subdocument/Storage client-delete permissions removed in the same change.

**Live verification (after PR 2's code review, before its production release):** exercise the complete Archive → Restore and Archive → Permanent Delete workflows against production, using freshly created test devices — real pre-existing devices are expected to be absent from the tabs during this window, per "Migration" above.

**Only once verification passes:** production backup → `migrate-recordstate.js --execute` → `verify-recordstate.js` confirms zero documents missing `recordState`. Explicit product-owner approval gates the `--execute` step — it's a live write across every real customer device record.

**Final deployment:** PR 2 merges to `main` only after migration verification passes, closing out the vertical slice as one coordinated release rather than a partial in-between state.

## Consequences

- `OPEN_DECISIONS.md`'s "Deletion recovery mechanism" and the device-deletion portion of "Business Authority" both become settled by this ADR (see the `PRD.md`/`OPEN_DECISIONS.md` update accompanying PR 1). The broader business-authority question (refunds, other future exceptional actions) remains open.
- Two Cloud Functions now share the "Admin + own-staffStatus-active" caller check (`setStaffStatus`, `permanentlyDeleteDevice`) — worth factoring into a shared helper if a third ever needs the same check, not done now (two call sites doesn't yet justify the abstraction).
- The `lifecycleEvents` subcollection is a new, permanent per-device audit surface with a deliberately weaker trust model than `auditLogs` — worth remembering if a future feature is tempted to treat it as equally tamper-resistant; it isn't, by design.
