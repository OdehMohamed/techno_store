# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Techno Store is a Flutter app (mobile/desktop/web targets scaffolded, but Android/iOS are the active platforms) backed entirely by Firebase (Firestore, Firebase Auth, Firebase Storage). It's a device retail + maintenance-tracking app: customers/admins manage products, categories, and a device maintenance workflow (intake, status tracking, images, pattern locks, etc).

## Common commands

```bash
flutter pub get                  # install dependencies
flutter run                      # run on a connected device/simulator
flutter analyze                  # static analysis (uses analysis_options.yaml, flutter_lints)
flutter test                     # run all tests
flutter test test/widget_test.dart   # run a single test file
flutter build apk / ipa          # release builds
```

There is no custom lint/format/test tooling beyond the Flutter SDK defaults — `flutter_lints` is the only linter configured, with no rules overridden in `analysis_options.yaml`.

Firebase config is managed via FlutterFire (`lib/firebase_options.dart`, `firebase.json`, platform `google-services.json` / `GoogleService-Info.plist`). Regenerate with `flutterfire configure` if Firebase project settings change — do not hand-edit the generated options file.

## Architecture

### Feature-first structure

Code lives under `lib/features/<feature_name>/`, each typically containing some subset of:
- `view/` — screens (`StatefulWidget`/`StatelessWidget` pages)
- `widgets/` — widgets private to that feature
- `cubit/` — `flutter_bloc` `Cubit` + a `part`-linked sealed `State` class (see below)
- `services/` — feature-specific Firestore/Storage calls
- `view_model/` — present in a few older features but largely dead/commented-out code left over from a pre-Cubit `ChangeNotifier` pattern; don't extend this pattern, use Cubit instead

Shared code lives under `lib/core/`:
- `core/model/` — data models shared across features (note: file naming is inconsistent, e.g. `productModel.dart`)
- `core/services/` — app-wide Firebase wrappers: `FirestoreServices`, `FirebaseStorageServices`, `AuthServices`, `CacheServices`, `LocationService`
- `core/route/` — `AppRoutes` (route name constants) and `AppRouter` (the single `onGenerateRoute` switch)
- `core/utils/` — `AppConstants`, `AppColors`, `AppTheme`, Firestore/Storage path builders, misc utilities
- `core/widgets/` — shared widgets (dialogs, buttons, app bar, drawer, footer, progress indicator)

### State management pattern

State management is `flutter_bloc` Cubits, one per feature, paired with a sealed state hierarchy declared in a separate file included via `part`/`part of`:

```dart
// xxx_cubit.dart
part 'xxx_state.dart';
class XxxCubit extends Cubit<XxxState> { ... }

// xxx_state.dart
part of 'xxx_cubit.dart';
sealed class XxxState {}
final class XxxInitial extends XxxState {}
final class XxxLoading extends XxxState {}
final class XxxSuccess extends XxxState { final ...; XxxSuccess({required ...}); }
final class XxxError extends XxxState { final String error; XxxError({required this.error}); }
```

Cubits are provided at the route level in `AppRouter` (via `BlocProvider`/`MultiBlocProvider`), not globally at the app root. Some routes pass already-created cubit instances forward through route `arguments` and re-provide them with `BlocProvider.value` (see `AppRoutes.maintenancePage`) so multiple screens can share the same cubit instance across a navigation stack.

### Firestore access

All Firestore reads/writes go through `FirestoreServices` (`lib/core/services/firestore_services.dart`), a singleton (`FirestoreServices.instance`) exposing generic helpers (`getDocument`, `getCollection`, `documentsStream`, `collectionsStream`, `setData`, `deleteData`) that take a path string and a `builder` function to map raw Firestore data to typed models. Feature-specific services (e.g. `NewDeviceServices`) call into these generics rather than touching `FirebaseFirestore.instance` directly.

Firestore document/collection paths are centralized in `lib/core/utils/firestore_api_path.dart` (`FirestoreApiPath`) as static path-builder methods — always add new paths there rather than inlining path strings in services.

### Navigation

Navigation is via named routes through `AppRouter.onGenerateRoute` (`lib/core/route/app_router.dart`), not `go_router` or similar. Route names live in `AppRoutes` (`lib/core/route/app_routes.dart`). Screens that need complex data (e.g. a device model, or shared cubits) receive it via `settings.arguments` cast to `Map<String, dynamic>` inside the router's switch statement.

### Localization

Uses `easy_localization` with `en`/`ar` locales, translation JSON in `assets/translations/{en,ar}.json`, initialized in `main.dart` and wrapped around `MyApp`.
