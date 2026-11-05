# Agent Playbook

This is the "how to do it right" companion to
[engineering-standards.md](../engineering-standards.md).

- `engineering-standards.md` and `tool/architecture_check.dart` define what is
  **not** allowed and reject the wrong shape.
- This playbook shows the **correct shape** for the recurring tasks, so agents
  (and new humans) produce compliant code on the first try instead of learning
  the conventions by hitting the checker.

Always finish with `make check`. Never edit `*.g.dart` files by hand.

## Recipe: add a feature

Prefer the generator — it produces a compile-ready, format-clean, layered
skeleton that already passes `tool/architecture_check.dart`:

```sh
dart run tool/new_feature.dart my_feature          # full vertical slice
dart run tool/new_feature.dart my_feature --ui-only # presentation only
# or: make new-feature name=my_feature
```

The full slice creates:

```text
lib/features/my_feature/
  domain/my_feature.dart                       # entity, framework-free
  data/dto/my_feature_dto.dart                 # fromJson + toDomain()
  data/api/my_feature_api.dart                 # Dio call + error boundary
  data/repositories/my_feature_repository.dart # DTO -> domain
  providers/my_feature_providers.dart          # api + repository + FutureProvider
  presentation/my_feature_page.dart            # ConsumerWidget + AppAsyncView
```

Then:

1. Wire a route (see "add a route" — the generator prints the exact snippet).
2. Replace the placeholder `id` field with real fields in `domain/` and map
   them in the DTO `fromJson`.
3. Move user-visible strings into `lib/i18n/*.i18n.json` and run `make gen`.
4. Fill in the `TODO(my_feature)` markers, then run `make check`.

### Layer rules (enforced)

- `domain/`: no Flutter / Riverpod / Dio; no imports from `data`,
  `presentation`, or `providers`.
- `data/`: may use Dio and depend on `domain`; must not import `presentation`.
- `providers/`: dependency wiring and state ownership.
- `presentation/`: no direct `dio` / `shared_preferences` /
  `flutter_secure_storage`; reach infrastructure through providers.

## Recipe: add an API client + repository + DTO

The generator already emits this. When adding one by hand, follow the same
shape. The key rule is the **error boundary**: convert transport failures into
`ApiException` inside `data/`, so `DioException` never leaks upward.

```dart
// data/api/<feature>_api.dart
Future<FooDto> fetchFoo() async {
  try {
    final response = await _dio.get<Map<String, dynamic>>('/foo');
    final data = response.data;
    if (data == null) {
      throw const ApiException(
        type: ApiExceptionType.badResponse,
        message: 'Foo response was empty',
      );
    }
    return FooDto.fromJson(data);
  } on DioException catch (error) {
    final apiException = error.error;
    if (apiException is ApiException) {
      throw apiException;
    }
    throw ApiException.fromDioException(error);
  }
}
```

- Parsing lives in the DTO (`fromJson`), not in the domain entity.
- The repository maps DTO → domain (`toDomain()`), so `providers` and
  `presentation` only ever see domain types.
- If the backend uses the `{ code, message, data }` envelope, unwrap with
  `unwrapApiData` from `lib/core/network/api_envelope.dart`.

## Recipe: add a route

Edit `lib/app/router/app_router.dart`:

```dart
// 1. AppRoutePaths
static const profile = '/profile';
// 2. AppRouteNames
static const profile = 'profile';
// 3. routes: [...]
GoRoute(
  path: AppRoutePaths.profile,
  name: AppRouteNames.profile,
  builder: (context, state) => const ProfilePage(),
),
```

Navigate with the name, never a hardcoded string:

```dart
context.pushNamed(AppRouteNames.profile);
```

Routes are protected by default: anything not in `_publicRoutePaths` redirects
unauthenticated users to `/sign-in`. Add a path there only if it must be public.

## Recipe: add a provider

- Wiring/singletons: `Provider<T>((ref) => ...)`.
- Async reads: `FutureProvider.autoDispose<T>((ref) => ...)`.
- Mutable UI state: a `Notifier<T>` exposed via
  `NotifierProvider<MyNotifier, T>(MyNotifier.new)`.

Read config, Dio, storage, and logging through the existing `core/providers/*`
(`appConfigProvider`, `dioProvider`, `loggerProvider`, etc.). Do not construct
these dependencies inline or create service locators / global mutable state.

## Recipe: add a translation key

1. Add the same key to **every** locale file: `lib/i18n/en.i18n.json` and
   `lib/i18n/zh.i18n.json`.
2. Run `make gen` (regenerates `strings.g.dart`; never edit it by hand).
3. Use it: `context.t.common.retry` / `context.t.myFeature.title`.

All user-visible text must come from Slang unless it is a platform-owned value
or a non-user-facing diagnostic.

## Recipe: add a shared widget

Reusable UI belongs in `lib/core/widgets/` and must reuse theme tokens from
`lib/app/theme/` (`AppColors`, `AppSpacing`, `AppTextStyles`) instead of
hardcoded colors/sizes. Check `core/widgets/` first — prefer `AppScaffold`,
`AppButton`, `AppAsyncView`, `AppEmptyView`, etc. before adding a new control.

## Recipe: write a test

- Unit-test domain rules, DTO parsing, repositories, and providers.
- Widget-test meaningful UI states (loading / empty / error / success).
- Tests must be deterministic: no real network, credentials, wall-clock timing,
  or execution-order dependencies.
- Every reproducible bug fix needs a regression test.

Run `make test`, or `make check` for the full non-mutating suite.

## Before you finish

```sh
make fix    # apply Dart fixes, format, regenerate translations
make check  # format, generated-code, architecture, doctor, analyze, test
```

Report any check that could not run. Do not weaken a checker, lint, or test to
make new code pass.
