# ADR-004: Admin User Management Feature — Design Proposal

**Status:** Split three ways. **Staff Status architecture** (activate/deactivate) is **settled and shipped** (2026-07-23 Staff Status Architecture Pass; `setStaffStatus`, PR #14/#22 infrastructure). **Staff Account Creation & Management Surface** (creating accounts in-app, listing/filtering staff, wiring activate/deactivate into a real screen) is **settled as of 2026-07-25 — implementation-ready, not yet built.** **Role-change** (`setUserRole`) remains **Proposed — future work, not decided to build**, deliberately left untouched by both passes above, per this ADR's own original recommendation to treat it as a separate, more carefully reviewed feature.
**Date:** 2026-07-03 (original proposal); settled 2026-07-23 (Staff Status Architecture Pass); settled 2026-07-25 (Staff Account Creation & Management Surface).
**Related:** `ADR-002-role-management.md` (Phase 2, Custom Claims), `docs/ai-workflow/archive/phase1-execution/PHASE1_IMPLEMENTATION_PLAN.md` §2, `docs/product/PRD.md` (Auth & Account Lifecycle), the 2026-07-25 Admin-area code review (findings B1/D1/D3 — `NewUserAdminSide` non-functional, no account-creation mechanism exists anywhere; finding D2, `create_user_account` "orphaned", was itself corrected during PR 2's implementation — see below and `DECISIONS_LOG.md`).

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

## 2026-07-25 — Staff Account Creation & Management Surface (settled)

Prompted by the Admin-area code review (2026-07-25): the only existing account-creation UI, `NewUserAdminSide` ("Add new Employee"), is fully non-functional — its submit path calls a commented-out `AuthCubit.signUp`/`AuthServices.signUpWithEmailAndPassword`, and even if it weren't commented out, the deployed `users/{uid}` `create` rule (`request.resource.data.type == 1`, Customer only) would reject it. No Cloud Function creates staff accounts either. Despite `docs/product/PRD.md` settling "accounts are created directly by the Admin" as a real product decision, no trusted mechanism for it has ever existed — not in code, and not even on paper in this ADR's original proposal, which scoped only activation and role-change. This section closes that gap and, since it's the natural companion surface, also settles the staff-management screen (list/filter/activate/deactivate) that the original proposal's "read/browse/filter — no new infrastructure needed" section already described but was never built.

**Mechanism: a new `createStaffAccount` HTTPS Callable Cloud Function, Admin SDK, mirroring `setStaffStatus`'s trust boundary exactly** (caller must be `type == 0` AND the caller's own `staffStatus` must be `active` — closes the same deactivated-Admin-with-a-lingering-session gap). This is the only viable mechanism, for two independent reasons, not one:
1. The deployed `users/{uid}` `create` rule structurally blocks any client write with `type != 1` — no Admin, however legitimate, can create a staff-typed profile document from the client.
2. Independent of rules entirely: the Firebase Auth client SDK creating a new user (`createUserWithEmailAndPassword`) signs the *calling* session in as the newly created account — an Admin performing this action client-side would be signed out mid-flow and signed in as the new employee. A secondary hidden `FirebaseApp` instance is a known workaround for this specific problem in some Firebase codebases, but was considered and rejected here: it still doesn't solve reason 1, so it only trades one problem for continued reliance on the Cloud Function anyway, for no net benefit.

An invitation/self-registration email flow is not a candidate alternative here — excluded on product grounds (`PRD.md`: "no invitation flow"), not engineering ones.

**Minimum required data at creation:** full name, email, initial password (Admin-set), role (Admin/Reception/Maintenance — all three, see below). No `phoneNumber` (staff accounts have never carried one — see `UserData.fromMap`). **No profile photo** — deliberately dropped from the creation flow: `profiles_photos/{uid}/`'s Storage rules require `request.auth.uid == uid` on write, so neither the Admin's own session nor the not-yet-authenticated new account can upload one during creation, and bundling a binary upload into a callable function's request adds real complexity for a field `PRD.md` already treats as "optional and supplementary." If staff ever want their own photo, it belongs in a future self-service profile-edit feature — none exists today, not designed here.

**Initial password is treated as an initial credential for v1, not a settled long-term password lifecycle.** The Admin types it directly into the creation form and communicates it to the new employee out of band — matches the current product direction and avoids standing up an invitation/reset-email flow this ADR has already excluded above. A forced first-login password change is a real candidate improvement but is explicitly **not decided here** — track it as a future item that must independently earn its place, not something this design assumes or blocks.

**Identity model: a client-supplied `requestId`, not content matching, anchors idempotency.** Email and role describe *what* is being created, never *which attempt* created it — two genuinely unrelated creation attempts can legitimately share both, and matching on content alone risks silently collapsing an unrelated pre-existing account into a false "success." The client generates a UUID (`requestId`) once per creation attempt (held in form/cubit state, resent unchanged on retry; a fresh attempt gets a fresh id) and sends it in the payload alongside `name`/`email`/`password`/`type`.

**New collection: `staffAccountCreationRequests/{requestId}`** — a durable pre-commit intent record, written *before* Auth user creation, so request identity survives even a crash before any Firestore profile exists. Shape: `{ email, type, name, callerUid, status: 'pending' | 'authCreated' | 'completed', uid, createdAt, updatedAt }`. Covered by the existing blanket default-deny (same as `auditLogs`) — no rules change needed. Claimed atomically via `requestRef.create(...)` (throws `ALREADY_EXISTS` if already claimed), not `.set()` — this also serializes two near-simultaneous calls sharing the same `requestId`, rather than letting them race to create two Auth users.

**Data writes, in order, and their atomicity boundary:**
1. Validate caller (Admin + own `staffStatus == active`) and inputs (`requestId`, email format, password strength, `type ∈ {0, 2, 3}`) — no writes yet.
2. Atomically claim (or read the existing) `staffAccountCreationRequests/{requestId}` doc. If it already exists, defensively verify its `email`/`type` match this call's payload — a `requestId` reused with different content is rejected (`failed-precondition`), never silently acted on.
3. Branch on the tracking doc's state (see the five-case table below).
4. `admin.auth().createUser({ email, password, displayName: name })` where applicable — the one step with no cross-system transaction available; Firestore cannot be made atomic with Firebase Auth. Immediately followed by updating the tracking doc to `{ status: 'authCreated', uid }`, so the uid this request owns is durable before anything else happens.
5. `users/{uid}`, `users/{uid}/meta/staffStatus`, and the tracking doc's `status: 'completed'` update, all in a **single Firestore batch** — atomic with respect to each other.
6. `auditLogs/{autoId}` entry (`actingAdminUid`, `targetUid`, `action: 'createStaffAccount'`, `role`, `timestamp`) — written last; a failure here does not roll back an otherwise-successful creation, only gets logged for operational visibility, matching the relative priority already established in `setStaffStatus`/`permanentlyDeleteDevice`.

**The five cases, resolved by request identity, not content:**

| Case | Resolution |
|---|---|
| Normal new creation | Tracking doc claim succeeds (fresh id) → full flow. |
| Orphaned Auth user → resume | Tracking doc `status == 'authCreated'` with a `uid` that `admin.auth().getUser()` still confirms exists → skip Auth creation, resume at the Firestore batch using that `uid`. |
| Completed same-request retry → idempotent success | Tracking doc `status == 'completed'` → return `{ uid }` immediately, zero writes. |
| Genuine pre-existing/duplicate account | Fresh claim, but `admin.auth().getUserByEmail(email)` resolves to an account this `requestId` doesn't own → reject `already-exists`. |
| Existing account with a "conflicting" role | Collapses into the case above — **role plays no part in the identity decision.** An unrelated pre-existing account is rejected whether its role happens to match or differ from what was requested; only this exact `requestId`'s own tracked `uid` can ever resolve to success. |

**Idempotency and self-healing are part of the implementation contract, not optional hardening.** The gap between Auth creation and the Firestore batch is the one place a partial account can exist:
- **Primary: compensating delete.** If the Firestore batch throws after Auth creation succeeded, catch it, call `admin.auth().deleteUser(uid)`, reset the tracking doc back to `pending`/`uid: null` so a clean retry can re-create Auth cleanly, then rethrow.
- **Safety net:** if the compensating delete itself fails (crash, timeout), leave the tracking doc at `authCreated`/`uid` set — the next retry with the same `requestId` finds it and resumes via the table above, rather than requiring manual cleanup.
- The pre-flight `getUserByEmail` duplicate check is a fast-fail nicety; `admin.auth().createUser`'s own `email-already-exists` error remains the authoritative backstop if two different `requestId`s ever race past it simultaneously.

**Test-only failure injection, for verifying the compensating-delete path specifically:** since this function runs via the Admin SDK, its Firestore writes bypass Security Rules entirely — the deny-rule technique used for the `MaintenanceListCubit` client-side failure-path test (PR #23) does not apply here. Instead, a guarded synthetic throw sits as the first statement in the Firestore-batch try block, gated on **two independent conditions**: `process.env.FUNCTIONS_EMULATOR === "true"` (set automatically by the Firebase emulator harness, structurally absent from any real deployed function — not a convention, a property of which runtime executed the code) AND an explicit `request.data.__testInjectFailure === "afterAuthBeforeFirestore"` payload field. Neither condition is reachable in production regardless of what a caller sends. Kept permanently in committed source, not revert-before-commit like the client-side emulator flags from ADR-005 — those lived in a mobile binary end users hold (a genuine on-device attack surface); this lives only in Cloud Functions source deployed by the project owner, with an environment no caller can manipulate.

**Initial `staffStatus`: active by default, product-owner decision (2026-07-25).** Creating the account is itself the Admin's act of granting access — there is no separate "provisioned but not yet granted" state in the shipped `active|inactive` schema, and inventing one would make ordinary creation carry an extra required step for no normal-case benefit. If an account genuinely needs to be prepared ahead of an employee's start date, the already-shipped `setStaffStatus` covers it for free: create, then immediately deactivate — an explicit extra step for the rare case, not the default for the common one.

**Admin creating another Admin is allowed, through the same function, same authorization boundary — product-owner decision (2026-07-25).** No separate mechanism or extra server-side gate for `type == 0` specifically: only an authenticated, active Admin can call `createStaffAccount` at all, and that boundary is already as strong as this action needs. The one requirement carried into the client implementation shape: the UI must make selecting the Admin role visually distinct enough that it cannot be assigned by an inattentive click — a UI/UX requirement, not an additional authorization layer.

**Staff-management surface (list/filter/activate/deactivate):**
- New Admin-only route, guarded the same way as `archivedDevices` (`UserRole.isAdmin` check before building the screen).
- Lists `users` filtered to `type ∈ {0, 2, 3}`, each cross-read against its own `meta/staffStatus`. **Pagination deliberately deferred** (product-owner decision, 2026-07-25) — the current staff roster is small enough that it would be premature infrastructure; revisit only if roster size ever makes it a real problem.
- Filterable by role and status, per this ADR's original 2026-07-03 recommendation.
- Activate/Deactivate calls the **already-shipped, unmodified `setStaffStatus`** — no backend change needed for this half at all.
- Account creation is folded into this same surface (a "New Staff Account" affordance on the list), not kept as a separate standalone destination.

**Existing manually-created staff accounts require no migration.** `createStaffAccount` produces exactly the `users/{uid}` + `meta/staffStatus` shape that any currently-active staff account must already have — if one didn't, it would already be failing today's shipped fail-closed sign-in gate (`AuthCubit._fetchStaffIsActive`), independent of anything in this design. The list/filter surface and `setStaffStatus` therefore work uniformly regardless of whether an account was created via Console or via this function, by construction — no backfill script, no reconciliation step.

**`NewUserAdminSide`'s disposition:** rebuilt as the create-account view inside the new staff-management surface (reusing its existing name/email/password/role fields, minus the photo picker), not left standing as a separate drawer-level screen, and not deleted outright without replacement.

**Correction (PR 2 implementation, 2026-07-25): `lib/features/create_user_account/` is NOT dead code and must not be removed.** The original Admin-area review's grep search used the wrong class name (`CreateUserAccountView`, matching the filename, instead of the actual class `CreateUserAccount`) and produced a false "zero call sites" result. `CreateUserAccount` is the live screen `MainScreen` renders on `AuthNeedsProfileCompletion` — the customer phone-OTP profile-completion step, unrelated to staff account management entirely. Caught before deletion, during PR 2's implementation, by re-grepping for the actual class name while wiring up the new imports. `main_drawer.dart` (the old, separately-and-correctly-confirmed-dead `MainDrawer` class — see `BACKLOG.md` item 7) was removed instead, as a directly necessitated side effect of removing `NewUserAdminSide`: it held the only remaining reference to that class, and was already flagged unused with no live import anywhere.

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

- Should role-change and activation be built together or as two separate releases, given the recommendation to treat role-change as higher-risk? **Answered by the 2026-07-25 pass: separately** — creation and status are now settled and implementation-ready; role-change stays untouched and deliberately deferred, exactly as originally recommended.
- Should the audit log be visible anywhere in the app (e.g., an Admin-facing history view), or purely a backend record for incident investigation? **Still open** — deliberately kept out of the 2026-07-25 pass as its own separate decision thread, not a hard dependency of account creation or the management surface.
- Any compliance/retention requirement for the audit log itself? **Still open**, same reason as above.

## Explicitly not decided by the 2026-07-25 pass

- **Role-change (`setUserRole`)** — untouched, exactly as originally scoped in this ADR's 2026-07-03 proposal.
- **Audit-log visibility in-app and its retention/compliance requirements** — a separate decision thread, not a dependency of this pass.
- **Admin dashboard/reporting** (Business Lens: Relationship Health, Operational Trends) — unrelated surface, not expanded into by this work.
- **Forced first-login password change**, or any broader password-lifecycle policy beyond "Admin sets an initial credential" — a real candidate future improvement, explicitly not assumed or designed here.
- **Staff self-service profile editing** (including ever adding a photo) — would be the natural home for anything beyond what's captured at creation; not designed here.
