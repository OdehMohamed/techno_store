# ROADMAP.md

This document sequences the open product decisions recorded in `OPEN_DECISIONS.md` by factual dependency — not by importance, not by ease of implementation, not by a timeline with dates implying a precision nobody has. Where one thing genuinely cannot be sensibly resolved before another, that dependency is stated. Where two items simply have no dependency relationship, they sit in the same group with no order implied between them — appearing first within a group carries no meaning beyond narrative convenience.

This document makes no new decisions. Every item here is already defined in full in `OPEN_DECISIONS.md`; this is where they're organized for sequencing, not where they're decided.

`OPEN_DECISIONS.md`'s Design & Experience and Revisitable Concepts sections are deliberately not included here — the first is execution work, not sequencing logic; the second is explicitly not planned unless something changes, which is the opposite of what a roadmap represents.

---

## Foundational

Nothing else in this document depends on anything outside this group, and several later items depend on these being resolved first.

- **Device matching and deduplication, together with the intake-time lookup workflow.** How staff actually find or confirm a device or customer at intake shapes almost everything built on top of the identity model.
- **The complete status vocabulary, together with the estimate/approval record shape.** The full set of states and the structure of the pricing sequence are tightly coupled — designing one without the other risks a mismatch between what the workflow tracks and what it can actually show.

## Self-Contained

Each of these is resolvable independently of the others and of the foundational group, in any order, whenever there's a real reason to take one up.

- **PIN/pattern purge timing** — immediate on delivery, or a short, strictly bounded grace period, and what mechanism guarantees completion.
- **Deletion recovery mechanism** — how long a hidden record stays recoverable, and how it's restored.
- **Phone-number-change mechanism** — how a customer's identity survives a verified number changing entirely.
- **Starting Something New** — the mechanism for a customer-initiated request, remote from a walk-in visit.
- **Customer notification and communication channel(s)** — reliability is the governing requirement; the specific mechanism is undecided.
- **Whether promotional communication belongs in the Communication Timeline at all** — not decided against, simply not yet earned; independent of the channel question above.
- **Staff-alert scenarios and delivery** — the specific conditions and thresholds that should surface inside the Aggregate Operational View, and how.
- **Relationship Health metric definitions** — the precise semantics and time boundaries behind "active," "new," "returning," and "dormant."
- **Product representation's shape.** Explicitly not blocked by inventory ownership below — whether and how product information is represented for browsing or discovery can be designed independent of where the underlying inventory data ends up living.

## Gated by Something Outside This Process

Not blocked by indecision — blocked by a real dependency that hasn't been resolved yet, in one case entirely outside this business's control.

- **Inventory ownership** is the actual gate here. Whether Techno Store ever owns inventory itself or integrates with the external accounting system already in use depends on a conversation with that system's vendor that hasn't happened.
- **The remaining retail-cluster items** — fulfillment shape (pickup, delivery, or both), and payment timing within the order journey — are downstream of that same gate: neither can be sensibly designed before it's known where product and order truth actually live. Favorites' fate is downstream of these, not of inventory ownership directly, since it depends on the shape of the surrounding retail journey.
- **The business-authority mechanism**, spanning permanent deletion authorization and future refunds, needs its own dedicated design thread once there's enough shape to approach it properly — not something to resolve as a side effect of any single item above.

## Speculative

Not scheduled, not foreclosed — revisited only if a real need actually surfaces.

- **Whether business insight ever extends beyond Admin.** A concrete instance already named — repair-type trends might genuinely help Maintenance plan for parts — but no real business problem has earned that conclusion yet.
