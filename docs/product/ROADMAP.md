# ROADMAP.md

This document sequences the open product decisions recorded in `OPEN_DECISIONS.md` by factual dependency — not by importance, not by ease of implementation, not by a timeline with dates implying a precision nobody has. Where one thing genuinely cannot be sensibly resolved before another, that dependency is stated. Where two items simply have no dependency relationship, they sit in the same group with no order implied between them — appearing first within a group carries no meaning beyond narrative convenience.

This document makes no new decisions. Every item here is already defined in full in `OPEN_DECISIONS.md`; this is where they're organized for sequencing, not where they're decided.

`OPEN_DECISIONS.md`'s Design & Experience and Revisitable Concepts sections are deliberately not included here — the first is execution work, not sequencing logic; the second is explicitly not planned unless something changes, which is the opposite of what a roadmap represents.

---

## Foundational — resolved (2026-07-25)

Both items formerly in this group — device identity/matching together with the intake-time lookup workflow, and the status vocabulary together with the estimate/approval record shape — are now settled at the architecture level by `ADR-007` (Device / Visit / Estimate Domain Model), which designed them together specifically because of the cross-dependency this section flagged. Not yet implemented, but no longer blocking anything else in this document. The two narrower threads this left open — the device-matching algorithm and the status vocabulary's narrative copy — briefly moved to Self-Contained below and have since been settled in full (2026-07-25 and 2026-07-26 respectively); neither remains in this document as an open item.

## Self-Contained

Each of these is resolvable independently of the others, in any order, whenever there's a real reason to take one up.

- **PIN/pattern purge timing** — immediate on delivery, or a short, strictly bounded grace period, and what mechanism guarantees completion.
- **Deletion recovery mechanism** — how long a hidden record stays recoverable, and how it's restored.
- **Phone-number-change mechanism** — how a customer's identity survives a verified number changing entirely.
- **Shared-device staff identity switching or locking** — its secure mechanism deserves its own dedicated security and architecture thread whenever there's a real reason to take it up.
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
