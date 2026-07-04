# CONTRIBUTING.md — Git & GitHub Workflow

**Status: permanent operating rule for this repository**, established 2026-07-04, referenced from `docs/ai-workflow/RULES.md`. Applies to all future work, by anyone — human or AI — on this project, until explicitly revised (revisions get recorded in `docs/ai-workflow/DECISIONS_LOG.md`).

This document exists to make development predictable, traceable, and maintainable as the project grows. It reflects decisions the product owner made on 2026-07-04, with a small number of refinements proposed during drafting — those are called out explicitly as **[Proposed]** below rather than silently folded in, since they weren't in the original request and deserve a deliberate yes/no. All `[Proposed]` items in this document have been reviewed and approved.

---

## 1. Feature planning

- Understand the requested feature before writing code — read the relevant existing code, don't assume behavior from names or partial reads.
- Assess architectural impact: does this touch shared/core code, the data model, security/permissions, or multiple features at once?
- Not every change needs a written plan. Use this heuristic: small, well-scoped fixes or additions confined to one feature can proceed straight to implementation. Anything touching shared core code (`lib/core/`), the Firestore schema, security rules, or spanning multiple features gets a short plan (a few sentences to a paragraph: what will change, why, what it touches) shared for approval *before* implementation. This mirrors what `docs/ai-workflow/RULES.md` already requires for "non-trivial changes" — this section just makes the trivial/non-trivial line concrete instead of leaving "if needed" to judgment calls each time.
- If a new architectural issue, technical debt item, or risk is discovered while planning, do not fold it into this feature's scope — see §12.

## 2. Branch strategy

- **Never commit directly to `main`.** All work happens on a branch.
- Branches are always created from the latest `main` (`git fetch origin && git checkout -b <branch> origin/main`), not from a stale local `main`.
- **Naming convention**: `<type>/<short-kebab-case-description>`, e.g. `feature/customer-device-history`, `fix/cascade-delete-storage-race`, `refactor/maintenance-list-services`.
- Types, aligned 1:1 with the Conventional Commit types used in §5 so branch prefix and commit type always match:
  - `feature/` — new functionality
  - `fix/` — bug fixes
  - `refactor/` — restructuring without behavior change
  - `docs/` — documentation only
  - `chore/` — tooling, dependencies, config, maintenance
  - `hotfix/` — urgent production fix, branched from `main` and merged back fastest-path (still via PR, never a direct push — see §8)
- Keep a feature branch reasonably current with `main` (rebase or merge from `main` periodically on longer-lived branches) so the eventual PR diff stays reviewable and merge conflicts don't pile up silently.

## 3. Sensitive files & secrets policy

**Before every commit, push, pull request, release, or tag**, perform a repository safety check to confirm no sensitive file is tracked or about to be pushed.

This is not a hypothetical precaution — it has already happened twice in this repository during the setup of this very workflow: a production-data backup directory (containing real customer PII and plaintext PINs/pattern locks) and the Android app signing keystore were both found unprotected in `.gitignore` before being caught and fixed. Both would have been serious incidents if committed. This section exists specifically because of that.

**Sensitive categories** (not exhaustive — when in doubt, treat it as sensitive):
- Signing keys / keystores (`*.jks`, `*.keystore`)
- Service account keys and other credential files
- Certificates and private keys
- Local databases and database dumps
- Backup files, especially anything containing production data
- API keys, tokens, or credentials of any kind
- Environment files (`.env` and variants)
- Generated local artifacts that happen to contain the above (e.g., a migration script's local output directory)
- Any other confidential project asset not listed here but recognizable as such

**The check, concretely**: before the action in question, run `git status` and `git diff --stat` and actually read the output — don't skim past it. When new tooling or infrastructure is introduced (a new CLI, a new build step, a new integration), check what it generates or writes to disk and confirm `.gitignore` already covers it *before* it has a chance to be staged, not after.

**If a sensitive file is discovered** (tracked, staged, or about to be pushed):
1. Stop immediately — do not proceed with the commit/push/PR/release/tag in progress.
2. Explain the specific risk (what the file is, what exposure would mean).
3. Update `.gitignore` to cover it.
4. If it's already tracked in git history, flag that removing it from history (not just the working tree) is a separate, more invasive operation than a normal `.gitignore` fix — do not attempt a history rewrite without explicit approval, since that's a hard-to-reverse operation with implications for anyone who's already pulled.
5. Wait for explicit approval before continuing with the original action.

`.gitignore` (and the nested `android/.gitignore`, `ios/.gitignore`) must be kept up to date whenever new tooling or infrastructure is introduced — this is a standing requirement, not a one-time cleanup.

## 4. Development

- Work only on the feature branch for that feature — no mixing unrelated changes in.
- Large features: split into logical milestones. Each milestone should be independently reviewable (a coherent slice of the work), not an arbitrary time-boxed chunk.
- For features large enough to span many days or touch many files, consider whether splitting into two or more sequential PRs (each building on the last, each independently mergeable to `main`) produces a more reviewable result than one large PR at the end. Not a hard rule — a judgment call per feature, flagged for discussion at planning time (§1) if it looks like it'll apply.
- Related work is grouped into meaningful commits, not one giant commit at the end — see §5.

## 5. Commit quality

- **Conventional Commits format**: `<type>(<scope>): <description>`. This repo's existing history already uses this style informally (`feat(maintenance): assign devices on signup`, `fix(android): recreate android folder...`) — this section formalizes what was already the de facto convention rather than introducing something new.
  - Types: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `perf`, `build`, `test` (once tests exist).
  - Scope: the feature/module affected, e.g. `(maintenance)`, `(auth)`, `(rules)` — optional but preferred when it adds clarity.
- **One commit = one logical unit of work.** If describing a commit needs "and," it's probably two commits.
- **The project should remain buildable after every commit, whenever reasonably possible** — concretely, for this repo today, that means `flutter analyze` runs clean (no new errors/warnings introduced) and the app compiles. This repo has no automated test suite today (per `docs/ai-workflow/RULES.md`), so "buildable" here means compiles and analyzes cleanly — it is not a substitute for manual verification of actual behavior, and should never be described as "tests pass" when no tests exist.
- **Never commit secrets, credentials, or production data exports** — see §3 for the full policy and the concrete check to run before every commit.

## 6. Commit approval

Before creating any commit:
1. Summarize what was completed.
2. Summarize exactly what the commit will contain (file list).
3. Propose the exact commit message.
4. **Wait for explicit approval before running `git commit`.**

No commit happens without this loop completing, every time — not just for the first commit of a session. Commits are approved and created **one at a time**: present a proposed commit, wait for approval, create it, then move to the next — never batch-approve a sequence of commits in advance.

## 7. Push

- After a commit is approved and created, push the branch normally (`git push -u origin <branch>` on first push, `git push` thereafter).
- Before pushing, re-run the §3 sensitive-files check — it applies here too, not just at commit time.
- **All Git operations use the project's local Git identity; no external or automated identity attribution is introduced.** This includes bot accounts, GitHub Apps, CI service identities, or AI-assistant-specific trailers (e.g. `Co-Authored-By: Claude...`) — regardless of what tooling is used to make the commit, only the actual local operator's configured identity appears in the history. This overrides any default behavior that would otherwise add such attribution, and stays valid even if the tooling used for development changes in the future.
- The repository remains private. Nothing about this workflow changes that, and no step in it should ever assume or imply public visibility.

## 8. Pull Requests

When a feature (or milestone, per §4) is complete:
1. Push the branch.
2. Open a PR against `main` (`gh pr create`).
3. Critically review the diff yourself before asking for review — read it as if reviewing someone else's code, not as the author.
4. The PR description includes, every time:
   - **Summary** — what changed and why.
   - **Risks** — what could go wrong, what's untested, what assumptions were made.
   - **Testing performed** — exactly what was manually verified (and honestly note what wasn't, given no automated suite exists).
   - **Breaking changes** — any, or explicitly "none."
   - **Rollback considerations** — how to undo this if it causes a problem in production, when relevant (e.g., does it touch data, rules, or just app code that reverts cleanly via a normal revert-and-redeploy).
5. **Wait for explicit approval before merging.** No self-merging.

## 9. Merge

- Merge only after explicit approval.
- Default merge strategy: **squash merge**, producing one clean, Conventional-Commit-formatted commit on `main` per feature. This keeps `main`'s history readable as a changelog of features/fixes rather than a mix of in-progress commits. For a large, multi-milestone feature where the individual commits are independently meaningful and worth preserving in `main`'s history, a regular merge commit is the exception — decide per-PR, default to squash.
- Keep `main` stable — it should always be in a releasable state.
- Delete the branch once merged and no longer needed (see §10).

## 10. Repository hygiene

- Delete merged branches, both local and remote, promptly.
- Periodically check for stale branches (no commits in a long time, never opened as a PR, or superseded by other work) and remove them after confirming they're not silently in-progress work.
- Keep local and remote in sync — don't let local branches linger unpushed, and don't leave remote branches that no longer correspond to active local work.
- Keep history organized: this is what §5's commit discipline and §9's squash-merge default are for — hygiene is mostly a byproduct of doing 5 and 9 consistently, not a separate cleanup effort.

## 11. Release workflow

Whenever a new version is to be published:
1. Verify `main` is stable (builds, analyzes cleanly, no known open regressions).
2. Confirm no unfinished or forgotten branches are silently carrying work that should be in this release.
3. Re-run the §3 sensitive-files check against the release artifact scope, not just the usual commit diff.
4. Recommend a semantic version bump (`MAJOR.MINOR.PATCH`) based on what actually changed since the last release — breaking change → major, new feature → minor, fix-only → patch. Given this project uses Shorebird: also state explicitly whether the changes are Shorebird-patchable (Dart-only, no native/plugin/asset changes) or require a full new store release (native code, new plugins, asset changes) — this affects what you'll actually need to do with the recommended version, since a patch-level Dart-only fix might ship as a Shorebird patch against an existing release rather than a new version at all.
5. Update `pubspec.yaml`'s `version:` (and any other version/build number references) to match.
6. Create the Git tag (`git tag -a vX.Y.Z -m "..."`, pushed with `git push origin vX.Y.Z`).
7. Create the GitHub Release (`gh release create`) attached to that tag.
8. Generate release notes in two forms:
   - **Technical release notes** (GitHub Release body) — organized by type (Features / Fixes / Security / Internal), referencing the actual changes.
   - **Store-ready release notes** — short, user-facing, no technical jargon, formatted for Google Play's and the App Store's "what's new" fields (these have different tone conventions than a technical changelog — plain language, what the user gets out of it, not implementation detail).
9. Maintain a `CHANGELOG.md` at the repo root, updated as part of each release.

**Explicitly out of scope for this workflow**: running Shorebird release commands and uploading builds to the app stores. Per product-owner direction, that's done manually, personally, every time — this workflow prepares everything up to and including the GitHub Release, and stops there.

## 12. Technical debt

If architectural issues, technical debt, or worthwhile-but-unrelated improvements are discovered while working on a requested feature:
- Do not implement them as part of that feature's work, even if small.
- Document them in `docs/ai-workflow/BACKLOG.md` with enough context that someone picking it up later (possibly a different person or a fresh AI session with no memory of this conversation) understands what was found and why it matters, plus a recommendation.
- Continue focusing on the requested feature. Only expand scope if the product owner explicitly approves it.

This is not a new rule — it's what `docs/ai-workflow/RULES.md` already establishes and what Phase 1's work already did in practice (e.g., the merge-semantics fix, the orphaned-subdocument finding). This section just makes it explicit as a standing part of the feature workflow, not something specific to Phase 1.

## 13. Documentation

This document is permanent and is referenced from `docs/ai-workflow/RULES.md` as the authoritative Git/GitHub workflow for this project. Changes to this workflow itself should be proposed, discussed, and recorded as a decision in `docs/ai-workflow/DECISIONS_LOG.md`, the same as any other standing-rule change.
