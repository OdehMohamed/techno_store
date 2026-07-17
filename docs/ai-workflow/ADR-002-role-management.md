# ADR-002: User Role Immutability and Management

**Status:** Phase 1 (Option 1 — rules-enforced immutability) approved and implemented as part of Phase 1, 2026-07-03; see `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` and `docs/ai-workflow/DECISIONS_LOG.md` for the confirmed outcome. **Phase 2 (Option 2 — Custom Claims) remains proposed, not implemented**, with no current schedule — see `docs/ai-workflow/BACKLOG.md` item 1h for the related, also-deferred admin user-management feature it would naturally sequence alongside.
**Date:** 2026-07-03
**Related:** `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md` §5a, §5e; `docs/ai-workflow/PERMISSIONS_MATRIX.md`; confirmed role mapping (Admin=0, Customer=1, Reception=2, Maintenance=3, Guest=9)

## Context

`UserData.type` (`int`) is the sole role field. It is written by an ordinary client-side `Firestore.set()` call (`FirestoreServices.saveUserData`) with no server-side validation anywhere. Two concrete facts drive this ADR:

1. **CRITICAL finding (SECURITY_AUDIT.md §5a):** because nothing validates writes to `users/{uid}`, any authenticated user can set their own `type` to `0` (Admin) via a direct Firestore SDK/REST call, bypassing the app UI entirely. The app trusts whatever value is stored, with no re-verification.
2. **The intended role-assignment flow doesn't work.** `NewUserAdminSide` (an Admin picks Reception/Maintenance/Admin via radio buttons and creates an account) has its actual account-creation call commented out — the feature is a non-functional stub. If it were "fixed" by simply uncommenting the existing code, the restored code path (`AuthServices.signUpWithEmailAndPassword` → `UserData(..., type: type)` → `saveUserData`) would still be a **client-side write of an arbitrary role value** — i.e., naively restoring it would reintroduce the same vulnerability as finding #1, just from a different screen. Any fix to this flow must go through whatever mechanism this ADR settles on, not the original commented-out code as-is.

## How roles should be assigned (options)

### Option 1 — Firestore field, rules-enforced immutability

Keep `type` as a Firestore field on `users/{uid}`. Add a security rule that permits a client to `update` their own profile document only if the new `type` equals the existing `type` (i.e., every field except `type` is client-editable; `type` can never change via a client write, full stop — not even to the same role by a different actor, and never to a different one). The **only** way to change a role becomes a trusted, out-of-band process: a script run with the Firebase Admin SDK (which bypasses security rules by design) or a direct edit in the Firebase Console, performed by a trusted operator.

- **Pros:** Smallest possible change — no new infrastructure. Directly and immediately closes the CRITICAL self-promotion hole. Keeps the data model exactly as it is today, so all existing UI code that reads `state.userData.type` keeps working unmodified.
- **Cons:** Every other Firestore rule that needs to know "is this caller an Admin/Reception/etc." (e.g., rules on `maintenanceDevices`) must perform a `get()` lookup of `users/{uid}` from *within* the rule to read the current role — and that lookup is itself billed as a document read on every single request those rules evaluate (flagged already in `SECURITY_AUDIT.md` §9 and `FIREBASE_COST_REVIEW.md`). Role changes require manual operator action every time — no self-service admin tooling, which may or may not be acceptable depending on how often roles change in practice (**Unknown — needs product-owner input on expected frequency**).

### Option 2 — Firebase Auth Custom Claims as the authoritative role store

Store the role in the user's Firebase Auth **custom claims** (baked into their verified ID token, e.g. `token.role == "admin"`), set exclusively via the Firebase Admin SDK — there is no client-side API that can set custom claims at all, so this isn't "restricted by a rule that could have a bug," it's structurally impossible for a client to touch. Firestore/Storage rules then check `request.auth.token.role` directly, with no extra document read. This is Firebase's own recommended pattern for role-based access control. The `users/{uid}.type` Firestore field would become a **denormalized read-model**, kept in sync by whatever trusted process sets the claim, purely for the convenience of existing UI code that reads it — never itself a source of authority.

- **Pros:** The strongest possible guarantee against self-promotion (not just "no client write path exists today," but "no client write path can exist, by API design"). Zero added cost to every other rule that checks role (claims are already in the verified token — no `get()` needed). This is the well-established, recommended long-term pattern for exactly this problem in Firebase applications.
- **Cons:** Requires standing up Cloud Functions in a project that has none today — meaningful new infrastructure (deploy pipeline, monitoring, cost model), not a small addition. Requires a way to actually *invoke* the claim-setting function — e.g., an admin-only callable function (itself gated on "caller already has the admin claim," which requires bootstrapping the very first Admin's claim manually). Clients must force-refresh their ID token (or re-authenticate) to see a newly assigned role take effect — a UX detail to design for (Flutter's `FirebaseAuth` SDK supports `getIdTokenResult(true)` for this). Introduces a "dual write, single source of truth" pattern to reason about (claims are authoritative; the Firestore field is a synced copy) — more moving parts than Option 1.

## Recommendation: phased approach

**Phase 1 (immediate — closes the CRITICAL finding with no new infrastructure): Option 1.** Add the rules-enforced immutability described above, and treat role assignment/change as a manual, trusted-operator action (Admin SDK script or Console edit) until Phase 2 is justified. This is the right near-term fix given this codebase currently has no Cloud Functions, no CI, and no existing admin tooling — introducing all of that just to close one field-write hole is disproportionate to the immediate problem.

**Phase 2 (recommended target state, larger investment, not urgent): Option 2.** Once there's a real, recurring operational need for self-service role assignment (e.g., Admins frequently onboarding new Reception/Maintenance staff — which is exactly what `NewUserAdminSide` was apparently built for), migrate to Custom Claims via a minimal admin-only Cloud Function, keeping the Firestore field as a synced read-model. This is the point at which fixing `NewUserAdminSide` for real becomes worthwhile — its account-creation flow should call this trusted function, not perform a direct client-side Firestore write of the chosen role.

**Do not** treat "uncomment `NewUserAdminSide`'s existing code" as an acceptable fix at any point — it predates this ADR and writes the role directly from the client, which is the exact vulnerability being closed.

## How role changes should happen (process, not just mechanism)

- **Phase 1:** a trusted operator (initially, presumably the product owner or a designated technical admin) runs an Admin SDK script or edits the Firebase Console directly to set/change a `type` value. This is manual and low-volume by design — acceptable for infrequent role changes, not intended as a long-term operational pattern.
- **Phase 2:** an existing Admin, authenticated in the app, uses a rebuilt `NewUserAdminSide`-equivalent flow that calls an admin-only Cloud Function to create the account and set its role/claim server-side. The function itself must verify the caller already holds the Admin claim before acting — this is the actual authorization boundary, not a UI-level check.
- In both phases, **the app's own UI should never be the last line of defense** for who can change a role — that must be enforced where the write actually happens (rules in Phase 1, an authorization check inside the trusted function in Phase 2).

## Server-side enforcement recommendations (summary)

- Firestore rule on `users/{uid}`: allow `update` only if `request.resource.data.type == resource.data.type` (role cannot change via any client write, ever) — applies regardless of the caller's own role, including Admins acting on their own document.
- No rule should ever allow a client to set `type` to a specific value directly, even conditionally by role — role changes for *other* users should go through Phase 2's function (which uses the Admin SDK internally, bypassing rules entirely by design) rather than through a client-writable Firestore path with a permissive rule, since the latter reintroduces the same class of risk this ADR exists to close.
- Once Phase 2 lands, all role-based rules across the project (`maintenanceDevices`, Storage paths, etc. — see `PERMISSIONS_MATRIX.md`) should be migrated from `get(/databases/.../users/$(uid)).data.type` lookups to `request.auth.token.role` checks, both for cost (per `FIREBASE_COST_REVIEW.md`) and for the stronger tamper-resistance guarantee.
- **Implementation note carried over from the audit:** when the role model is actually implemented in code (as an enum or named constants replacing the current raw `int`), permission checks should be written as **allow-lists** ("this capability is granted to `[admin, reception, maintenance]`") rather than the current **deny-list** pattern (`type != 1`, meaning "not customer"). The deny-list pattern is what caused the separate Guest-role exposure documented in `ADR-003-guest-account-behavior.md` — an allow-list approach fails closed for any role not explicitly listed, including undefined or future ones, instead of failing open.

## Open questions for product owner

- Expected frequency of role changes/new staff onboarding — informs how soon Phase 2 is worth prioritizing over Phase 1 alone.
- Who is the trusted operator for Phase 1 manual role changes, and how should the very first Admin account be established (bootstrapping problem shared by both phases)?
