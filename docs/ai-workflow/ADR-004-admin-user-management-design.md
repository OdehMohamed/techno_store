# ADR-004: Admin User Management Feature — Design Proposal

**Status:** Split. The **Staff Status architecture** (activate/deactivate) below is **settled — approved by the product owner 2026-07-23, ready for implementation planning whenever it's picked up.** The **role-change proposal** (`setUserRole`) remains **Proposed — future work, not decided to build**; this pass deliberately left it untouched, per its own original recommendation to treat role-change as a separate, more carefully reviewed feature.
**Date:** 2026-07-03 (original proposal); settled 2026-07-23 (Staff Status Architecture Pass).
**Related:** `ADR-002-role-management.md` (Phase 2, Custom Claims), `docs/ai-workflow/archive/phase1-execution/PHASE1_IMPLEMENTATION_PLAN.md` §2, `docs/product/PRD.md` (Auth & Account Lifecycle)

**2026-07-22 product-decision update:** `docs/product/PRD.md` (Auth & Account Lifecycle) has since settled the product-level question this ADR anticipated — Admin can create, suspend, and restore staff access, with accounts created directly by Admin (no invitation flow). However, the generic `isActivated` field this ADR designs around has separately been retired for customer accounts (also `PRD.md`); staff access will be modeled as its own distinct lifecycle status, not a revival of that field. The activate/deactivate mechanics below (Cloud Function shape, audit log, route-level authorization) are still a reasonable starting point, but the exact field/data shape should be revisited against the new staff-status concept — not `isActivated` — whenever this is actually built.

## 2026-07-23 — Staff Status Architecture Pass (settled)

This section supersedes the activation-specific parts of the original design proposal below (data model, write mechanism). The original's read/browse/filter design, Custom Claims sequencing, and route-level authorization guidance still stand unchanged. The role-change proposal (`setUserRole`) is untouched and still just a proposal.

**Data model.** `users/{uid}/meta/staffStatus`, holding `{ status: "active" | "inactive", updatedAt, updatedBy }`. A new document, not a revival of `users/{uid}/meta/isActivated` — per `PRD.md`, staff status is a distinct concept. No rules change needed: the existing `meta/{metaDoc}` wildcard match already covers any document under `meta/`, so the current read (owner or staff) and write (`if false`, always denied to clients) rules apply automatically.

**Write authority.** A `setStaffStatus({ uid, status })` HTTPS Callable Cloud Function, per this ADR's original design — with one addition: it must verify not only that the caller's role is Admin, but that **the calling Admin's own `staffStatus` is currently active**. A deactivated Admin account retaining a valid Firebase Auth session must not be able to change anyone else's status. Writes an audit log entry (`auditLogs/{autoId}`: acting admin uid, target uid, old/new status, timestamp), per the original design's recommendation.

**Live-session enforcement (client-side; not part of the original proposal, which was backend/Admin-screen only).** Two separate listeners, started together right after a successful staff sign-in:
- One on `users/{uid}/meta/staffStatus`, reacting to a transition to `inactive`.
- One on `users/{uid}` itself, reacting to a change in `type` against the value captured at sign-in.

Both funnel into the same settled behavior: an immediate forced sign-out, with status-specific and role-specific messaging kept distinct. Deliberately **not named after the old `_listenToActivation`/`AuthNeedActivation` pattern** — that code is dead, and reusing its name would blur the distinction `PRD.md` already draws between the retired `isActivated` concept and this new one. Proposed naming: `_listenToStaffStatus()` / `_listenToStaffRole()` on `AuthCubit`, emitting distinct new states (e.g. `AuthStaffDeactivated`, `AuthStaffRoleChanged`) rather than reusing `AuthNeedActivation` — exact naming to be finalized at implementation, but conceptually new, not inherited.

**Role-change scope.** This pass only covers the app correctly *reacting* to a role change, regardless of how it was performed (Console-only today, same as status was before this pass). Building an in-app role-change mechanism (`setUserRole`) remains explicitly out of scope, per the original proposal's own recommendation.

**Failure handling if status can't be verified.** Split by context, not a single fail-open/fail-closed rule for everything:
- At sign-in and on app restart (`checkAuth()`): fail **closed** — a read failure blocks access with a retry-able error, never a silent assumption of "active."
- For an already-active session's live listener: a connection hiccup does **not** force a sign-out — only an actual received value (inactive, or a changed role) triggers it. A transient disconnect exposes no new risk beyond what was already true when the session started.

**Migration from the legacy `isActivated` data.** Explicitly out of scope for this architecture — handled manually by the product owner at implementation time, not automated or designed here.

## Is any part of this required for Phase 1 security?

**No.** The product owner confirmed the current activation workflow is a manual Firebase Console edit by a privileged operator. Console edits with sufficient IAM permissions bypass Firestore security rules entirely — they don't go through the client SDK/rules evaluation path at all. This means Phase 1's `allow write: if false` rule on `users/{uid}/meta/isActivated` has **no effect on the current manual process** — it continues to work exactly as it does today. Nothing about this ADR needs to be pulled into Phase 1 to keep the product owner's existing workflow functioning. This ADR is purely forward-looking.

## Context

Future goal: an Admin-only page to manage users, with users grouped/filtered by role (Admin, Reception, Maintenance, Customer — notably **not** Guest, which lines up with `ADR-003`'s conclusion that Guest has no defined business role and shouldn't be designed around). Admin should be able to activate/deactivate accounts, and potentially manage role changes.

This lands on top of two things Phase 1 already establishes:
1. `type` and `isActivated` are immutable from **any** client write, including an Admin's own, by design (`ADR-002` Phase 1, `docs/ai-workflow/archive/phase1-execution/PHASE1_IMPLEMENTATION_PLAN.md` §2).
2. `users/{uid}` is already readable by any staff role, including via `list` queries filtered by `type` (the `isStaff()` rule doesn't depend on which document is being read, so Firestore can validate a collection-wide filtered query against it without per-document evaluation).

Consequence: this feature splits cleanly into a **read half** (already fully enabled today, needs nothing new) and a **write half** (structurally blocked by Phase 1's own rules, by design — and correctly so, since allowing it would reopen exactly the hole Phase 1 closes).

## Design proposal

### Read/browse/filter — no new infrastructure needed

An Admin-only screen can query `users` directly from the client, filtered by `type` (e.g., `where('type', isEqualTo: 2)` for Reception), using the existing Firestore rules as-is. Recommend:
- Role filter as a segmented control or dropdown (Admin/Reception/Maintenance/Customer), matching the product owner's own grouping — deliberately excluding Guest as a filterable group, consistent with `ADR-003`.
- Paginated queries (Firestore `.limit()` + `startAfterDocument`, the same pattern already written but unused in `MaintenanceListServices.fetchMaintenanceDevicesPaginated` — reusable precedent) rather than loading the entire `users` collection at once, since this will grow over time.
- A per-user detail view showing profile fields, current `isActivated` state, and (if built) role.

### Write actions — must go through a trusted server-side mechanism

Because Phase 1's rules make `type` and `isActivated` client-write-immune unconditionally, **any** write from this feature — including from a legitimately authenticated Admin — must go through a mechanism that operates outside client-side rules evaluation. The only correct option is a **Cloud Function using the Admin SDK** (Admin SDK operations bypass Firestore security rules by design, which is exactly the trusted escape hatch Phase 1's rules assume will exist for legitimate administrative changes).

Recommended shape:
- `setUserActivation({ uid, isActivated })` — an HTTPS Callable Cloud Function. Before doing anything, it must verify the caller is an Admin. In Phase 1's world (no Custom Claims yet), that check is a straightforward Admin-SDK read of `users/{callerUid}.type == 0` performed *inside* the function — this works today, independent of whether `ADR-002` Phase 2 (Custom Claims) has landed yet. If Phase 2 has landed by the time this is built, checking `context.auth.token.role` instead is cheaper and stronger, but is not a hard prerequisite for building this feature.
- `setUserRole({ uid, role })` — same shape, for the "potentially manage role changes" capability. Recommend treating this as a **separate, more carefully reviewed feature** from activation, not bundled in casually: it directly touches the exact field `ADR-002` was built to protect, so it deserves its own explicit confirmation step in the UI (e.g., a "are you sure you want to change this user's role from X to Y" dialog) and should not ship in the same pass as the simpler activate/deactivate action without deliberate consideration.
- Both functions should write an **audit log entry** (e.g. `auditLogs/{autoId}`: acting admin uid, target uid, field changed, old value, new value, timestamp) for every action. There is currently no audit trail at all for these changes (even today's manual Console edits aren't tracked in-app, though they may appear in GCP-level infrastructure audit logs invisible to this codebase) — adding one here is the single highest-value "safest design" addition for a feature that grants this much power, at low implementation cost.

### Sequencing relative to ADR-002 Phase 2

Building this feature does **not** strictly require Custom Claims to exist first — the Cloud Function can check the caller's role via a direct Admin-SDK Firestore read, which works under Phase 1's field-based role model too. Migrating to Custom Claims (`ADR-002` Phase 2) and building this admin panel are therefore independent efforts that can be sequenced in either order; migrating claims first is marginally cleaner (cheaper rule evaluation, stronger tamper-resistance) but not a blocker.

### Route-level authorization

This is a new Admin-only screen — it should **not** repeat the existing pattern found in `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md` §4/§5b, where `AppRouter` performs no role checks at all and screens are "protected" only by not showing a button. Whenever this feature is built, its route should be guarded by an explicit role check before building the screen, not left to UI-only gating — this is a good opportunity to close that longstanding gap rather than extend the old pattern to a new, more sensitive screen.

## Consequences

- No Phase 1 work is required or recommended to be pulled forward for this feature.
- ~~When this is eventually built, it requires standing up Cloud Functions in this project for the first time~~ **Stale as of 2026-07-23:** `functions/` already exists (`linkDevicesToNewCustomer`, shipped alongside the customer sign-up flow), already using the Admin-SDK/`firebase-functions` v2 pattern this feature needs. `setStaffStatus` (see the Staff Status Architecture Pass section above) is an incremental addition to live infrastructure, not first-time setup — this materially lowers the cost of building this feature versus what was assumed here.
- The audit-log recommendation introduces a new Firestore collection (`auditLogs` or similar) — a small, low-risk addition, but worth deciding its own read-access rules at that time (likely Admin-only read, no client write at all — only the Cloud Functions write to it via Admin SDK).

## Open questions for product owner (for whenever this is prioritized, not now)

- Should role-change and activation be built together or as two separate releases, given the recommendation to treat role-change as higher-risk?
- Should the audit log be visible anywhere in the app (e.g., an Admin-facing history view), or purely a backend record for incident investigation?
- Any compliance/retention requirement for the audit log itself?
