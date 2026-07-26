# Firestore rules tests

Permanent, reproducible executable tests for `../../firestore.rules`, established during `ADR-007` Phase 1 so later phases (Phase 6's rule tightening, and any future rule change) can regress against this suite instead of writing a one-off scratchpad script each time. Not part of the Flutter app or the `functions/` Cloud Functions project — a standalone Node project scoped to this one concern.

## Prerequisites

- Node 22 (matches `functions/package.json`'s own pinned engine).
- **Java 21 or later on `PATH`.** `firebase-tools` no longer supports older JDKs for the Firestore emulator. This is *not* hardcoded into the test script, since the correct install location differs by machine (e.g. Homebrew's `/opt/homebrew` on Apple Silicon vs. `/usr/local` on Intel) — confirm before running:

  ```bash
  java -version   # must report 21 or higher
  ```

  If it doesn't, install a JDK 21+ (e.g. `brew install openjdk@21`) and prepend its `bin` directory to `PATH` for this shell session before running the tests.

## Running

```bash
cd test/firestore-rules
npm install
npm test
```

`npm test` starts a local Firestore emulator (via a pinned `firebase-tools@15.24.0`, not the global `firebase` CLI, which has a known-broken installation in this environment), runs every `*.test.js` file against it with Node's built-in test runner, and tears the emulator down afterward — no production or shared infrastructure touched. `--project demo-technostore-rules-test` is a fake, local-only project ID; nothing here can reach a real Firebase project.

`--test-concurrency=1` is required, not optional. Node's test runner otherwise executes separate test files concurrently, and every file's `beforeEach` calls `clearFirestore()` against the same shared emulator project — confirmed empirically (not assumed) that running files in parallel produces real, intermittent failures where one file's fixtures get wiped mid-test by another file's `clearFirestore()`. If a future contributor adds more test files and wants them to run in parallel for speed, each would need its own isolated `projectId` in `helpers.js` instead of removing this flag.

## Scope

Covers `devices/{deviceId}` and `maintenanceDevices/{deviceId}/estimates/{estimateId}` (both new in `ADR-007` Phase 1), plus a small regression subset of the pre-existing `maintenanceDevices/{deviceId}` rules to confirm they're undisturbed. Does not re-run the full historical `BACKLOG` #0a matrix. App-layer-only invariants (the no-new-Estimate-while-unresolved rule, and Estimate qualification) are explicitly out of scope here — they aren't enforced by `firestore.rules` and need their own coverage once the app-layer code implementing them exists.

No CI wiring in this phase — run manually until that's worth doing.
