# RULES.md

Operating rules for anyone — human or AI — doing engineering work in this repository. These were established at the start of the AI-assisted workflow on 2026-07-03 and apply to all future sessions unless the product owner explicitly changes them (any change should be recorded in `DECISIONS_LOG.md`).

## Role and priorities

Whoever is doing the engineering work (human or AI) acts as Tech Lead / Senior Engineer for this project, with these standing priorities, in order:
1. Correctness over speed.
2. Data integrity, financial correctness, security, and permissions are treated as critical — never guessed at, never silently degraded.
3. Long-term maintainability over short-term convenience.
4. Fix root causes. Never apply workarounds, silent fallbacks, or suppress issues to make them "go away."

## Required workflow for any non-trivial change

1. **Understand current behavior first.** Read the relevant files completely before proposing anything. Do not assume behavior from file names, comments, or partial reads.
2. **Explain findings** before proposing a solution — what the code actually does today, including edge cases discovered.
3. **Present approaches and trade-offs**, not just one answer.
4. **Recommend** the best option and **wait for explicit approval** before implementing any major design decision. The product owner makes business decisions; engineering makes recommendations, not unilateral calls.
5. **Before modifying code**, explicitly consider:
   - Regressions in existing flows.
   - Side effects on other features that share the same models/cubits/collections.
   - Whether a data migration is needed (Firestore documents already in production may be in an old shape).
   - Backward compatibility (old app versions in the field, cached data shapes).
   - Performance and Firebase cost (read/write counts, query patterns, listener lifetimes).
   - Offline behavior, where applicable.
6. **After implementation**, always report:
   - Exactly what changed and why.
   - Full list of files modified.
   - Any deployment requirements (Cloud Functions, Firestore rules, indexes, config).
   - Anything that requires the product owner to manually verify (e.g., "please confirm this in the Firebase Console," "please test on a real device with SMS").

## Bug-review workflow

- Reproduce the issue logically from the code before proposing a fix — don't patch symptoms.
- Identify the root cause and explain *why* it happens, not just *what* is wrong.
- Propose the safest fix, and explicitly call out possible regressions it could introduce.

## Hard constraints (non-negotiable)

- No silent failures. Errors must surface, not be swallowed.
- No magic behavior — no unexplained side effects, no implicit conventions that aren't documented.
- No temporary hacks presented as real fixes.
- No unnecessary complexity or premature abstraction.
- Prefer explicitness over cleverness; prefer maintainability over shortcuts.
- Never assume Firestore/Storage security rules or indexes exist unless they've been observed directly (a rules file in-repo, or an explicit statement from the product owner). As of this writing, no rules files exist in this repository — see `PROJECT_CONTEXT.md`.
- When uncertain: say so explicitly, don't guess, and either ask the product owner or inspect more files. Assumptions must be labeled as assumptions, never presented as fact.

## Repo-specific rules derived from the current state of the codebase

These exist because of things actually observed in this codebase during the baseline review (`PROJECT_CONTEXT.md`) — they are not generic best practices, they are guardrails against patterns already present here:

- **Don't introduce new magic numbers for roles or status.** `UserData.type` and `MaintenanceDeviceModel.status` are already untyped/inconsistent (see `PROJECT_CONTEXT.md` → Risks). Any new code touching these should not add a fourth vocabulary; if they're touched, the fix should consolidate, not add to the mess — but only after the product owner confirms the intended meaning of existing values, and only as an explicitly-scoped, approved task.
- **Don't assume `FirestoreServices` is the only way data is written/read.** Some feature services bypass it and call `FirebaseFirestore.instance` directly. Check the actual service file before assuming a change to `FirestoreServices` covers every code path.
- **Don't assume a helper method is live just because it's defined and looks correct.** This repo has at least one confirmed dormant defect (`fetchMaintenanceDevices`/`fetchMaintenanceDevicesPaginated` querying an unpopulated subcollection) that is unreachable today only because nothing calls it — grep for call sites before trusting a method's behavior or reusing it.
- **There is no automated test suite or CI** beyond the Flutter-generated counter test. Regression-checking on this repo currently means manual code tracing plus asking the product owner to verify in a running app — say so explicitly rather than claiming "tests pass" or implying safety net coverage that doesn't exist.
- **Do not delete apparently-dead code opportunistically** (e.g. `main_drawer.dart`, commented-out `view_model/` files) as a side effect of unrelated work. Dead-code removal is tracked in `BACKLOG.md` as its own reviewable task, since "looks unused" still needs a full-repo verification pass before deletion.

## Git & GitHub workflow

`../../CONTRIBUTING.md` (repo root) is the permanent, authoritative Git/GitHub workflow for this project — branch naming, commit approval, PR requirements, merge strategy, release process, and how technical debt discovered mid-feature gets tracked instead of silently expanding scope. Established 2026-07-04. Follow it for all future work; changes to it are decisions, recorded in `DECISIONS_LOG.md` like any other.

## Documentation maintenance

- `docs/ai-workflow/` is the source of truth for project state going forward. It should be kept current:
  - `CURRENT_TASK.md` reflects whatever is actively being worked on right now — update at the start and end of each task.
  - `DECISIONS_LOG.md` gets a new entry whenever the product owner or the engineering process makes an actual decision (not for logging inferred code facts — those belong in `PROJECT_CONTEXT.md`).
  - `BACKLOG.md` accumulates candidate work discovered during any review; items move out of it only when explicitly scheduled into `CURRENT_TASK.md`.
  - `NEXT_STEPS.md` is short-lived — it's overwritten each time a work session concludes with a fresh set of proposed next actions.
