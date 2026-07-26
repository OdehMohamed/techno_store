# ADR-007: Device / Visit / Estimate Domain Model

**Status:** Ratified (2026-07-25), with the Device Matching / Deduplication Policy addendum, the Technical Finding / Pending Revision Resolution correction and its write-authority ratification (2026-07-25), and the per-Estimate resolution refinement — embedded shape, no-new-Estimate-while-unresolved invariant, history-anchored qualification, and server-authoritative `decidedAt`/`resolvedAt` (2026-07-26). All surfaced during Status Narrative Copy discovery. **Phase 1 (additive `devices`/`estimates` Firestore rules) implemented, executably verified (86/86, `test/firestore-rules/`), and deployed to production `technostore-v2` (2026-07-26, PR #26, merge commit `4f9e853`).** **Phase 2 (Bridge Client) implemented, executably verified (91/91, `test/firestore-rules/`; 6/6, `test/core/utils/device_status_test.dart`), and merged to `main` (2026-07-26, PR #27, merge commit `dc879ee`) — deliberately not deployed/distributed to staff, since it isn't released independently under the clarified rollout (see Rollout).** **Rollout sequence reconciled (2026-07-26) against that clarified deployment strategy — the original two-gate design collapses to one; see Rollout for the revised 7-step sequence.** **The two implementation-adjacent dependencies flagged 2026-07-25 — IMEI/serial normalization, and the customer-known-Devices query design — are now resolved (2026-07-26); see the Addendum's two continuation sections.** Steps 3–7 not started; step 3 (capability-client implementation) no longer has an undesigned dependency blocking it.
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
  imeiNumber: string?             // matching evidence only, never an identity anchor
  imeiNumberNormalized: string?   // NEW (2026-07-26) — derived from imeiNumber, see Addendum
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
     fields, receivedAt/deliveredAt/updatedAt, recordState
```

`name`/`phoneNumber` are the customer-at-intake snapshot (coexisting with, never overwritten by, later linking to a resolved `userId`). `brand`/`model`/`colorHex`/`imeiNumber` are the device-at-intake snapshot — unchanged fields, now formally documented as point-in-time facts, independent of whatever the live `devices/{deviceId}` document says later.

**Correction (2026-07-25) — `fixedAt` is retired as a concept, replaced by two new Visit-level facts; storage shape not yet settled.** A Status Narrative Copy pressure-test found that neither `status` nor Estimate outcome can reliably answer "what did the technical work establish," especially when an approved scope was completed but a separately-proposed, later revision was declined — the two facts below are new, not merely a rename:

- **Technical Finding** — a small, closed set: *Repaired* / *No Fault Found* / *Fault Found, Not Repaired*. Independent of both `status` and Estimate outcome. Set once, via an explicit staff action — preserving today's existing behavioral pattern (`fixedAt` today is already set only through one dedicated "mark complete" action, never inferred from status or Estimate history); only the meaning and name are corrected, not the mechanism.
- **Technical-work-concluded-at** — the timestamp paired with the above. `fixedAt`'s old meaning implicitly assumed the conclusion was always a successful repair; the corrected concept is broader — when the technical work/diagnostic process concluded, regardless of which of the three Technical Finding outcomes it reached. One timestamp honestly covers all three.

No general "why didn't repair happen" field is introduced. When Technical Finding is *Fault Found, Not Repaired*, the reason is already answerable from the Estimate sequence (a declined Estimate on record → customer declined); the rarer case — a fault found with no Estimate ever created because nothing viable was offered — is left as free text (`additionalNotes`) rather than formalized, consistent with not building structure for a case that hasn't earned it.

**Write authority (2026-07-25):** Maintenance + Admin only — matching Estimate-creation authority exactly, on the same "who actually knows enough to assert this truthfully" test. Reception retains read access (via the existing whole-document Visit read rule) and continues to perform the Ready-for-Handback → Delivered handback transition, but never asserts either fact itself. See the Final authorization matrix.

### 5. `price` (legacy) vs. `finalAmountCharged` (new)

`price` was historically overwritten at intake, Fixed, and Delivered with no record of which write survived — its meaning cannot be recovered and is **not** reinterpreted. It stays as-is, displayed for historical Visits under an explicitly weaker label ("recorded amount — legacy record, exact meaning not preserved").

`finalAmountCharged` is a new, distinct field with a defined lifecycle:
- **Write authority:** staff-wide.
- **Rule-level invariant:** any write that creates or changes `finalAmountCharged` is permitted **only when the write's resulting `status` is `'Ready for Handback'`** — `request.resource.data.status == 'Ready for Handback'`. This single condition covers setting it in the same write that transitions into Ready for Handback, adjusting it further while the Visit remains in that state, and — because no write can ever set `status` back to `'Ready for Handback'` once it's `'Delivered'` (Delivered is terminal — §6) — makes the field immutable after delivery without a second clause. A write that doesn't touch `finalAmountCharged` is unaffected by this rule.
- **Ceiling invariant — precision correction (2026-07-25):** must never exceed the amount of the Visit's **governing Approved Estimate** — the latest Estimate whose *outcome* is Approved, which is not necessarily the same Estimate as the positionally-current one (§8's "current" is purely positional — latest by ordering — regardless of outcome). A later revision can be Declined and still be positionally current while an earlier Approved Estimate remains the actual authorization boundary; this is exactly the shape the Pending Revision Resolution correction (§7) walks through, and the two terms are kept deliberately distinct rather than used interchangeably. A reduction against the governing Approved Estimate never requires new approval; an increase always does. Resolving the governing Approved Estimate is a cross-document lookup with no fixed, predictable path — the same expensive class as the interior status-transition graph (§8) — so this stays **app-layer enforced for v1**, not rules. When a Visit never had an Estimate (the optional-skip branch), there is no ceiling to check.

### 6. Legacy Visit boundary — precisely defined

**Permanent legacy facts** — never backfilled, never migrated, honestly incomplete forever:
- `deviceId` stays null on every pre-cutover Visit (§3).
- Pricing history predating `finalAmountCharged`'s existence stays in the legacy `price` field, never reinterpreted (§5).
- No Estimate is ever fabricated for a Visit's history before cutover — its `estimates` subcollection simply starts empty until (if ever) a real Estimate is created for it after cutover.

**Status vocabulary is explicitly not a permanent legacy fact.** From the capability cutover (Phase 4) onward, every status transition — including one performed on a Visit that started life under the old vocabulary — writes using the new vocabulary. A legacy Visit still open at cutover (say, sitting at `'In Maintenance'`) fully participates in the new workflow from that point on: staff can create a real Estimate for it, move it through Awaiting Approval, and it writes `'In Progress'`/`'Ready for Handback'`/`'Delivered'` exactly like a new-world Visit. Only its `deviceId`, pricing, and Estimate-history facts are treated as frozen legacy; its `status` field is not. This means many legacy Visits migrate to the new vocabulary organically, through ordinary use, before the bulk migration script ever runs.

The bulk migration (Phase 7) remains necessary regardless — it exists specifically to catch legacy Visits that never get touched again after cutover. Most importantly, every legacy Visit already sitting at `'Delivered'` (the likely largest bucket) is terminal and will never be written to again through ordinary use, so it would otherwise carry an old literal forever without the script.

### 7. Status vocabulary and transitions

Legal: intake → In Progress; In Progress → Awaiting Approval (Estimate created); Awaiting Approval → In Progress (approved); Awaiting Approval → Ready for Handback (declined, no prior Approved Estimate on this Visit); In Progress → Ready for Handback (work completed directly, or — see the correction below — a revision declined with prior approval, resolved to stop); Ready for Handback → Delivered.

Illegal: any transition out of Delivered (a returning device is always a new Visit); any transition out of Ready for Handback other than to Delivered (a same-day mis-mark correction is a deliberately deferred operational-safety question, not a vocabulary path).

**Correction (2026-07-25) — the decline-with-prior-approval window is a real gap in the four-state vocabulary, not an app-layer detail.** The original text above silently assumed the "declined, resolved to continue/stop" case resolves instantaneously, without saying how a Visit gets from "a revision was just declined" back to a legal status at all. It doesn't, necessarily: during any real delay between the decline and staff's resolution, none of the four status values is honestly true — not Awaiting Approval (the customer already decided), not In Progress (nothing has resumed), not Ready for Handback (nothing's been decided to stop). Pressure-testing delayed resolution, app restart, and staff handoff confirmed this is a genuine, durable condition a Visit can sit in for real, findable spans of time — not a rendering nuance.

The four-state vocabulary itself is **not** expanded to cover it. Instead, a concrete, narrowly-scoped condition exists whenever a later Estimate revision is declined while an earlier Estimate on the same Visit was already Approved. While it holds, it takes precedence over `status` as the honest answer to "what's happening" — `status` isn't overridden or falsified, the Visit simply carries an additional fact layered over whatever `status` last meaningfully held. It resolves to exactly one of two outcomes — *continue under the prior approved scope* (→ Visit returns to In Progress) or *stop* (→ Visit proceeds to Ready for Handback). This is deliberately **not** a general "blocked pending staff decision" abstraction reusable for other future conditions — it is scoped to this one concrete business condition until a second real scenario demonstrates an abstraction is actually shared.

**Correction, refined (2026-07-26) — the resolution is embedded per qualifying Estimate, not a separate Visit-level fact.** An earlier draft of this correction described a single fact living on the Visit. That's wrong once multiple Estimate revisions are allowed: the qualifying condition can recur more than once on the same Visit, and a single mutable Visit-level fact would silently overwrite an earlier occurrence's resolution the moment a later one arose — the exact historical-truth violation Structural Pattern 2 exists to prevent, and the same failure mode this whole domain model was built to close for `status` and `price`.

Resolution instead lives directly on the qualifying Estimate itself (§8): three additional fields — `resolutionOutcome`, `resolvedByUid`, `resolvedAt` — present only on a Declined Estimate that qualifies, transitioning exactly once (`null → 'continue'/'stop'`), then frozen. The association between a resolution and the Estimate it belongs to is structural, not referential — there is nothing to point back to, because the fact lives on the record it concerns. Every qualifying occurrence on a Visit is preserved independently; resolving a later one never touches an earlier one's own resolution.

**Qualification is history-anchored, not live-state-anchored.** A Declined Estimate qualifies for resolution only if, among Estimates on the same Visit positioned earlier in the immutable ordered sequence (§8's `createdAt`/`estimateId` ordering), at least one has `outcome == 'approved'`. This is a pure function of the sequence strictly before the Estimate in question — never "does an Approved Estimate happen to exist right now" — so it gives the identical, correct answer whether evaluated at the moment of decline, at resolution, or at any later audit, since an already-decided Estimate's outcome can never change.

**No new Estimate may be created while a qualifying declined Estimate is unresolved.** While any Estimate on a Visit has `outcome == 'declined'`, qualifies, and `resolutionOutcome == null`, Estimate creation on that Visit is blocked. Two independently-unresolved things — a customer decision pending on a new proposal, and a staff decision pending on an existing decline — would otherwise coexist on the same Visit with no single truthful answer to what its operative state is, and no way to tell two simultaneously-true-but-contradictory stories ("nothing needed from you" and "please decide") at once. This closes a genuine workflow ambiguity, not merely a rendering inconvenience. Enforced at the **app layer for v1** — the same cost/value boundary already drawn for the `finalAmountCharged` ceiling and the interior status-transition graph, since it's a cross-document check against sibling Estimates, not a single-document rule.

**The resolution (continue/stop) is independent of Technical Finding (§4) and must never be treated as determining it.** Pressure-testing confirmed this matters concretely: resolving to "stop" doesn't necessarily mean nothing was repaired (the earlier approved scope may already have been completed before the revision was even proposed — Technical Finding would then still be *Repaired*), and resolving to "continue" doesn't guarantee a successful outcome either. Each fact is set independently, by its own explicit action, and may combine with the other however reality actually produced.

**Write authority (2026-07-25, updated 2026-07-26):** the condition's *existence* is not a separately authorized action — it arises automatically from the already-staff-wide Estimate decline-recording write (§8) whenever that decline qualifies. *Resolving* it — continue or stop — is Maintenance + Admin only: correctly judging whether previously-approved work remains viable, or even that a decline is unrelated to it, requires the same technical competence as diagnosis itself, which Reception cannot reliably substitute for. Admin holds identical authority to Maintenance here, since this is the technical-expertise boundary, not a separate business-authority operation. See the Final authorization matrix.

**Implementation concern, resolved by construction (2026-07-26):** an earlier draft flagged a transaction/consistency risk — a decline write leaving the Visit without its resulting resolution fact. Embedding resolution on the same Estimate document being declined removes this risk entirely: there is no separate fact a partial write could omit, since `resolutionOutcome` starts `null` on the very document the decline write already touches.

### 8. Estimate — immutable revision sequence, server-authoritative ordering

```
maintenanceDevices/{visitId}/estimates/{estimateId}
  proposedScope: string
  proposedAmount: number
  createdByUid: string
  createdAt: timestamp     // must equal request.time at creation
  outcome: 'pending' | 'approved' | 'declined'
  decidedByUid: string?
  decidedAt: timestamp?    // must equal request.time on the decision write — 2026-07-26
  declineReason: string?
  resolutionOutcome: 'continue' | 'stop' | null   // NEW (2026-07-26) — see §7 correction
  resolvedByUid: string?                          // NEW (2026-07-26)
  resolvedAt: timestamp?                          // must equal request.time on the resolution write — NEW (2026-07-26)
```

Whole-visit approval (no per-line-item approval in v1). No `revisionNumber` field, no mutable `isCurrent` flag, no separate resolution collection.

**Ordering:** the current Estimate is the one that sorts first under **`createdAt DESC, estimateId DESC`**. `createdAt` must equal `request.time` at creation — a cheap, single-document `create`-time rule — so it can never be a client-supplied value that misorders a genuinely newer Estimate behind the one it supersedes. `estimateId` (Firestore's opaque auto-generated document ID) is a **deterministic tie-breaker only** — it carries no chronological meaning of its own; its sole purpose is guaranteeing a strict total order exists in the practically-unlikely case two Estimates land the same server timestamp, so "current" is never ambiguous.

**Decision and resolution timestamps are also server-authoritative (2026-07-26).** `decidedAt` must equal `request.time` on the decision-recording write; `resolvedAt` must equal `request.time` on the resolution write — the same rule and reasoning as `createdAt`. These stopped being passive provenance once the narrative model began deriving customer-visible behavior directly from the elapsed time between them (composing a decline and its resolution into one moment, versus inserting an interim reassurance) — that behavior depends on knowing the real gap, not a client-supplied value.

**Resolution fields are a second, independently-gated one-time transition on the same document (2026-07-26)** — distinct from `outcome`'s own transition. `resolutionOutcome` may only move `null → 'continue'/'stop'` when `outcome` is already `'declined'` and the Estimate qualifies (§7 correction); once set, it is frozen, exactly like `outcome` itself. The core proposal fields (`proposedScope`, `proposedAmount`, `createdByUid`, `createdAt`) stay frozen from creation throughout, untouched by either transition — this doesn't relax or conflict with the existing "other fields frozen" rule on decision-recording, it adds a second, differently-gated, differently-authorized one-time transition alongside it.

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
| `maintenanceDevices/{id}.technicalFinding` / `.technicalWorkConcludedAt` | update | **Maintenance + Admin only** (2026-07-25) | technical judgment can't be borrowed situationally — matches Estimate-creation authority exactly; Reception reads via the existing whole-document Visit read rule, never writes |
| `maintenanceDevices/{id}.recordState` | update | unchanged (ADR-005) | not touched by this ADR |
| `maintenanceDevices/{id}` | delete | none (`false`) | unchanged |
| `.../estimates/{id}` | create | **Maintenance + Admin only**; `createdAt` must equal `request.time`; blocked while any Estimate on the Visit is Declined, qualifies, and unresolved (2026-07-26) | technical judgment can't be borrowed situationally; server-authoritative timestamp protects ordering; the precondition prevents two independently-unresolved conditions coexisting on one Visit |
| `.../estimates/{id}` | read | staff-wide, or customer where the parent Visit's `userId == request.auth.uid` | Reception needs full visibility regardless of who created it |
| `.../estimates/{id}` | update (decision recording) | staff-wide; one-time `pending → approved/declined`; `decidedAt` must equal `request.time` (2026-07-26); other fields frozen | recording a customer's answer is coordination, not technical judgment |
| `.../estimates/{id}` | update (resolution recording) | **Maintenance + Admin only** (2026-07-26); one-time `null → 'continue'/'stop'`, only when `outcome == 'declined'` and the Estimate qualifies (§7); `resolvedAt` must equal `request.time`; other fields frozen | judging whether previously-approved work remains viable, or that a decline is unrelated to it, requires the same technical competence as diagnosis; Admin's authority here is identical to Maintenance's — the technical-expertise boundary, not business authority |
| `.../estimates/{id}` | delete | none (`false`) | |

## Migration

A single script: **`migrate-status-vocabulary.js`** — rewrites the three legacy `status` literals (`In Maintenance`→`In Progress`, `Fixed`→`Ready for Handback`, `Delivered` unchanged) across every Visit that still holds one at the time it runs. Dry-run by default, `--execute` to write, idempotent, paired verify script — same shape as `migrate-recordstate.js`.

No `devices` backfill (§3/§6) and no `price`/`finalAmountCharged` migration (§5/§6) — both stay permanently legacy by design.

Rejected alternatives for historical Device identity, for the record: one Device per legacy Visit (manufactures false distinctness — asserts as many physical devices existed as there are historical records, which is almost certainly an overcount); a single shared placeholder Device for all legacy Visits (the mirror-image mistake — a wholesale false merge, the exact thing the matching asymmetry rule exists to prevent); a best-effort matching heuristic during migration (would mean designing the deferred reconciliation capability under migration time pressure, before it's been properly designed).

## Rollout

**Deployment strategy clarified (2026-07-26):** staff remain on the current production build throughout backend, bridge, and capability-client development — the bridge client is not distributed as its own production release. The sequence below is revised in place to reflect this; it originally (as first ratified) used two separate confirmed-cutover gates (confirm bridge adoption, then later confirm capability adoption), reflecting an assumption that the bridge and capability clients would ship as two independent releases reaching the field at different times. Under this clarified strategy there is only one real release, so those two gates collapse into one — see the revised Scoping note at the end of this section.

Uses the existing forced-update mechanism (`appConfig/global`, `minRequiredVersion`), paired with a manual check of the small, known set of physical staff devices (the mechanism fails open if unreachable, so it's a strong nudge, not a standalone guarantee) — needed exactly once now, at the coordinated release gate (step 4), not at two separate points.

1. **Additive backend only.** New `devices` collection + rules; new `estimates` subcollection + rules; `deviceId` added to the Visit model as nullable, not yet required. Nothing shipped reads or writes any of it. **Complete** — PR #26, deployed to production `technostore-v2` (2026-07-26).
2. **Bridge compatibility client.** Reads/displays both vocabularies. Writes only the old shape. **Complete, merged to `main` — intentionally not distributed as an independent release** (PR #27, 2026-07-26). Still required despite never shipping alone: at the moment step 4 first distributes the coordinated build, the status-vocabulary migration (step 6) has not yet run, so every existing Visit still holds legacy literals. The newly-distributed client's very first job is displaying that entire legacy dataset correctly — exactly what this phase's dual-vocabulary read/grouping logic (`lib/core/utils/device_status.dart`) already does. Without it, the coordinated release would break on 100% of existing production data on day one, before migration ever runs.
3. **Capability-client implementation.** New required Device selection at intake, Estimate creation, Awaiting Approval — all live, including on legacy Visits still open (§6). Rules remain unchanged from steps 1–2. Developed and merged to `main` while production stays on the current build — nothing here is blocked by an adoption gate, since nothing is deployed until step 4. **Also requires:** gating step 2's compatibility-tab action set (Edit/Fixed/Archive for the In Maintenance group, Edit/Deliver/Archive for the Fixed group) by real status semantics rather than carrying its display-only grouping forward as a workflow rule — a Visit sitting at `Awaiting Approval` must not remain reachable through the legacy "Fixed" action once this step is live.
4. **Coordinated release / adoption gate.** First real distribution of the combined bridge+capability build to staff. Bump `minRequiredVersion`; pair with the manual check of the known staff-device fleet, per the note above on why both exist together. The only rollout-confirmation step in this sequence — it stands in for what were separately steps 3 and 5 in the original two-gate design.
5. **Tighten rules.** Only after step 4 confirms every staff device is on the coordinated build. `deviceId` required on Visit `create`; `status` rejected once `Delivered` or unless a valid new literal; `finalAmountCharged` writable only when resulting `status` is `Ready for Handback`. Tightening any earlier would break the currently-shipped production client's writes outright — it has no awareness of either vocabulary change until step 4.
6. **Status-vocabulary migration.** Only after step 5. `migrate-status-vocabulary.js --execute` → verify. Explicit approval gates `--execute`. Running this before step 4's distribution would rewrite literals the currently-shipped client has never been coded to read, defeating the exact purpose step 2 exists to serve.
7. **Optional, no deadline.** Remove dual-vocabulary read compatibility whenever convenient.

**Scoping note (revised 2026-07-26):** the original design used two separate confirmed-cutover gates — confirm bridge adoption, then confirm capability adoption — reflecting an assumption, since revised, that the bridge and capability clients would ship as independent releases. Under the clarified single-coordinated-release strategy only one such gate exists (step 4). This single-confirmed-cutover-gate shape is specific to this migration's now-settled deployment strategy, not adopted as a general rollout requirement for future features.

## Consequences / deliberately deferred

Device-level `recordState`/archive; Device merge/reconciliation, including any future historical-Visit-to-Device linking (no write path today, to be designed with its own authority when a real need emerges); Waiting for Parts as a status; Estimate decision-channel provenance; Estimate revision-relationship classification; IMEI-edit audit or elevated authority; rules-level enforcement of the interior status-transition graph and the `finalAmountCharged` ceiling-vs-Estimate check, both app-trusted for v1; a generalized "blocked pending staff resolution" abstraction beyond the one concrete per-Estimate resolution case (§7 correction) — deferred until a second real scenario demonstrates it's actually shared; a generic termination-reason taxonomy beyond what Technical Finding plus the Estimate sequence already answer (§4 correction). The transaction/consistency concern raised in an earlier draft (a decline write leaving the Visit without a resulting resolution fact) is resolved by construction now that resolution is embedded on the same Estimate document, not deferred.

---

## Addendum (2026-07-25): Device Matching / Deduplication Policy

Ratified as a product/behavioral policy, closing the one item `ROADMAP.md`/`OPEN_DECISIONS.md` still tracked as open after this ADR's initial ratification: the exact rules for confidently matching two records to the same physical device. Product-level only — no Firestore queries, indexes, schema, or UI decided here.

**Two candidate-producing pathways, and only two:**
- An **exact IMEI/serial match** — population-wide, cross-customer.
- The resolved customer's **own previously-known Devices** — customer-scoped, derived from their prior Visits' `deviceId` references, not a field on Device itself (Device carries no customer/ownership reference by design — §4).

Brand/model/color never independently produces a candidate; it only ranks or disambiguates within a set one of the two pathways above already produced.

**Reason-tags, not a synthesized confidence score.** Each candidate carries one or both of: *Known device for this customer*, *Matches by IMEI/serial*. No blended numeric confidence is computed.

**Ordering — three explainable buckets:** both reasons present → IMEI match alone → known-to-this-customer alone. Brand/model/color may only be used to order within the last bucket.

**No candidate:** whenever neither pathway produces anything, intake proceeds directly to creating a new Device — an expected, unremarkable default, not a dead end or error state.

**Cross-customer presentation — deliberately minimal.** A cross-customer candidate shows only Device-level facts (brand, model, color, IMEI-as-known) and the explicit reason it was surfaced. It does **not** show the previous customer's name, prior Visit content, or a Visit count. Staff's broad Visit-read authorization does not make that information part of this decision surface — the matching decision is narrowly whether the physical device matches the candidate, and showing more risks conceptually mixing Device identity with Customer relationship, which this ADR's relationship model (§4) deliberately keeps separate. At most, a cross-customer candidate may neutrally indicate the Device was previously seen by the shop, without attaching it to who.

**What staff is actually confirming:** exactly one thing — that the physical device in front of them is the same physical device the candidate Device record represents. Not the customer relationship (already established earlier in the same intake flow), not any inherited history, condition, or pricing.

**Asymmetry rule preserved by construction:** no pathway, including an exact IMEI match, ever auto-selects a candidate; "none of these — create new" is always a first-class sibling option; duplicate or conflicting IMEI data (two Device records sharing a stored IMEI value) surfaces as separate candidates rather than being silently resolved to one.

**Schema/authorization consequence: none.** This policy requires no new fields on `devices` or `maintenanceDevices` beyond what §1/§4 already define, and no change to the authorization matrix — reason-tags and candidate presentation are derived at query/read time, not stored.

**Recorded as implementation dependencies, not designed here (2026-07-25):**
- **IMEI/serial normalization.** "Exact match" means exact after whatever canonical normalization/validation policy is eventually defined (case, separators, checksum, etc.), not necessarily raw-string equality as typed by staff. That normalization policy is undesigned.
- **The customer-known-Devices lookup** (the second pathway) implies querying Visits by `userId` where `deviceId` is present and collecting the distinct set, since Device carries no customer-side field to query directly. This is a real query/index dependency for whichever implementation phase designs it — flagged so it isn't invented ad hoc later, not resolved here.

Both resolved below (2026-07-26), as focused engineering-design threads ahead of capability-client implementation — not new product discovery, since the product-level policy above is unchanged.

### Addendum, continued (2026-07-26): IMEI/serial normalization and validation policy

**Two distinct concerns, deliberately kept separate.** *Normalization* transforms a value for comparison purposes only — it never changes what's stored or shown. *Validation* decides whether staff's typed input is accepted for storage at all. Conflating them (e.g. rejecting input that doesn't fit a strict IMEI format) would silently narrow §1's `imeiNumber` field to phones-only, when this shop's own problem/accessory lists (`AppConstants`) show it services devices beyond phones — a rejected tablet or other device's genuine serial number would be a real business harm, not a data-quality improvement.

**Normalization (for matching):** trim surrounding whitespace, strip internal separator characters staff commonly type or scan (spaces, hyphens, colons — real-world IMEI display formats include grouped forms like `35-209900-176148-1`), and uppercase the result (a no-op for the common all-digit IMEI case, but necessary for alphanumeric serials, e.g. Apple's format). No checksum validation (IMEI's Luhn check digit), no fixed-length enforcement — both would incorrectly reject legitimate non-phone serial numbers, and the field is explicitly evidence, not identity, so imposing phone-specific rigor overclaims what this field is for. A value that normalizes to the empty string (originally empty, or originally only whitespace/separators) is treated as **absent evidence, never a matchable value** — two devices both lacking a recorded IMEI must never be presented as matching each other on that basis; the exact-match pathway simply produces no candidate from a document whose normalized value is empty, and no query is issued for an empty normalized value at all.

**Validation (for data entry):** deliberately light — non-empty after trim if provided at all (the field stays optional, per §1), and a generous max-length guard (e.g. 40 characters) purely against paste/barcode-scanner garbage, not format enforcement. No blocking error message tied to "looks like a valid IMEI," mirroring the field's own "matching evidence, not identity" framing — contrast deliberately with `phoneNumber`'s existing `_normalizePhoneNumber`, which *does* enforce a strict shape, because phone number is a true identity signal (verified against Firebase Auth) and IMEI/serial is explicitly demoted below that bar.

**Schema consequence — new derived field.** Firestore cannot apply an arbitrary normalization function during a query; an exact-match query needs the *stored* value already in canonical form. `devices/{deviceId}` gains one new field:

```
devices/{deviceId}
  ...existing fields (§1)...
  imeiNumberNormalized: string?   // NEW — derived from imeiNumber, recomputed on every write, never independently editable
```

Computed client-side by a shared pure function (mirroring the `DeviceStatus` utility's placement — e.g. `lib/core/utils/imei_normalization.dart`), applied identically wherever `imeiNumber` is written or compared, so the same input always normalizes the same way. The exact-match query becomes `where('imeiNumberNormalized', '==', normalize(typedValue))` — a single-field equality query, which needs no new composite index (Firestore's automatic single-field indexing already covers it).

**Rules consequence, kept consistent with existing precedent.** `firestore.rules`' `devices` `create`/`update` key-set (`hasOnly`/`hasAll`) needs `imeiNumberNormalized` added as an optional string-when-present field, identical in shape to the existing `imeiNumber` check. Rules do **not** re-derive or verify that `imeiNumberNormalized` is genuinely the correct normalization of `imeiNumber` — that would require reimplementing the normalization function in the rules language itself. This is a deliberate app-trusted boundary, consistent with this ADR's existing precedent for cross-field consistency (the interior status-transition graph and the `finalAmountCharged` ceiling check are both already app-trusted for v1, per Consequences) — not an oversight.

### Addendum, continued (2026-07-26): customer-known-Devices query design

**Shape:** resolved customer (`userId`, already established earlier in the intake flow via the existing `getUserIdByPhoneNumber` pattern) → that customer's Visits → distinct non-null `deviceId` values → the corresponding `devices/{deviceId}` documents. Two reads, not one.

**Read 1 — the customer's Visits.** `maintenanceDevices` `where('userId', '==', uid)`, no `recordState` filter, no `orderBy`. Deliberately includes archived Visits: a customer's device history is a historical fact independent of whether a particular repair record is currently active in staff's day-to-day workflow (ADR-005's archive is about hiding from active workflows, not erasing history) — and omitting the `recordState` filter also keeps this a single-field equality query needing no composite index, sidestepping `BACKLOG.md` #17's gap entirely (that gap is specifically about the `status`-filtered tab view, which this lookup has no reason to resemble). A generous defensive `.limit(...)` (e.g. 200) guards against a pathological case — a real customer accumulating meaningfully more distinct devices than that over a relationship with a local repair shop is implausible — mirroring `streamDevicesForTab`'s own existing `limit(50)` pattern rather than leaving the read truly unbounded.

**Dedup, client-side.** Collect `.deviceId` from the fetched Visits into a `Set<String>`, dropping null/absent values — Firestore has no server-side `DISTINCT`, and a bounded per-customer result set makes client-side deduplication the simplest correct option, not a performance compromise.

**Read 2 — the candidate Device documents.** Batch-fetch by ID using `where(documentId(), 'in', chunk)` in chunks of ≤30 (Firestore's `whereIn` limit), rather than one `get()` per distinct `deviceId` — avoids the N+1 shape explicitly ruled out, at effectively no added complexity since it reuses the exact `whereIn` pattern this codebase already established in Phase 2's `_deviceTabQuery`. In the overwhelming common case (a customer with a small handful of distinct historical devices) this is a single batched call; only a customer with more than 30 distinct devices — not realistic for this shop — would need a second chunk. No new composite index: `documentId()`-based `in` queries don't require one.

**Denormalization — considered and rejected.** An alternative design would maintain a `knownDeviceIds` array directly on `users/{uid}`, updated whenever a Visit is created with a `deviceId`, trading this two-read query for a single direct lookup. Rejected: it introduces a second write path that must stay synchronized with the Visits collection — exactly the kind of drift risk this ADR's `price`-field post-mortem (§5) already illustrates concretely, for a lookup that only runs once per intake (staff-side candidate generation), not a hot or frequent path where the read-latency saving would matter. The two-read design stays the source of truth in one place (the Visits themselves) at a cost this feature's actual access pattern doesn't need paid down.

**Schema/authorization consequence: none.** Both reads use `maintenanceDevices`/`devices` read authority already ratified and deployed in Phase 1 — no new fields, no rules change.
