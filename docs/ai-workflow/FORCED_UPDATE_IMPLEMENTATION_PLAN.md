# FORCED_UPDATE_IMPLEMENTATION_PLAN.md

**Status:** Approved for implementation by the product owner on 2026-07-09. **No code has been modified. No Firestore rules have been deployed.**
**Branch:** `feature/forced-app-update`.
**Scope:** v1 implements forced update only. Soft update, maintenance mode, and feature flags are designed to be schema-ready but are explicitly **not implemented** in this pass — see "Deliberately deferred" below.

This plan sequences the work; it does not execute it. Implementation proceeds commit-by-commit per `CONTRIBUTING.md`, each commit presented for approval before it's created.

---

## 1. Problem

`in_app_update` (already a dependency) is wired into `SignIn.initState()` only, and is Android-only. It has three gaps: it never runs for already-authenticated returning users (they never mount `SignIn`), it forces an update on *every* new Play release with no way to say "only below version X," and it gives the product owner no lever over "when needed" from outside a Play Store rollout. iOS has no equivalent at all.

## 2. Data model

Single Firestore document — deliberately one document, not one per concern, so it can grow later (maintenance mode, feature flags) without new paths or new rules:

**Path:** `appConfig/global` (new `FirestoreApiPath.appConfig()` entry, following the existing centralized-path convention).

```
appConfig/global
{
  version: {
    android: {
      minRequiredVersion: "1.2.0",   // below this -> forced/blocking
      latestVersion: "1.3.0",        // below this (but >= min) -> soft nudge; schema-ready, NOT implemented in v1
      packageId: "com.mohamedodeh.technostore"
    },
    ios: {
      minRequiredVersion: "1.2.0",
      latestVersion: "1.3.0",
      appStoreId: null               // null until the App Store listing exists; feature degrades gracefully, see §6
    }
  }
  // Reserved for later, NOT implemented in v1 — added as new top-level keys
  // when picked up, no migration needed (Firestore documents are schemaless
  // per-field):
  // maintenance: { enabled: bool, message: ... }
  // featureFlags: { ... }
}
```

Two thresholds per platform (`minRequiredVersion` / `latestVersion`) so soft-update support can be added later purely as new UI/cubit-state logic reading the *same* document — no schema change when that's picked up.

## 3. Firestore rules

One addition to `firestore.rules`:

```
match /appConfig/global {
  allow read: if true;
  allow write: if false;
}
```

`allow read: if true` — this must be readable by signed-out users too (the sign-in screen itself must be forceable), and it contains no sensitive data, only operational version/store metadata. `allow write: if false` — no in-app admin UI in v1; edited manually via Firebase Console, the same operating model already used for `isActivated` (`ADR-004`).

## 4. Fail-open on read failure

**Approved explicitly by the product owner.** If fetching `appConfig/global` fails (offline, transient error, or the document doesn't exist yet), the app must **not** block — log the error, treat it as "no forced update," and let the user in. A config-read failure must never be able to brick the app for everyone. This is the one deliberate exception to "no silent failures" (`RULES.md`): the error is still logged, it just must never be used to block.

## 5. Version comparison

- Add `package_info_plus` — reads the installed app's actual version at runtime (both platforms).
- Add `pub_semver` (the Dart team's own semantic-version package) for comparison — no manual string splitting. `Version.parse(installed) < Version.parse(minRequired)`.
- `pubspec.yaml`'s `version:` field remains the source of truth for the installed version on both platforms (already true today via `flutter.versionName`).

## 6. `in_app_update`'s role

Kept, unchanged in behavior: an Android-only, non-blocking nudge for routine Play releases. It no longer has any say in whether the app is blocked — that decision belongs entirely to the new Firestore-driven gate, identical on both platforms.

## 7. Where the gate runs

New `AppUpdateCubit`, provided alongside `AuthCubit`/`HomeCubit`/`MaintenanceListCubit` in `app_router.dart`'s `MultiBlocProvider` for the `mainScreen` route — its Firestore fetch starts **concurrently** with `AuthCubit.checkAuth()`, not after it, so added latency is near-zero in the common case.

The *decision* to block is layered onto `MainScreen`'s existing `BlocBuilder<AuthCubit, AuthState>`, applied only once auth reaches a stable outcome (`AuthSuccess`, or the existing fallback that renders `SignIn`). `AuthRestoredPendingVerification` / `AuthNeedsProfileCompletion` are unaffected and render exactly as today. This deliberately keeps the existing startup/auth flow intact per the product owner's explicit instruction: nothing about `main.dart`, `Firebase.initializeApp`, or `checkAuth()` changes — the gate only intercepts what `MainScreen` would render next, after auth has already resolved.

If auth has resolved but the config fetch is still in flight, show a brief loading state (reusing the existing `MainProgressIndicator`) rather than flashing `SignIn`/`HomePage` and immediately replacing it.

## 8. Blocking UI

A dedicated full-screen page (not a dialog): no back-button dismissal, no barrier-tap dismissal, no cancel affordance. Title/body text via new `easy_localization` translation keys in `assets/translations/{en,ar}.json` (consistent with the rest of the app — not stored as free text in Firestore). A single action button opens the Play Store (Android) or App Store (iOS, only when `appStoreId` is non-null — otherwise the button is hidden with a fallback message, since a store link can't be built for a listing that doesn't exist yet) via the already-present `url_launcher`.

## 9. New files (planned)

- `lib/features/app_update/cubit/app_update_cubit.dart` + `app_update_state.dart` — states: `AppUpdateInitial`, `AppUpdateLoading`, `AppUpdateUpToDate`, `AppUpdateForceRequired`.
- `lib/features/app_update/services/app_update_service.dart` — fetches `appConfig/global` via `FirestoreServices`, compares versions via `pub_semver`.
- `lib/features/app_update/view/forced_update_page.dart`.
- `lib/core/model/app_config_model.dart` — parses the `appConfig/global` document.
- `lib/core/utils/firestore_api_path.dart` — add `appConfig()`.

## 10. Deliberately deferred (schema-ready, not built in v1)

- **Soft update** — `latestVersion` fields exist in the schema; no UI/cubit-state logic reads them yet.
- **Maintenance mode** — no `maintenance` key is written or read in v1.
- **Feature flags** — no `featureFlags` key is written or read in v1.

None of these require a schema change or migration when picked up later — they're new top-level keys on the same single document.
