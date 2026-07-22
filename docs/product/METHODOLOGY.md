# METHODOLOGY.md

This document is not a summary of how discovery happened. It's a decision-making reference — the set of principles, patterns, and tests that discovery produced, meant to be checked against every future product, UX, and documentation decision for this project.

Each entry answers four questions:

- **What is it?** — a precise statement.
- **Why is it true?** — the grounding, not the full story.
- **How should it be used?** — when it should actually influence a decision.
- **What earned it?** — the clearest concrete example that proved it, not a hypothetical.

If a future decision can't be checked against anything here, that's not necessarily wrong — but it's worth asking whether it's actually been earned (see Operational Test #3) before it's carried forward as settled.

These four documents describe one product from different altitudes, not four independent ones. A change to any single document can create a contradiction with another that its own review would never catch — this happened for real during the first holistic Product Review, between a claim in `ROADMAP.md` and an explicit statement in `OPEN_DECISIONS.md` that neither document's own internal logic flagged. Whenever a foundational document changes, check it against the other three before treating the change as complete, not just against itself.

---

## Product Principles

Values that judge whether a decision is *good*.

### 1. Relationship, Not Transaction

**What it is:** Techno Store's product exists to serve one continuous relationship between a customer and the business — spanning their devices, repairs, and purchases — not a series of disconnected transactions.

**Why it's true:** Discovered while examining the maintenance workflow: the app modeled a single repair ticket moving through three states, with nothing connecting one repair to the next, or a repair to a later purchase. That gap directly contradicted the trust, transparency, and long-term relationship the product exists to build.

**How it's used:** Apply whenever a decision would treat two related events — two repairs on the same device, a repair and a later purchase — as unconnected. If a decision would sever a continuity a real customer would expect, it's wrong regardless of how convenient it is to implement.

**What earned it:** Modeling devices as a first-class entity distinct from repair episodes, so a phone repaired three times over two years reads as one continuous history, not three unrelated tickets.

### 2. Goal-Oriented, Not Feature-Oriented

**What it is:** Every interaction is judged by whether it helps someone achieve the real goal they came with, not by whether it resembles a typical app feature.

**Why it's true:** Discovery repeatedly produced better answers by asking "does the customer's actual goal require this" than by asking "should we build this feature."

**How it's used:** Before designing anything, name the real goal — the customer's, the staff member's, the owner's — it's meant to serve. If the goal can't be named precisely, the thing being proposed hasn't earned its existence yet.

**What earned it:** Reframing retail from "should we build a store screen" to "does this help someone achieve what they came here for," which revealed several retail journeys were one goal-fulfillment capability, not separate features.

### 3. Built for This Business, Not a Platform

**What it is:** Techno Store is designed for this specific business and its real relationship with its real customers — not generalized for hypothetical scale, resale, or platform ambitions.

**Why it's true:** Confirmed directly at the start of discovery: a multi-tenant SaaS model was explicitly rejected in favor of "one business, one customized product." Every later phase reinforced this by refusing to build generic capability the business hadn't actually asked for.

**How it's used:** When a decision is justified by "that's what apps like this usually have" rather than something true about this business, stop and ask whether it's actually earned. Operational Tests #1 and #2 are how this principle gets applied concretely.

**What earned it:** Retiring the `isActivated` field once its real origin — a multi-tenant subscription-licensing gate — was revealed to belong to a business model already explicitly rejected.

### 4. Action and Authority Are Separable

**What it is:** The system should always be able to distinguish who performed an action from whose expertise, decision, or authority that action actually represents.

**Why it's true:** Surfaced while examining how Reception could correct a status a technician forgot to update, without that correction being mistaken for Reception performing technical work themselves.

**How it's used:** Whenever a record is created or updated, ask whether "who touched this" and "whose judgment this reflects" could ever be different people. If they could, capture both, not just one.

**What earned it:** Marking a device "Fixed" always records whose technical judgment it reflects, regardless of who performed the data entry — protecting accountability without restricting who can keep the shared workflow accurate.

---

## Structural Patterns

Judge whether an entity is *modeled correctly*.

### 1. Identity Persists, Attributes Change

**What it is:** An entity's identity should never be defined by a single mutable attribute or event attached to it.

**Why it's true:** Proven independently four times: a device's identity outlives any single repair episode; a customer's identity outlives any single phone number; a staff member's identity outlives any single role; an experience's identity outlives any single platform it's rendered on. Four independent confirmations made this a pattern, not a coincidence.

**How it's used:** When modeling a new entity, ask what's actually persistent about it and what's merely attached — a contact detail, a status, a rendering context. Never let the attachable thing become the thing itself.

**What earned it:** A customer's phone number can change entirely — a lost SIM, a new number years later — without creating a new customer or severing their history.

### 2. Sequences Carry Meaning

**What it is:** When something changes over time in a way that matters, preserve the sequence of what happened rather than overwriting it with only the latest value.

**Why it's true:** Discovered while designing pricing: a single overwritten price field would have destroyed the record of an original estimate versus a revised one, undermining the traceability the relationship depends on.

**How it's used:** Before letting a new value simply overwrite an old one, ask whether the history of how it got there is something a customer, staff member, or the business would ever need to see or trust. If yes, model it as a sequence, not a snapshot.

**What earned it:** Pricing became a sequence of estimate and approval records rather than one field — and the same reasoning later kept the Communication Timeline a persistent record instead of collapsing into "current status."

---

## Operational Tests

Questions to ask before anything is finalized.

### 1. Does the Application Need to Participate Here, or Does This Belong to Reality?

**What it is:** Before deciding how to model something inside the app, ask whether the app needs to be involved in it at all.

**Why it's true:** Realized while examining a staff member helping a colleague during a busy moment — a real, healthy business behavior that turned out to need zero in-app representation, because it was simply people helping each other, not a system interaction.

**How it's used:** The first question for any new scenario, before any design work begins. If the honest answer is "this is just people doing their jobs, or reality happening," stop there.

**What earned it:** A staff member verbally recommending a product to a customer needs no in-app modeling at all, even though the resulting sale, if it happens through the app, does.

### 2. Can an Existing Place Already Satisfy This Goal?

**What it is:** Once something is confirmed to need the app's participation, check whether an already-earned place can serve it before creating a new one.

**Why it's true:** Named while deciding whether "Customers" deserved to be its own browsable destination — it didn't, because the goal it seemed to justify was already fully served by search leading into an existing record.

**How it's used:** Before proposing a new screen, section, or concept, name the specific goal it serves, then check whether an existing place already reaches that goal by a different entry point.

**What earned it:** A standalone "Customers" browsing destination never earned its existence — the goal was already satisfied by phone-number lookup leading directly into a customer's relationship record.

### 3. Has This Specific Conclusion Actually Been Earned?

**What it is:** A conclusion only counts as decided if it's traceable to something true about this business — not merely reasonable, not merely different from a common default.

**Why it's true:** Surfaced when a proposed accent color turned out to be justified only by "avoiding what's generic" — a reason about other apps, not about Techno Store. The same test later retracted an early instinct that tablets should be primary for staff.

**How it's used:** Before carrying any conclusion forward, ask whether it traces back to something specifically true here, not just plausible in general. If the honest answer is "it's a reasonable guess," leave it open rather than pretend it's settled.

**What earned it:** The literal color palette was deliberately left open rather than settled through description, on the grounds that color is better tested against real interface and real type than argued into existence.

---

## Design Principles

Govern the experience layer specifically — how the product actually feels to use.

### 1. Tell the Story, Not the Status

**What it is:** Customer-facing moments read as a narrative — what's happening, what's expected, what's next — in institutional voice, never as a flat status label or an individual staff member's name.

**Why it's true:** Built to answer "never forgotten, never in the dark" concretely; refined once it became clear that naming an individual staff member would tie the customer's trust to a person rather than the persistent business — Structural Pattern #1 applied to institutional identity.

**How it's used:** When writing customer-facing copy about the relationship, check that it answers all three narrative questions and speaks as "we," never as a named individual.

**What earned it:** "We've diagnosed the issue and prepared an estimate — please approve before we begin," not "Status: Awaiting Approval."

### 2. For Staff, Invisible Is the Highest Compliment

**What it is:** Speed and predictability beat delight whenever they trade off, for anyone using the product many times a day to get real work done.

**Why it's true:** Grounded directly in the reality of Reception registering forty devices in a single day — visual polish costs something real when multiplied by that frequency.

**How it's used:** Whenever a staff-facing decision trades a moment of delight against a moment of friction or relearning, choose the option that disappears into muscle memory.

**What earned it:** Motion and animation in staff-facing flows are functional only — confirming an action succeeded — never decorative.

### 3. Quiet When Life Is Quiet

**What it is:** The application never manufactures content or presence simply because nothing is currently happening — it states the calm truth plainly and lets history remain quietly present.

**Why it's true:** Resolved a real tension between "never forgotten" and the discipline against manufactured engagement — the majority of a real relationship's lived time is quiet, and the product should be honest about that.

**How it's used:** When designing any "nothing is happening" state, resist filling it with suggestions or manufactured content. State the truth, keep history accessible, stop there.

**What earned it:** A Relationship Timeline with nothing active simply says so — "Nothing in progress right now" — with history quietly available beneath it.

### 4. Presence Is Earned, Not Performed

**What it is:** The application only participates — speaks, notifies, suggests, or shows content — when it has something true and useful to contribute. Never to perform activity for its own sake.

**Why it's true:** Recognized as the single value underlying several separate decisions made independently: the notification boundary, the Communication Timeline's discipline, staff's restraint, and the quiet state's honesty — later confirmed to also govern the insight-only boundary in Business Operations.

**How it's used:** The final check on anything the application is about to say or show: is this true and useful right now, or does it merely fill a space where content was expected? If the latter, don't.

**What earned it:** Business Operations stops at insight and never recommends an action — Questions → Insights → Stop — because recommending would be performing helpfulness the data doesn't actually justify.

### 5. Default Modes Break at Genuine Exceptions

**What it is:** The calm default for customers and the fast default for staff should visibly interrupt themselves at exactly three kinds of moments — a decision someone must make, an action requiring real business authority, or a moment where an honest mistake would carry real cost — and nowhere else. "A decision" surfaces primarily on the customer side (an estimate awaiting approval); authority and mistake-risk surface on both.

**Why it's true:** Named after noticing that customer approval moments and staff authority-gated actions were the same underlying design move, worn by two different defaults.

**How it's used:** Reserve visual and interactive interruption exclusively for these three triggers. If something outside them starts looking like an exception, the default is being violated without a real reason. This is distinct from Product Principle 4's own mechanism — a required, non-skippable field recording whose judgment an action reflects (for instance, marking a device "Fixed"). That doesn't visually interrupt the flow the way these three do; it just can't be skipped. Don't fold it into this principle's three triggers — it earned its place under Product Principle 4, not here.

**What earned it:** An estimate awaiting approval visually interrupts the customer's calm narrative; a business-authority action interrupts staff's fast workflow — both deliberately, both rare.

### 6. Deliberate Friction Protects Against Real Mistakes

**What it is:** A small, intentional moment of friction is worth its cost whenever it protects against a real-world error, independent of whether authority or a decision is involved.

**Why it's true:** Distinguished from the authority-interruption principle when discussing delivery confirmation — handing the wrong device to the wrong person is a real risk with no decision or authority question attached at all.

**How it's used:** Wherever an ordinary, routine action carries a real chance of an honest, costly mistake, add a deliberate confirmation step, even in an otherwise fast-by-default flow.

**What earned it:** Delivery confirmation shows identifying details before completing — a half-second of friction as cheap insurance against a real error in a busy shop.
