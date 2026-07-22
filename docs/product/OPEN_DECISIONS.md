# OPEN_DECISIONS.md

This is the canonical registry of open **product** decisions represented in `PRD.md` — not overlooked, but genuinely not yet earned (Operational Test 3, `METHODOLOGY.md`). `PRD.md` flags each of these inline, at the point they naturally arise; this document exists so they can also be found in one place, without needing to read the whole PRD to know what's still open. Its scope is deliberately matched to `PRD.md`'s own scope — product-level truths, not design or implementation execution.

A second, genuinely different kind of open question exists at a different altitude: design and experience execution — the literal visual palette, dark or light mode, customer-facing motion, and similar. These aren't excluded because they're unimportant. They're kept in their own section, clearly separate, because they answer a different question than "what should the product do," and blending them into the same list would blur a distinction worth protecting.

An item leaves either list when it's been earned, not when someone decides a deadline requires an answer.

---

## Open Product Decisions

### Device & Repair Data

**Device matching and deduplication.** A device is anchored on a system-generated internal ID, with IMEI or serial used only as an optional strong-match hint — never a required anchor, never silently merged on brand or model alone. What's not yet designed: the exact rules for confirming two records represent the same physical device, given IMEI isn't always available or reliably captured.
*Referenced in: Shared Foundation → Core Entities & Identity Model.*

**Intake-time device lookup workflow.** How staff actually find or confirm an existing device or customer relationship at the moment of intake — a search, a suggested match, something else — is not yet designed.
*Referenced in: Shared Foundation → Core Entities & Identity Model.*

**The complete status vocabulary.** Status stays deliberately simple, expanding only for genuine operational or decision points, designed together with notification triggers. The full, final set of states — and the exact narrative copy for each — is not yet settled.
*Referenced in: Shared Foundation → The Relationship Timeline; Relationship Lens → The Relationship, As Experienced.*

**The estimate/approval record shape.** Pricing is a sequence of records, not a single overwritten field — the principle is settled, the exact structure of that sequence is not.
*Referenced in: Shared Foundation → The Relationship Timeline.*

**PIN/pattern purge timing.** Sensitive unlock data is captured only when genuinely needed, and the Delivered event permanently triggers its purge lifecycle — it can never remain part of durable history past that point. Settled. Whether the purge completes immediately or after a short, strictly bounded grace period — and what mechanism guarantees it actually completes — is not.
*Referenced in: Shared Foundation → The Relationship Timeline.*

**Deletion recovery mechanism.** Ordinary removal from normal use is recoverable by default — hidden, not destroyed, protecting the durable history the timeline exists to preserve — settled. How long a hidden record actually stays recoverable and how it's restored is not designed. Distinct from *who* may authorize true permanent deletion, tracked separately under Business Authority below.
*Referenced in: Shared Foundation → The Relationship Timeline.*

### Identity & Account Lifecycle

**Phone-number-change mechanism.** A customer's identity must survive a verified number changing entirely — the requirement is settled; the migration and verification mechanism that actually accomplishes it is not designed.
*Referenced in: Shared Foundation → Auth & Account Lifecycle; Relationship Lens → Account & Identity.*

### Starting Something New

**Customer-initiated requests, remote from a walk-in visit.** Walk-in intake, staff-initiated, is real and working today. A customer starting something themselves — describing a problem, asking about availability — before ever physically visiting is intended to exist alongside walk-in, not replace it, but the mechanism is entirely undesigned.
*Referenced in: Relationship Lens → The Relationship, As Experienced.*

### Retail

**Product representation's shape.** Whether and how product information is represented for browsing or discovery — separable from, and not blocked by, inventory ownership below.
*Referenced in: Shared Foundation → The Relationship Timeline; Relationship Lens → Retail, As a Customer Journey.*

**Fulfillment shape.** Whether fulfillment happens by pickup, delivery, or both, and who would perform delivery if it exists — a distinct question from where payment sits in the same journey, not yet resolved.
*Referenced in: Relationship Lens → Retail, As a Customer Journey.*

**Payment timing within the order journey.** Digital payment is part of the long-term vision, alongside traditional in-person payment — settled. Where it actually sits within the order journey is not.
*Referenced in: Relationship Lens → Retail, As a Customer Journey.*

**Favorites' fate.** Whether it earns a place at all, and if so what it means, deliberately left open until the surrounding retail journey — cart, catalog, or something else entirely — is better understood.
*Referenced in: Shared Foundation → The Relationship Timeline; Relationship Lens → Retail, As a Customer Journey.*

**Inventory ownership.** A complete external accounting and inventory system already exists — products, quantities, barcodes — with no API or integration mechanism today. Whether Techno Store should ever own inventory itself, integrate with that system, or something else, is unresolved and depends on a conversation with the system's vendor that hasn't happened.
*Referenced in: Shared Foundation → The Relationship Timeline.*

### Business Authority

**The concrete authority mechanism.** Business authority is confirmed as a real, distinct dimension from expertise. Staff Account Management is the one place it's already fully settled — Admin-only, including account creation. Permanent deletion and future refunds are recognized as belonging to the same category but remain open until the authority model behind all of it is actually designed.
*Referenced in: Shared Foundation → Roles as Expertise; Operational Lens → Where Speed Intentionally Breaks.*

### Communication

**Customer notification and communication channel(s).** Triggered by "the customer needs to know or act" — settled. Reliability is the governing requirement for whichever channel or channels deliver it; the specific mechanism (SMS, push, something else) is deliberately undecided.
*Referenced in: Relationship Lens → Communication.*

**Whether promotional communication belongs in the Communication Timeline at all.** Non-commercial operational communications — closures, seasonal greetings — are settled as legitimate. Promotional communication of any kind was originally included alongside them without independent scrutiny; on review, "genuinely relevant" doesn't hold up as a hard, checkable boundary the way the rest of this product's tests do. Not decided against — moved here specifically so it earns its place through the same process everything else did, if a real need for it ever surfaces.
*Referenced in: Relationship Lens → Communication.*

**Staff-alert scenarios and delivery.** A distinct, legitimate category from customer communication — settled that it belongs inside the Aggregate Operational View, not a separate destination. The specific conditions and thresholds that should trigger this kind of surfacing, and how it's actually delivered within the view, are not designed.
*Referenced in: Operational Lens → The Aggregate Operational View.*

### Business Insight

**Relationship Health metric definitions.** "Active," "new," "returning," and "dormant" customers are real, settled business questions. Their precise semantics and time boundaries — what period makes someone active, when "new" becomes "returning," how long an absence counts as dormant — are not yet designed. The insight isn't trustworthy until they are.
*Referenced in: Business Lens → Relationship Health.*

**Whether business insight extends beyond Admin.** The Business Lens is owner-facing today, not foreclosed to others. A concrete instance already named: repair-type trends might genuinely help Maintenance plan for parts. No real business problem has earned that conclusion yet.
*Referenced in: Business Lens → The Insight-Only Boundary; Business Lens → Operational Trends.*

---

## Design & Experience — Not Yet Earned

A different kind of open question: execution-level decisions discovery touched during Phase 6 but deliberately didn't settle, because a color or a layout is better tested against real interface than argued into existence (Operational Test 3). Not reconciled against `PRD.md` the way the items above are, since `PRD.md` doesn't cover this altitude at all.

- **The literal visual palette**, including whether the dominant tone leans warm or cool, dark or light — the discipline of restraint is settled; the specific hues are not. (Whether Light and Dark Mode exist as supported product capabilities is no longer open — both are settled. What remains open here is the dark theme's own palette and design language, not whether it exists.)
- **Customer-facing motion and animation.** Staff's motion principle is settled — functional only, never decorative — but the customer-facing equivalent was never worked out.

---

## Revisitable Concepts — Not Currently Earned

Different again from both lists above: not an unresolved question waiting on a decision, and not an execution detail waiting on design work, but a concept that was actively considered and concluded *not* to earn its existence today — with the door deliberately left open, not conceptually foreclosed, should a real need surface later. Being here means "no, not now," not "undecided."

- **Staff Communication Timeline.** Considered directly alongside the customer-facing Communication Timeline. Concluded not to earn its own place — a staff member's "needs attention" moments are operational, and already belong inside the Aggregate Operational View, not a separate communication record. Revisitable only if a real, currently unimagined staff-facing communication need — something genuinely not operational in nature — actually surfaces.

---

## Disagreements on Record

Not open questions — decided, with a dissenting view deliberately preserved rather than quietly dropped.

**Mandatory location fields at signup.** Country, state, and city are required at customer signup. The recommendation was to make them optional, since a required field guarantees completeness but not accuracy — a rushed customer may pick the nearest plausible option rather than answer honestly. The business chose to keep them mandatory, weighing the long-term value of complete data over that accuracy risk, as a deliberate trade-off rather than an oversight. Revisitable if discovery later gives a reason to.
*Referenced in: Shared Foundation → Auth & Account Lifecycle.*
