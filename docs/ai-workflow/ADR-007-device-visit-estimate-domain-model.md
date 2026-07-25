# ADR-007: Device / Visit / Estimate Domain Model

**Status:** Ratified (2026-07-25). Not yet implemented — no schema, Firestore rules, migration, or client changes exist yet.
**Date:** 2026-07-25, during the Foundational decision work following "Current Application Review & Evolution."
**Related:** `docs/product/PRD.md` (Core Entities & Identity Model; Roles as Expertise; The Relationship Timeline), `docs/product/METHODOLOGY.md` (Structural Pattern 1 *Identity Persists, Attributes Change*; Structural Pattern 2 *Sequences Carry Meaning*), `docs/ai-workflow/ADR-001-sensitive-data-separation.md`, `docs/ai-workflow/ADR-005-device-lifecycle-archive-deletion.md`, `docs/ai-workflow/ADR-006-employee-attribution.md`, `docs/ai-workflow/FORCED_UPDATE_IMPLEMENTATION_PLAN.md`, `docs/product/OPEN_DECISIONS.md`, `docs/product/ROADMAP.md`.

## Context

`maintenanceDevices` today is a single flat document conflating four distinct things: a physical Device's attributes, one repair episode's facts, a Customer's contact details as captured at intake, and a single price field overwritten at three different moments with no record of which write survived. Four product-discovery passes (2026-07-25) settled the target conceptual model without touching schema: Device identity and intake matching; Visit boundaries; the status vocabulary; the Estimate/Approval sequence. This ADR turns those settled product decisions into a concrete data model, authorization design, and migration plan, refined across three architecture pressure-test rounds covering historical-migration honesty, authorization precision, rollout safety, and ordering/lifecycle integrity.

## Decision

### 1. New top-level `devices` collection

A lightweight, persistent identity anchor — distinct from any repair episode, anchored on a system-generated internal identifier per `PRD.md`'s already-settled Core Entities model. No lifecycle field, no ownership/customer reference, no merge capability.

```
devices/{deviceId}
  brand: string?
  model: string
  colorHex: string
  imeiNumber: string?      // matching evidence only, never an identity anchor
  createdAt: timestamp
  updatedAt: timestamp
```

### 2. Naming — two layers, kept explicit

- **Firestore path (unchanged, permanent):** `maintenanceDevices`. No collection copy/rename — not justified purely for naming clarity against hundreds of production documents.
- **Domain concept (code, docs, this ADR):** Visit. Class/service-level renaming to match is a separable, non-architectural implementation-time choice, not decided here.

### 3. The `deviceId` invariant — legacy vs. new-world, and its authority boundary

- **Legacy invariant:** `deviceId` is and remains absent on every Visit created before the capability cutover (Phase 4 of the rollout). This is permanent — historical physical-device identity is genuinely unknown, and representing that honestly as absence is preferable to manufacturing false certainty in either direction (see Migration for the rejected alternatives).
- **New-world invariant:** every Visit created from the capability cutover onward must reference a Device. Enforced at the rules layer starting at Phase 6 of the rollout — not from day one, for rollout-safety reasons explained there.
- **Authorization matches current capability, not future capability:** `deviceId` may be set **only as part of Visit creation**, never via a later `update`, under any condition. This means legacy Visits stay null under current authority simply because no write path to change `deviceId` exists at all — not because of a special-cased protective rule. A future historical-linking capability, if designed, will need its own explicit write path (almost certainly a Cloud Function, mirroring `setStaffStatus`/`permanentlyDeleteDevice`/`createStaffAccount`), not a preemptively loosened client rule.

### 4. Visit — existing fields reinterpreted, not restructured

```
maintenanceDevices/{visitId}
  deviceId: string?             // see §3
  finalAmountCharged: number?   // NEW — see §5
  status: 'In Progress' | 'Awaiting Approval' | 'Ready for Handback' | 'Delivered'
  ...unchanged: name, phoneNumber, userId, brand, model, colorHex, imeiNumber,
     price (legacy — see §5), estimatedTime, problems, accessories,
     deviceStatusReceived, installedPartCodes, images, employee attribution
     fields, receivedAt/fixedAt/deliveredAt/updatedAt, recordState
```

`name`/`phoneNumber` are the customer-at-intake snapshot (coexisting with, never overwritten by, later linking to a resolved `userId`). `brand`/`model`/`colorHex`/`imeiNumber` are the device-at-intake snapshot — unchanged fields, now formally documented as point-in-time facts, independent of whatever the live `devices/{deviceId}` document says later.

### 5. `price` (legacy) vs. `finalAmountCharged` (new)

`price` was historically overwritten at intake, Fixed, and Delivered with no record of which write survived — its meaning cannot be recovered and is **not** reinterpreted. It stays as-is, displayed for historical Visits under an explicitly weaker label ("recorded amount — legacy record, exact meaning not preserved").

`finalAmountCharged` is a new, distinct field with a defined lifecycle:
- **Write authority:** staff-wide.
- **Rule-level invariant:** any write that creates or changes `finalAmountCharged` is permitted **only when the write's resulting `status` is `'Ready for Handback'`** — `request.resource.data.status == 'Ready for Handback'`. This single condition covers setting it in the same write that transitions into Ready for Handback, adjusting it further while the Visit remains in that state, and — because no write can ever set `status` back to `'Ready for Handback'` once it's `'Delivered'` (Delivered is terminal — §6) — makes the field immutable after delivery without a second clause. A write that doesn't touch `finalAmountCharged` is unaffected by this rule.
- **Ceiling invariant:** must never exceed the Visit's current Approved Estimate's `proposedAmount` (a reduction never requires new approval; an increase always does). Resolving "current Approved Estimate" is a cross-document lookup with no fixed, predictable path — the same expensive class as the interior status-transition graph (§8) — so this stays **app-layer enforced for v1**, not rules. When a Visit never had an Estimate (the optional-skip branch), there is no ceiling to check.

### 6. Legacy Visit boundary — precisely defined

**Permanent legacy facts** — never backfilled, never migrated, honestly incomplete forever:
- `deviceId` stays null on every pre-cutover Visit (§3).
- Pricing history predating `finalAmountCharged`'s existence stays in the legacy `price` field, never reinterpreted (§5).
- No Estimate is ever fabricated for a Visit's history before cutover — its `estimates` subcollection simply starts empty until (if ever) a real Estimate is created for it after cutover.

**Status vocabulary is explicitly not a permanent legacy fact.** From the capability cutover (Phase 4) onward, every status transition — including one performed on a Visit that started life under the old vocabulary — writes using the new vocabulary. A legacy Visit still open at cutover (say, sitting at `'In Maintenance'`) fully participates in the new workflow from that point on: staff can create a real Estimate for it, move it through Awaiting Approval, and it writes `'In Progress'`/`'Ready for Handback'`/`'Delivered'` exactly like a new-world Visit. Only its `deviceId`, pricing, and Estimate-history facts are treated as frozen legacy; its `status` field is not. This means many legacy Visits migrate to the new vocabulary organically, through ordinary use, before the bulk migration script ever runs.

The bulk migration (Phase 7) remains necessary regardless — it exists specifically to catch legacy Visits that never get touched again after cutover. Most importantly, every legacy Visit already sitting at `'Delivered'` (the likely largest bucket) is terminal and will never be written to again through ordinary use, so it would otherwise carry an old literal forever without the script.

### 7. Status vocabulary and transitions

Legal: intake → In Progress; In Progress → Awaiting Approval (Estimate created); Awaiting Approval → In Progress (approved); Awaiting Approval → Ready for Handback (declined, no prior Approved Estimate on this Visit); In Progress → Ready for Handback (work completed directly, or a revision declined with prior approval and staff explicitly chose to stop); Ready for Handback → Delivered.

Illegal: any transition out of Delivered (a returning device is always a new Visit); any transition out of Ready for Handback other than to Delivered (a same-day mis-mark correction is a deliberately deferred operational-safety question, not a vocabulary path).

Decline-with-prior-approval is never auto-derived — staff resolve it explicitly (an app/workflow requirement; the immutable ordered Estimate sequence just needs to make "was there ever a prior Approved Estimate?" answerable).

### 8. Estimate — immutable revision sequence, server-authoritative ordering

```
maintenanceDevices/{visitId}/estimates/{estimateId}
  proposedScope: string
  proposedAmount: number
  createdByUid: string
  createdAt: timestamp     // must equal request.time at creation
  outcome: 'pending' | 'approved' | 'declined'
  decidedByUid: string?
  decidedAt: timestamp?
  declineReason: string?
```

Whole-visit approval (no per-line-item approval in v1). No `revisionNumber` field, no mutable `isCurrent` flag.

**Ordering:** the current Estimate is the one that sorts first under **`createdAt DESC, estimateId DESC`**. `createdAt` must equal `request.time` at creation — a cheap, single-document `create`-time rule — so it can never be a client-supplied value that misorders a genuinely newer Estimate behind the one it supersedes. `estimateId` (Firestore's opaque auto-generated document ID) is a **deterministic tie-breaker only** — it carries no chronological meaning of its own; its sole purpose is guaranteeing a strict total order exists in the practically-unlikely case two Estimates land the same server timestamp, so "current" is never ambiguous.

## Final authorization matrix

| Resource | Action | Authority | Reasoning |
|---|---|---|---|
| `devices/{id}` | create | staff-wide | mirrors the receive-device overlap-zone authority Visit-create already has |
| `devices/{id}` | read | **staff-wide only — never customer** | structural prevention of cross-customer exposure through a shared Device |
| `devices/{id}` | update `brand`/`model`/`colorHex` | staff-wide | ordinary, low-stakes correction |
| `devices/{id}` | update `imeiNumber` | staff-wide | evidence, not identity — `deviceId` is the actual identity boundary |
| `devices/{id}` | delete | none (`false`) | merge/reconciliation is a separate, higher-scrutiny future capability |
| `maintenanceDevices/{id}` (Visit) | read | staff-wide, or customer where `resource.data.userId == request.auth.uid` | unchanged from today |
| `maintenanceDevices/{id}` | create | staff-wide; `deviceId` required from Phase 6 | unchanged authority, tightened requirement once safe |
| `maintenanceDevices/{id}.deviceId` | update | **none — immutable after creation** | matches current capability only |
| `maintenanceDevices/{id}.status` | update | staff-wide; rules reject once `resource.data.status == 'Delivered'`; rules reject unless new value is one of the four valid literals (from Phase 6) | terminal invariant; interior transitions stay app-trusted |
| `maintenanceDevices/{id}.finalAmountCharged` | update | staff-wide; rules permit only when `request.resource.data.status == 'Ready for Handback'` (from Phase 6) | matches §5's lifecycle exactly; ceiling-vs-Estimate stays app-layer |
| `maintenanceDevices/{id}.recordState` | update | unchanged (ADR-005) | not touched by this ADR |
| `maintenanceDevices/{id}` | delete | none (`false`) | unchanged |
| `.../estimates/{id}` | create | **Maintenance + Admin only**; `createdAt` must equal `request.time` | technical judgment can't be borrowed situationally; server-authoritative timestamp protects ordering |
| `.../estimates/{id}` | read | staff-wide, or customer where the parent Visit's `userId == request.auth.uid` | Reception needs full visibility regardless of who created it |
| `.../estimates/{id}` | update (decision recording) | staff-wide; one-time `pending → approved/declined`; other fields frozen | recording a customer's answer is coordination, not technical judgment |
| `.../estimates/{id}` | delete | none (`false`) | |

## Migration

A single script: **`migrate-status-vocabulary.js`** — rewrites the three legacy `status` literals (`In Maintenance`→`In Progress`, `Fixed`→`Ready for Handback`, `Delivered` unchanged) across every Visit that still holds one at the time it runs. Dry-run by default, `--execute` to write, idempotent, paired verify script — same shape as `migrate-recordstate.js`.

No `devices` backfill (§3/§6) and no `price`/`finalAmountCharged` migration (§5/§6) — both stay permanently legacy by design.

Rejected alternatives for historical Device identity, for the record: one Device per legacy Visit (manufactures false distinctness — asserts as many physical devices existed as there are historical records, which is almost certainly an overcount); a single shared placeholder Device for all legacy Visits (the mirror-image mistake — a wholesale false merge, the exact thing the matching asymmetry rule exists to prevent); a best-effort matching heuristic during migration (would mean designing the deferred reconciliation capability under migration time pressure, before it's been properly designed).

## Rollout

Uses the existing forced-update mechanism (`appConfig/global`, `minRequiredVersion`), paired with a manual check of the small, known set of physical staff devices (the mechanism fails open if unreachable, so it's a strong nudge, not a standalone guarantee).

1. **Additive backend only.** New `devices` collection + rules; new `estimates` subcollection + rules; `deviceId` added to the Visit model as nullable, not yet required. Nothing shipped reads or writes any of it.
2. **Bridge client.** Reads/displays both vocabularies. Writes only the old shape.
3. **Confirm bridge adoption.** Bump `minRequiredVersion`; manually confirm every device is running it.
4. **Capability client.** New required Device selection at intake, Estimate creation, Awaiting Approval — all live, including on legacy Visits still open (§6). Rules remain unchanged from Phase 1–3.
5. **Confirm capability adoption.** Bump `minRequiredVersion` again; manually confirm every device is running it.
6. **Tighten rules.** `deviceId` required on Visit `create`; `status` rejected once `Delivered` or unless a valid new literal; `finalAmountCharged` writable only when resulting `status` is `Ready for Handback`.
7. **Status-vocabulary migration.** `migrate-status-vocabulary.js --execute` → verify. Explicit approval gates `--execute`.
8. **Optional, no deadline.** Remove dual-vocabulary read compatibility whenever convenient.

**Scoping note:** this two-confirmed-cutover-gate pattern is specific to this migration, not adopted as a general rollout requirement for future features.

## Consequences / deliberately deferred

Device-level `recordState`/archive; Device merge/reconciliation, including any future historical-Visit-to-Device linking (no write path today, to be designed with its own authority when a real need emerges); Waiting for Parts as a status; Estimate decision-channel provenance; Estimate revision-relationship classification; IMEI-edit audit or elevated authority; rules-level enforcement of the interior status-transition graph and the `finalAmountCharged` ceiling-vs-Estimate check, both app-trusted for v1.
