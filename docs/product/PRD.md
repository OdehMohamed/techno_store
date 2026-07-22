# Techno Store — Product Requirements Document

This document describes what is truthfully true about Techno Store as a product — settled, open, or deliberately deferred — organized around the realities discovery uncovered rather than around roles, features, domains, or platforms. See `METHODOLOGY.md` for the principles, patterns, and tests that produced these conclusions and that should govern how this document keeps evolving. See `OPEN_DECISIONS.md` for the consolidated registry of everything flagged as open below.

Where something is still genuinely unresolved, it's marked **Open** at the point it naturally arises, not hidden until an appendix. An open item is not an unfinished one — see Operational Test #3.

---

## Shared Foundation

The truths every part of this product depends on, described once. What follows is not owned by the customer's experience, staff's experience, or the business's understanding of itself — all three are built on it.

### Vision & Scale

Techno Store exists to serve one continuous, trustworthy, transparent relationship between the business and its customers — not a series of disconnected transactions. Its clearest test: the business is always present whenever something genuinely matters to that relationship, never merely present to have something to say (Design Principle 4, *Presence Is Earned, Not Performed*).

The product is built for this specific business, not as a generalized platform. It serves one business today; multiple branches of that same business are a legitimate future shape and should not be artificially constrained. What it explicitly is not: a multi-tenant product shared across unrelated businesses. If another business ever wanted something similar, the intended shape is "one business, one customized product," not shared infrastructure.

Palestine receives a first-class experience — not a translated afterthought — while the product remains internationally friendly wherever that doesn't compromise the first-class experience Palestinian customers get. Concretely: both `+970` and `+972` are recognized as valid Palestinian numbers, and the product avoids Israel-referencing UI (flags, country labels) wherever a reasonable alternative exists.

### Appearance & Accessibility

Both Light and Dark Mode are settled as supported product capabilities, neither one a token or partially-reachable mode — each must be a complete, real experience. The literal palettes, design tokens, and component treatments for either theme remain design work still to be earned against real interfaces, not decided here (Operational Test 3; see `OPEN_DECISIONS.md`).

Arabic-first support is foundational, consistent with Palestine receiving a first-class experience above. WCAG 2.2 AA is the accessibility baseline the product is held to. Material 3 remains the implementation foundation.

### Core Entities & Identity Model

Four things persist through change, and none of them are defined by any single attribute attached to them (Structural Pattern 1, *Identity Persists, Attributes Change*):

- **Customer.** The lasting identity in every relationship the product manages. A phone number is an authentication and contact attribute — not the identity itself. A customer may hold more than one real-world number but anchors their account on one verified number at a time, and changing that number must never create a new customer or sever their history.
- **Device.** A first-class entity, distinct from any single repair visit attached to it. Always anchored on a system-generated internal identifier; IMEI or serial number is used only as an optional strong-match hint when available, never as a required anchor. Devices are never silently merged on brand or model alone — any linking of two records to the same physical device requires human confirmation.
  **Open:** the exact matching and deduplication rules, and the staff-facing workflow for finding or confirming an existing device at intake.
- **Staff.** An individual, persistent identity, with role treated as a mutable status attached to it — not a fused, permanent account type. A person can move from Reception into Maintenance, or leave the business and later become an ordinary customer, without identity conflict, because staff authentication uses a path entirely separate from customer phone-OTP.
- **The Business.** Techno Store itself is the persistent institution every customer relationship is anchored to — not any individual staff member acting on its behalf at a given moment. This is why the customer-facing experience speaks in institutional voice, never by individual staff name (Design Principle 1).

### Auth & Account Lifecycle

**Customers** authenticate by phone-number verification alone; no email or social sign-in exists or has been identified as needed. Access is full immediately upon successful verification — there is no activation or vetting gate, because no real business need for one has ever been identified. A profile requires a full name and a nickname (a genuine local recognition need — the name staff and the community actually know someone by, not a decorative field) and requires country, state, and city. Profile photo is optional and supplementary.

*A disagreement remains on record here*: mandatory location fields at signup were recommended as optional, on the grounds that a required field guarantees completeness but not accuracy. The business chose to keep them mandatory for the future value of complete data, as a deliberate, weighed trade-off — not an oversight. See `OPEN_DECISIONS.md`.

**Staff** hold individual accounts, never shared between people, authenticating with email and password — a path deliberately separate from the customer phone-OTP flow. This delivers real accountability without entangling a staff member's personal identity with their work identity — someone who leaves the business and later becomes a customer carries no residue of their former role. Accounts are created directly by the Admin; there is no invitation flow an employee completes themselves. Staff-management authority belongs to the business owner (Admin) by default. No manager role has been built, because no real person currently occupies one; inventing it now would violate *Built for This Business, Not a Platform*.

Staff accounts also carry their own lifecycle status — active or inactive — entirely separate from role. This lets Admin suspend and later restore an employee's access without touching who they are or anything they've done: another instance of *Identity Persists, Attributes Change* (`METHODOLOGY.md`), alongside role itself.

**Retired:** the legacy generic `isActivated` field, as it applied to customer accounts. It was originally built to support a multi-tenant subscription-licensing model, explicitly rejected as this product's shape, so it was retired outright rather than repurposed. Staff status is a distinct, newly-designed concept, not a revival of that field.

**Open:** the phone-number-change migration and verification mechanism.

### The Relationship Timeline

The core data model underneath everything: one continuous timeline per customer, spanning their devices, repair episodes, and purchases together — not separate records that happen to share a customer. This is the direct expression of *Relationship, Not Transaction* at the data-model level.

Wherever something changes in a way that matters, the timeline preserves the sequence of what happened rather than collapsing it into a single current value (Structural Pattern 2, *Sequences Carry Meaning*). Pricing is the clearest instance: an estimate, its approval, and any later revision are each their own record, not overwrites of one field. Device status is deliberately kept simple, expanding only for genuine operational or decision points — and status and notification triggers are designed together, since a state worth adding is, by definition, usually a state worth notifying about.

Some devices require a PIN or pattern lock to be captured for the repair to happen at all. This is treated as temporary operational data, never part of the durable history — captured only when genuinely needed. The Delivered event permanently triggers its purge lifecycle: once a device leaves the shop's custody, that data can never remain part of its durable history.

Removing a record from normal use is recoverable by default — hidden, not destroyed — protecting the durable history this timeline exists to preserve. Permanent, irreversible deletion is a distinct, exceptional action, separate from ordinary removal, and who may authorize it is a business-authority question (see Roles as Expertise).

Retail's presence on this timeline is scoped precisely: a relationship record exists for every repair journey, and for retail journeys the application actually initiates — never for a purely physical, cash, walk-in transaction the application was never part of (Operational Test 1).

This timeline is one truth, described once, here. The Relationship Lens and Operational Lens each describe how it's presented differently to a customer and to staff — not two different timelines, one timeline read through two different truthful lenses.

**Open:** the full revised status vocabulary; the exact shape of the estimate/approval record sequence; whether the purge triggered at Delivered completes immediately or after a short, strictly bounded grace period, and what mechanism guarantees it actually completes; the recoverable-deletion mechanism itself — how long a hidden record stays recoverable and how it's restored; product representation's shape within the timeline; Favorites' fate; inventory ownership (a complete external accounting and inventory system already exists, with no integration path today).

### Roles as Expertise

Reception and Maintenance are peer expertises, not a hierarchy — coordination expertise and technical expertise, intentionally and narrowly overlapping, neither a smaller version of the other. The one hard boundary between them is technical judgment: the sole competence that can't be borrowed situationally, regardless of how flexible the business otherwise is about people helping each other. The narrow zone where their capabilities genuinely overlap is receiving and delivering devices — the load-bearing, record-creating moments where the application must participate, and where either expertise can act in service of the customer.

Admin — the business owner — holds full capability across both expertises, plus business authority that neither Reception nor Maintenance holds. Business authority is a distinct dimension from expertise. It is the concept underlying who may authorize a permanent deletion and how refunds will eventually be handled — both still open, with no concrete mechanism designed. Staff account management is the one place this authority is already settled, as Admin-only, including how an account is created — directly by the owner, not through invitation (see Auth & Account Lifecycle).

Wherever an action is recorded, the system distinguishes who performed it from whose expertise or authority it represents (Product Principle 4, *Action and Authority Are Separable*) — this holds regardless of how fluid day-to-day collaboration between staff actually is.

Guest is retired entirely. No principle discovery produced ever justified its existence.

**Open:** business authority's concrete mechanism, spanning deletion authorization, refunds, and staff account management.

---

## Relationship Lens

*How is this relationship experienced?*

Everything in this section is a customer's view of the same Shared Foundation above — the same timeline, the same identity model — read through the lens of someone who wants to know what's happening with their device, their purchases, and their standing with a business they trust.

### The Relationship, As Experienced

The customer-facing timeline reads as a narrative, not a status field (Design Principle 1, *Tell the Story, Not the Status*). Every moment answers three things at once: what's happening, what — if anything — is expected of the customer, and what happens next. It speaks in institutional voice, as "we" or "our team," never by an individual staff member's name, because the relationship being built is with Techno Store itself, not with whichever person happens to be handling a given moment (Structural Pattern 1, applied to the business's own identity).

Illustrative, not exhaustive — the full set of states this applies to is still open, per Shared Foundation:

- *"We've received your device and it's in queue for diagnosis."* Nothing is expected of the customer yet.
- *"We've found the issue: [problem]. Estimated cost: [amount]. Please approve before we begin."* This is the one kind of moment that deliberately breaks the calm default — a real decision the customer has to make, visually distinguished from everything around it (Design Principle 5, *Default Modes Break at Genuine Exceptions*).
- *"Your device is ready. Come by whenever works for you."*

When nothing is currently active, the experience says so plainly — *"Nothing in progress right now"* — with history still quietly present beneath it. Nothing is manufactured to fill the space (Design Principle 3, *Quiet When Life Is Quiet*). "Never forgotten" means the business is always present whenever something genuinely matters — not that it always finds something to say.

How a customer's involvement in something new actually begins is not fully settled either. Walk-in intake, initiated by staff, is real and working today. A customer starting something remotely — describing a problem before a repair exists, asking about something before it's confirmed available — is intended to exist alongside walk-in, not replace it, but the mechanism itself hasn't been designed.

**Open:** the complete, final status vocabulary and the exact narrative copy for each state; the mechanism for a customer-initiated request, remote from a walk-in visit.

### Communication

The Communication Timeline is a distinct record from the Relationship Timeline — what Techno Store has communicated, as opposed to what has happened — and the two cross-reference each other without being the same concept. Most communications map directly to a relationship event (a device is ready, an estimate needs approval, a special order has arrived). Some legitimately don't, and are settled as belonging here too — a holiday closure, a seasonal greeting — bounded firmly by the same test: the customer needs to know or act (Design Principle 4, *Presence Is Earned, Not Performed*). This is deliberately not a marketing surface; a communication that exists only because the business could send one, rather than because the customer needs it, does not belong here.

Whether promotional communication of any kind belongs here at all is deliberately not settled. "Genuinely relevant" doesn't hold up as a hard, checkable boundary the way the rest of this test does — it hasn't earned a place, and it isn't decided against either.

**Open:** which channel or channels deliver these communications, with reliability as the governing requirement; whether promotional communication belongs here at all, and if so, under what boundary.

### Account & Identity

A customer can view and manage their own profile — name, nickname, photo, location — from a dedicated place in the product, separate from the relationship timeline itself, since managing one's own account is a different kind of task from watching a relationship unfold.

**Open:** the concrete flow for changing a verified phone number without losing years of history — the mechanism is not yet designed, only the requirement that identity must survive it (Structural Pattern 1).

### Retail, As a Customer Journey

Retail is not a separate destination from the relationship — it's another way a customer's goal gets met, alongside repair. It shows up as more than one real journey: browsing what's available, discovering something relevant while a device is in for repair, asking for help finding the right thing, or requesting something not currently in stock. None of these is more important than the others; what matters is that the underlying goal — helping the customer get what they came for — is met regardless of which path they took.

A special order arriving is a concrete instance of the same "customer needs to know" boundary that governs every other communication — it earns a place in the Communication Timeline the same way a finished repair does. Consistent with Shared Foundation, a relationship record exists for a retail journey only when the application actually initiated it — never for a transaction that happened entirely in the physical world.

**Open:** the actual shape of product browsing and discovery; whether fulfillment happens by pickup, delivery, or both, and who performs delivery if it exists — a distinct question from where digital payment fits in that same order journey, alongside traditional in-person payment; whether Favorites earns a place at all, and if so, what it means once the surrounding retail journey is better understood.

---

## Operational Lens

*How does someone actually get their work done?*

The same Shared Foundation, read by the people running the business day to day. Where the Relationship Lens asks how a truth is experienced, this lens asks how it's acted on — quickly, predictably, without losing sight of what actually matters.

### Two Views, One Reality

Reception and Maintenance don't share one generic staff interface with different things hidden or shown — each has a genuinely different primary view, matching the peer expertise established in Shared Foundation. Reception's default view is shaped around coordination: who's waiting, what needs intake, what's ready to hand back. Maintenance's default view is shaped around the technical queue: what needs diagnosis, what's mid-repair. Within that queue, diagnosis and creating an estimate is treated as one focused, structured technical action, not an ordinary quick status update — it's the moment that determines the price-approval decision the customer will face downstream, and it deserves deliberate attention even inside a lens that defaults to fast everywhere else. The narrow zone where their capabilities overlap — receiving or delivering a device — is a light, occasional detour into the other's territory, not a parallel interface either of them lives in. Admin sees both in full, plus what belongs only to business authority.

This holds regardless of device or screen. There is one shared experience per role, optimized for whatever context it's actually used in — a counter, a workbench, a phone moving around the shop floor — never a separate experience built for one context and adapted to another. Divergence from that shared experience only happens where it's genuinely earned (Operational Test 3), never by default just because a larger screen happens to be available.

### The Aggregate Operational View

The first thing staff see: what needs attention right now, filtered to whichever lens — coordination or technical — is looking at it. Density here is correct, not a compromise (Design Principle 2, *For Staff, Invisible Is the Highest Compliment*) — staff want to see a lot at a glance, not a spacious layout designed for someone using the product twice a year. A retail order that began inside the application — never an ordinary walk-in cash sale, which the application was never part of — surfaces here exactly like any other operational item needing attention, not as a separate category, because it isn't a separate kind of work.

When nothing needs attention, the view says so plainly. An empty Aggregate View is good news, not a gap to fill with manufactured content (Design Principle 3, applied to staff's register rather than the customer's).

Staff-facing alerts belong here too, not in a separate destination. A device that's been awaiting a customer's decision for too long, or sitting ready for pickup without being collected, is exactly the kind of real operational condition this view exists to surface — a legitimate category on its own, distinct from customer-facing communication, but never a reason for a separate Staff Communication Timeline (see `OPEN_DECISIONS.md`).

**Open:** the specific conditions and thresholds that trigger this kind of surfacing — how long is "too long" — and how it's delivered within the view.

### The Customer Relationship Record

The same Relationship Timeline described in Shared Foundation, presented densely and functionally instead of as narrative — because staff need a different truth from the same reality, not a different reality. Reached by searching or entering a phone number — a high-frequency, phone-number-first action for Reception specifically, fast and unambiguous by design — never by browsing a standalone list of customers (Operational Test 2 — that goal is already met by lookup, and a separate browsing destination never earned its existence). Intake, the moment a new device or a new customer relationship is actually created, captures only what's genuinely required to bring the record into existence; further detail accumulates afterward rather than blocking the customer from being helped. When a retail journey began inside the application — never an ordinary walk-in cash sale — recording its progress happens inside that specific customer's record, the same way receiving or delivering a device does.

### Where Speed Intentionally Breaks

Everywhere else, this lens defaults to fast. It breaks from that default for three distinct reasons, and they shouldn't be read as one thing wearing different names.

**Business authority** interrupts because the action requires authority the acting person needs to legitimately hold. Staff Account Management is currently confirmed as Admin-only, regardless of how fluid day-to-day collaboration otherwise is. Other business-authority actions, including permanent deletion and future refunds, remain open until the authority model behind them is actually designed — not yet settled as Admin-only, just recognized as belonging to this same category.

**Technical-judgment attribution** interrupts for a different reason entirely — not authority, but integrity of the record. Marking a device "Fixed" always requires recording whose technical judgment it actually reflects, regardless of who performs the data entry. Reception can complete this update if a technician forgot to, but the record still names whose expertise it represents. This is Product Principle 4 made into a real, fast, non-skippable field — not a business-authority gate, and not something that blocks the person entering it from being someone other than the technician.

**Real mistake-risk** interrupts independent of both — delivery confirmation is the clearest instance, showing identifying details before completing it. Nothing about handing a device to the right person requires authority or judgment attribution; it just carries a real cost if it goes wrong, and a deliberate half-second of friction is cheap insurance against a busy shop's honest mistakes.

### Staff Account Management

The confirmed real business-authority problem named in Shared Foundation, now settled: an account is created directly by the Admin, with no invitation flow, and carries its own active/inactive status — distinct from role — so Admin can grant, suspend, and later restore an employee's access without touching identity or history.

---

## Business Lens

*Are we growing, are relationships fading, what's changing?*

The same Shared Foundation again, read by the business owner asking a trend question rather than a right-now question or an experience question. This lens is deliberately smaller than the other two — not because it matters less, but because it earned exactly this much, no more.

### The Insight-Only Boundary

This comes first because it defines what the rest of the lens deliberately refuses to become. Every question answered here stops at a truthful insight: Questions → Insights → Stop. Nothing in this lens recommends an action, suggests a next step, or automates anything on the strength of what it shows — Design Principle 4, *Presence Is Earned, Not Performed*, applied to business judgment rather than interface behavior. What the owner does with an insight — call a customer back, change nothing, change something entirely different — is business reality, not product reality. The application has no opinion on it, and isn't meant to develop one.

**Open:** whether insight ever extends to a role beyond Admin. Not decided against — simply not yet earned by a real business question.

### Relationship Health

How many active customers the business currently has; how many are genuinely new versus returning; how many haven't visited in a year or longer; which areas most customers come from; whether long-term relationships are growing or quietly eroding over time. These are about understanding and preserving the relationship the business already has with its customers — not about finding better ways to market to them, which this lens deliberately isn't for.

None of this required new data collection to become possible. It's a new lens over data already made trustworthy by the discipline held everywhere else in this product — the Relationship Timeline's preserved sequences, the persistent identity model — not a new problem this lens had to solve on its own. The geography question in particular is the first place the location fields collected at signup (Shared Foundation) serve a concrete, validated purpose — which confirms the data has real value, without resolving whether collecting it as a required field was the right way to gather it.

**Open:** the precise definition and time boundary behind each of these terms — what period makes a customer "active," at what point "new" becomes "returning," how long an absence has to be before it counts as "dormant." The questions themselves are real; their exact semantics are not yet designed, and the insight isn't trustworthy until they are.

### Operational Trends

How many devices were actually received this month; what proportion of the workflow is currently waiting on a customer's decision, and how that proportion has changed over time; what kinds of repairs are becoming more or less common. This is the same underlying truth the Aggregate Operational View already shows staff — the difference is vantage point, not capability. Staff see the specific, actionable list of what needs attention right now; that list itself belongs to them alone. This lens never exposes it — it turns the same truth into an aggregate count or proportion, and a trend of how that figure moves over time, answering "is this normal" rather than "what do I do about it right now."

This is about understanding how the business itself is functioning, not about monitoring individual people. Nothing here is shaped around who's performing well — only around what's happening in aggregate.

**Open:** whether operational trends should ever extend beyond Admin — a repair-type trend might genuinely help Maintenance plan for parts, for instance — but no real business problem has earned that conclusion yet.
