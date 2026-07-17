# ADR-003: GuestAccount Handling

**Status:** Approved and implemented (Option B — disabled/neutralized, retained as a reserved value) as part of the Phase 1A allow-list refactor, 2026-07-03. See `docs/ai-workflow/PHASE1_CLOSURE_SUMMARY.md` and the 2026-07-03 entries in `docs/ai-workflow/DECISIONS_LOG.md` for the confirmed outcome.
**Date:** 2026-07-03
**Related:** `docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md` §5c; `docs/ai-workflow/PERMISSIONS_MATRIX.md`; `ADR-002-role-management.md` (allow-list vs. deny-list note)

## Context

**Product-owner clarification (2026-07-03):** `GuestAccount` (`type == 9`) currently has **no business role or intended permissions**. It exists historically, and may or may not be used in the future. It should be treated as an **undefined role** — this ADR should not design a permission model or feature set around it beyond what's necessary to eliminate its current, demonstrated risk.

This directly resolves the "Unknown" left open in `PERMISSIONS_MATRIX.md` ("What is a GuestAccount?") — the answer is: nothing, by design, today.

## Current behavior (fact)

Despite having no intended role, `type == 9` is not actually *inert* in the code — it is affirmatively granted staff-level behavior in at least three places, all stemming from the same root pattern: permission checks written as **deny-lists** (`type != 1`, i.e. "anything that isn't Customer") rather than **allow-lists** (explicitly listing which roles get a capability):

1. `main_screen.dart:60` — `listenToMaintenanceDevices(state.userData!.type == 1 ? state.userData!.uid : null)`. Any role other than Customer, including Guest, gets `uid: null`, which triggers the **entire, unfiltered** `maintenanceDevices` collection stream — every customer's device records, system-wide.
2. `inner_maintenance_list.dart` — `isEmployee = homeState.userData.type != 1` shows the "add new device" floating action button to Guest.
3. `device_details_sheet.dart` — receives `isEmployee` (sourced from the same check above) and uses it to decide whether to display `pin`, `patternLock`, and `notesHidden` — meaning Guest currently sees exactly the data `ADR-001` establishes customers must never see, and that no legitimate business role has been defined to justify Guest seeing either.

**Fact:** no code path anywhere in this codebase creates a `UserData` with `type: 9`. `UserData`'s model default is `1`; `AuthServices.completeUserProfile` always hardcodes `type: 1`; `CacheServices.getUserData()` reads whatever integer is cached with no default substitution (and throws via `!` if absent, rather than defaulting to `9`). **This means, as far as this repository can determine, no account with `type: 9` is ever produced by the app itself.** Whether any such account already exists in production Firestore (e.g., created manually, or a relic from before this codebase's current state) is an **Unknown this review cannot resolve** — it would require checking the live `users` collection directly.

## Risks

- **If no `type: 9` account exists today:** the risk is latent, not active — but it's a live landmine. The moment any account ends up with `type: 9` (a manual Firestore edit, a future feature, a data-import script, or simply someone testing "what happens with an unrecognized role") that account silently inherits full staff-equivalent visibility into every customer's devices, PINs, pattern locks, and internal notes, with no code path having ever intended that.
- **If a `type: 9` account already exists in production:** this is not latent — it's an active, undetected exposure right now, and this review cannot confirm or rule it out from the repository alone.
- **Root cause is systemic, not guest-specific.** The deny-list pattern (`type != 1`) means *any* future role value — a typo, a new role added later without updating every one of these checks, a malformed/corrupted field — inherits staff access by default. Guest is the currently-visible symptom; the pattern itself is the real defect (see `ADR-002`'s allow-list recommendation, which addresses this at the root for all roles, not just Guest).

## Options considered

### Option A — Remove GuestAccount entirely

Delete all `type == 9` / `// 9 for guest` references; treat `type` as strictly one of `{0, 1, 2, 3}` going forward; add validation that rejects or safely handles any other value.

- **Pros:** Eliminates the concept entirely — nothing to misclassify because the value is no longer meaningful anywhere. Simplifies the eventual role enum (`ADR-002`) to four members instead of five.
- **Cons:** Contradicts the product owner's explicit statement that Guest "may or may not be used in the future" — full removal discards the reserved value, so reintroducing it later means redoing this analysis from scratch. If a `type: 9` account already exists in production (unconfirmed), removing all handling leaves undefined behavior for it rather than a deliberate, safe outcome.

### Option B — Disable/neutralize GuestAccount, but retain it as a reserved, explicitly-inert value

Keep `9` as a known constant (e.g., a reserved member in the future role enum from `ADR-002`), but fix every current check so Guest is **denied by default** everywhere, the same as any other non-explicitly-granted role would be once the allow-list pattern from `ADR-002` is adopted. Concretely: the three call sites in "Current behavior" above stop using `type != 1` and instead use explicit allow-lists (e.g., "unfiltered device stream is granted to `[admin, reception, maintenance]`" — Guest is simply not on that list, with no special-casing required).

- **Pros:** Directly and immediately eliminates the demonstrated exposure. Requires no new feature design or permission model for Guest — it ends up with zero capabilities purely as a side effect of the allow-list pattern, not because anyone designed a "Guest experience." Preserves the reserved value per the product owner's "may or may not be used in future" — if Guest is ever given a real purpose later, there's a known, safely-inert starting point rather than an undefined gap. This is a natural byproduct of the `ADR-002` allow-list fix, not extra work specific to Guest.
- **Cons:** A small amount of "reserved but unused" surface remains in the codebase (one enum value with no current behavior). Mitigated by this ADR serving as the documented rationale, so it doesn't read as a mystery to future engineers.

### Option C — Leave as-is

Explicitly rejected. The current behavior is a confirmed, demonstrated exposure of customer PINs, pattern locks, and internal notes to an undefined role, which directly contradicts both the original audit's "treat missing rules as a major risk until proven otherwise" instruction and this session's clarification that customers must never see this data (Guest seeing it is no better than a customer seeing it — arguably worse, since Guest's identity/legitimacy is even less established).

## Recommendation

**Option B** — disable/neutralize, retain the reserved value. This is "necessary" in the sense the product owner's instruction allows for ("do not design around it unless necessary"): fixing an active, confirmed exposure is not the same as proactively building a feature or permission model for a role that doesn't have one. No new capability, UI, or business logic is being added for Guest — the fix is purely subtractive (removing accidental grants) and falls out naturally from the broader allow-list fix already recommended in `ADR-002` for unrelated reasons (closing the same class of bug for all roles, not just this one).

Concretely, this means: when the role checks in `main_screen.dart`, `inner_maintenance_list.dart`, and `device_details_sheet.dart` are updated as part of implementing `ADR-002`'s role model, Guest requires **no special-case code at all** — it's simply absent from every allow-list, which is the correct, minimal, "don't design around it" outcome.

## Consequences

- No standalone Guest-specific code change is needed if `ADR-002`'s allow-list refactor is implemented — this ADR's recommendation is satisfied as a side effect, not a separate workstream. If `ADR-002` is deferred, the three call sites listed under "Current behavior" should still be patched directly and promptly as a narrower, standalone fix, since this is a confirmed data-exposure bug independent of the broader role-model timeline.
- If Firestore rules are later written for `maintenanceDevices` (per `ADR-001`/`docs/ai-workflow/archive/phase1-audit/SECURITY_AUDIT.md`), Guest should not appear in any `allow read`/`allow write` clause — it inherits Firestore's default-deny behavior automatically, requiring no explicit "deny guest" rule to be written.

## Whether GuestAccount should be removed, disabled, or retained

**Recommendation: disabled (neutralized), and retained as a reserved value** — not removed, and not left as-is. This matches Option B above and directly answers the product owner's question: the constant/value stays (for possible future use), but every current behavior that grants it unintended access is eliminated.

## Open questions for product owner

- Whether to check the live `users` collection in the Firebase Console now for any existing `type: 9` accounts, to rule out (or respond to) an active exposure rather than only a latent one. This is a quick, read-only check outside this repository's visibility.
- None of this ADR's recommendation requires further product input to proceed once approved — it is intentionally scoped to *not* require designing Guest's future purpose, per the original instruction.
