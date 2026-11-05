# Named

English | [中文](README.zh-CN.md)

A reusable Flutter foundation for kicking off new Android / iOS apps.

## Positioning

**An AI-native, team-level app foundation for Android / iOS**: engineering
standards are enforced by executable checks; the repo is a shared starting
point for multiple product apps; common platform capabilities are included and
each integration point is swappable (batteries-included but swappable).

### What this is

- **Team infrastructure, not a one-off scaffold**: architecture boundaries are
  enforced by `tool/architecture_check.dart`, `make check` matches CI locally,
  and agent guidance points at
  [engineering standards](docs/engineering-standards.md). That investment pays
  off when you have multiple people, multiple apps, and long-lived maintenance.
- **Platform layer, not product layer**: common building blocks every app would
  otherwise rebuild (auth skeleton, networking, i18n, storage abstractions,
  etc.). Product logic is left blank (`todo_demo` is a removable sample).
- **AI-native**: not only executable “don’t do this” guards, but also a
  constructive “do it this way” layer —
  [Agent Playbook](docs/agent/agent-playbook.md) plus
  `dart run tool/new_feature.dart <name>` — so agents and new teammates get the
  shape right on the first try.

### What this is not

- Not multi-platform: Android / iOS only. `web` / `windows` / `linux` / `macos`
  are forbidden by policy and rejected by the checker.
- Not tied to a product or brand: theme colors, icons, and auth are neutral
  placeholders.
- Not a kitchen sink: optional capabilities (push, analytics, deep links, etc.)
  live in
  [optional capability skills](docs/agent/optional-capability-skills.md) and are
  added on demand.

### Open design trade-offs

- **Template strategy**: new apps are derived via copy + `setup_project.dart`
  and may diverge freely. The cost is that template upgrades do not flow back
  into already-derived apps. If the number of apps grows meaningfully, consider
  extracting `core/` into an internal shared package.
- **Codegen (undecided)**: data models and providers are currently **hand-written
  (minimal)**. `freezed` / `json_serializable` / `riverpod_generator` are not
  included. Codegen remains an optional upgrade path and is not decided yet;
  switching would require updating generator templates and the Agent Playbook
  together.

## Goals

- Keep the base project runnable out of the box (multi-environment + demo).
- Provide a clear directory layout for routing, networking, state management,
  and the design system.
- Serve as a starting point for multiple product apps without binding to one
  business or brand.
- Ship cross-app platform capabilities: Toast, i18n, auth skeleton, DeviceInfo,
  update checks, WebView shell, and more.

## Out of the box

| Capability | Notes |
| --- | --- |
| Multi-environment config | `config/*.json` + `--dart-define-from-file` |
| State management | `flutter_riverpod` |
| Routing | `go_router` (unauthenticated redirect → `/sign-in`) |
| Networking | `dio` + logging / auth / refresh / deviceInfo / global error toast |
| Storage | `KeyValueStorage` + `SecureStorage` |
| i18n | slang (en / zh) + locale persistence |
| Toast | `AppToast` facade (toastification underneath) |
| Auth skeleton | Dev Sign In with a fake token; no product login API |
| iOS Install Guard | Clears Keychain on reinstall so “delete app, still signed in” does not happen |
| DeviceInfo | Outbound requests carry a `deviceInfo` JSON header |
| App Update | Optional / forced update dialog sample |
| WebView | Host allowlist (default `example.com`) |
| Demo | `todo_demo`: loading / empty / error / success |

## Directory layout

```text
lib/
  app/
    app.dart
    router/app_router.dart
    theme/
  core/
    config/app_config.dart
    device/device_info_service.dart
    errors/app_error_localizer.dart
    feedback/app_toast.dart
    i18n/app_locale_controller.dart
    logging/
    network/
      api_envelope.dart
      api_exception.dart
      auth_interceptor.dart
      device_info_interceptor.dart
      dio_logging_interceptor.dart
      error_interceptor.dart
      refresh_token_interceptor.dart
    providers/
    startup/
      app_install_guard.dart
      startup_logger.dart
    storage/
    widgets/
  features/
    auth/           # Dev Sign In skeleton
    app_update/     # version check + dialog
    home/
    not_found/
    settings/       # language settings
    todo_demo/      # API demo
    webview/        # allowlist WebView
  i18n/
    en.i18n.json
    zh.i18n.json
  main.dart
docs/
  agent/
    agent-playbook.md
    optional-capability-skills.md
  branding.md
  device-info-header.md
  engineering-standards.md
  flavors.md
  observability.md
  release.md
  template-usage.md
  toolchain.md
config/
  dev.json
  staging.json
  prod.example.json
tool/
  setup_project.dart
  new_feature.dart
  init_git.dart
```

## Suggested reading order

1. [README](README.md) / [中文 README](README.zh-CN.md): capabilities, layout, and common commands.
2. [Engineering standards](docs/engineering-standards.md): layering, agent constraints, tests, and quality gates.
3. [Agent Playbook](docs/agent/agent-playbook.md): correct shapes for common tasks (feature / API / route / provider / i18n / test).
4. [Template usage](docs/template-usage.md): how to initialize a new app from the template.
5. [Flavors](docs/flavors.md): `dev` / `staging` / `prod` vs `debug` / `profile` / `release`.
6. [Release](docs/release.md): release preflight, signing, and APK / AAB / IPA builds.
7. [Toolchain](docs/toolchain.md): FVM, GitHub Actions, and Git hooks.
8. [Branding](docs/branding.md): replacing app icons and splash assets.
9. [Observability](docs/observability.md): logging, redaction, error reporting, and third-party hooks.
10. [Optional capability skills](docs/agent/optional-capability-skills.md): capabilities to add later on demand.

For a quick start, read `README -> Template usage -> Flavors`. Read `Release`
when you are ready to ship.

## Create a new project from the template

1. Copy the template

   ```bash
   rsync -a --exclude-from=<template-dir>/.templateignore <template-dir>/ my_app/
   cd my_app
   ```

2. Run the rename script

   ```bash
   dart run tool/setup_project.dart \
     --project-name my_app \
     --display-name "My App" \
     --android-package com.xxx.my_app \
     --ios-bundle-id com.xxx.my-app
   ```

   Parameters:

   - `project-name`: Dart package name written to `pubspec.yaml`.
   - `display-name`: Android launcher / iOS Home Screen display name.
   - `android-package`: Android `namespace`, `applicationId`, and Kotlin package.
   - `ios-bundle-id`: optional; defaults from `android-package` with `_` → `-`.

   The script updates `pubspec.yaml`, `README.md`, `README.zh-CN.md`,
   `.vscode/launch.json`, `config/*.json`, Android / iOS package and display
   names, and the template package name under `lib/`, `test/`, and
   `integration_test/`.

   Signing team: open `ios/Runner.xcworkspace` → `Runner` →
   `Signing & Capabilities`.

3. Clean and fetch dependencies

   ```bash
   flutter clean
   flutter pub get
   dart run slang   # if you changed i18n JSON
   ```

4. Install Git hooks

   ```bash
   brew install lefthook   # if needed
   make hooks
   ```

   After install, every `git commit` runs format / architecture / analyze
   checks, and every `git push` runs the full `make check`.

5. Initialize Git

   ```bash
   dart run tool/init_git.dart
   # or: dart run tool/init_git.dart --commit --message "Initial commit"
   ```

6. Reopen the IDE at the project root (do not open only `android/`).

Typical next steps for a product app: swap theme / API, delete `todo_demo`, and
add your own features under `features/`.

## Run

```bash
flutter pub get
make run-dev
# or:
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

| Command | Purpose |
| --- | --- |
| `make get` | `flutter pub get` |
| `make bootstrap` | Create local `prod.json` from `prod.example.json` if missing |
| `make run-dev` | Run `devDebug` with Hot Reload |
| `make run-staging` | Run `stagingDebug` against staging |
| `make run-prod` | Run `prodRelease` against production |
| `make build-apk-local` | Build `devRelease` to verify release behavior |
| `make build-appbundle` / `build-apk` | Build Android `prodRelease` |
| `make build-ios` | Build iOS `Release-prod` IPA |
| `make preflight-prod` | Check production config and template markers |
| `make preflight-android` / `preflight-ios` | Check platform release prerequisites |
| `make doctor` | Check toolchain, platforms, and required config |
| `make new-feature name=xxx` | Scaffold a layered feature (see [Agent Playbook](docs/agent/agent-playbook.md)) |
| `make check` | Format, generated code, architecture, toolchain, analyze, and tests |
| `make fix` | Apply Dart fixes, format, and regenerate translations |
| `make analyze` / `make test` / `make clean` | Quality checks and cleanup |

VS Code launch configs: `Flutter Dev` / `Flutter Staging` / `Flutter Prod`.

Layering, security, testing, and agent collaboration rules are defined in
[engineering standards](docs/engineering-standards.md). CI and local both run
the same `make check` gate.

## Multi-environment config

Native flavors are `dev` / `staging` / `prod`. Dart config is injected with
`--dart-define-from-file`. Full details:
[flavors](docs/flavors.md).

- `config/dev.json`
- `config/staging.json`
- `config/prod.example.json` (committed)
- `config/prod.json` (local, **gitignored**)

### Common defines

| Key | Description | Example |
| --- | --- | --- |
| `APP_NAME` | In-app Flutter display name | `Named` |
| `APP_ENV` | `dev` / `staging` / `prod` | `dev` |
| `API_BASE_URL` | Dio `baseUrl` | `https://jsonplaceholder.typicode.com` |
| `USE_MOCK_API` | Demo / some capabilities use local mocks | `true` |
| `REFRESH_TOKEN_PATH` | Refresh relative path | `/api/v1/auth/refresh` |
| `APP_VERSION_CHECK_PATH` | Version-check relative path | `/api/v1/app/version/check` |
| `WEBVIEW_ALLOWED_HOSTS` | Comma-separated host allowlist | `example.com,www.example.com` |

`APP_NAME` affects things like `MaterialApp.title`; the launcher display name
still comes from platform config / `setup_project`. `APP_ENV` is strictly
parsed and compared with native `appFlavor` at startup; missing values, typos,
or mismatches block the app from starting. Production build checks are covered
in [release](docs/release.md).

## Dependencies

| Package | Purpose |
| --- | --- |
| `flutter_riverpod` | State management |
| `go_router` | Routing |
| `dio` | Networking |
| `logger` | Logging (via `AppLogger`) |
| `shared_preferences` / `flutter_secure_storage` | KV / secure storage |
| `toastification` | Toast (via `AppToast`) |
| `slang` / `slang_flutter` | i18n |
| `pinput` | OTP input |
| `device_info_plus` / `package_info_plus` | DeviceInfo header |
| `url_launcher` | Open store / external links |
| `webview_flutter` | Shell WebView |
| `flutter_launcher_icons` / `flutter_native_splash` | Icon and splash generation |

## State management

On startup, `lib/main.dart` builds `AppConfig`, initializes `SharedPreferences`
(and the iOS Install Guard), then overrides `appConfigProvider` /
`sharedPreferencesProvider` through `ProviderScope`. Pages read config with
`ref.watch(appConfigProvider)`.

## Design system

Tokens live in `lib/app/theme/`. Shared widgets live in `lib/core/widgets/`.

### Theme tokens

| File | Role |
| --- | --- |
| `app_colors.dart` | Brand and semantic colors (neutral placeholders, not a product brand) |
| `app_text_styles.dart` | Type scale |
| `app_spacing.dart` | Spacing / radius / `AppRadius` / `AppSize` |
| `app_theme.dart` | Assembles `ThemeData` |

### Common widgets

| Widget | Role |
| --- | --- |
| `AppScaffold` | Page title, width, padding |
| `AppButton` | `primary` / `secondary` / `text` |
| `AppTextField` | Text field |
| `AppLoadingView` / `AppEmptyView` / `AppErrorView` | Shared states |
| `AppSkeleton` | Shimmer placeholder |
| `AppListEmptyView` | List empty state (i18n) |
| `AppOtpField` / `SendCodeButton` | OTP + send-code countdown |
| `AppFilterBar` | Filter chips + sheet |
| `AppTextTabBar` / `AppTabPageTopBar` | Tab UI |
| `AppOptionTile` / `AppTwoLineListItem` | List rows |
| `AppTextDivider` / `AppBarCloseButton` / `AppRichText` / `AppIconBadge` | Other shared UI |
| `SplashWidget` | Splash skeleton (defaults to Named) |

## Routing and auth

Routes live in `lib/app/router/app_router.dart` (`appRouterProvider`).
Unauthenticated users redirect to `/sign-in`. Dev Sign In writes a fake token
and continues to home.

| Path | Notes |
| --- | --- |
| `/` | Home |
| `/sign-in` | Placeholder sign-in |
| `/todo-demo` | API demo |
| `/settings/language` | Language |
| `/webview?url=` | WebView |

| File | Role |
| --- | --- |
| `features/auth/presentation/sign_in_page.dart` | Dev Sign In |
| `features/auth/providers/auth_notifier.dart` | Auth state |
| `core/network/auth_interceptor.dart` | `Authorization` header |
| `core/network/refresh_token_interceptor.dart` | 401 refresh/retry (path/parsing injectable) |
| `core/storage/storage_keys.dart` | Access / refresh / install id |

When `USE_MOCK_API=true`, refresh uses the local Dev client and does not hit a
real endpoint.

Adding a route:

```dart
GoRoute(
  path: AppRoutePaths.profile,
  name: AppRouteNames.profile,
  builder: (context, state) => const ProfilePage(),
);

context.pushNamed(AppRouteNames.profile);
```

## Networking

`dioProvider` uses `AppConfig.apiBaseUrl` and mounts:

1. `DeviceInfoInterceptor`
2. `AuthInterceptor`
3. `RefreshTokenInterceptor`
4. `ErrorInterceptor` (`ApiException` + debounced global toast)
5. `DioLoggingInterceptor`

Optional envelope helper: `unwrapApiData` in
`lib/core/network/api_envelope.dart` expects `{ code, message, data }` with
`code == 0` for success. Replace the helper if your product envelope differs.

### Global error toast

| File | Role |
| --- | --- |
| `core/feedback/app_toast.dart` | Shared facade (features must not import toastification directly) |
| `core/errors/app_error_localizer.dart` | Transport copy (slang `error.*`) |
| `core/network/error_interceptor.dart` | Fault-state lock + minimum interval |

- The first network / timeout / server failure toasts once and locks that fault
  class.
- Any successful request unlocks it so the next failure can toast again.

### `todo_demo` and `USE_MOCK_API`

| `USE_MOCK_API` | Behavior |
| --- | --- |
| `true` (dev default) | success / empty / error use `MockTodoApi` |
| `false` | success hits remote `API_BASE_URL`; empty / error stay on local mocks |

Manual check:

```bash
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

1. Dev Sign In → Home → Todo Demo: Success / Empty / Error.
2. Error should trigger the global network toast; Retry should retry.
3. With `USE_MOCK_API=false` and a JSONPlaceholder base URL, Success fetches
   `/todos/1`.

## Internationalization (i18n)

[slang](https://pub.dev/packages/slang): sources in `lib/i18n/*.i18n.json`,
generated `strings*.g.dart` (do not edit by hand). Locale persistence key:
`app.locale`.

```bash
dart run slang
```

```dart
Text(context.t.common.retry);
```

Home → Language switches en/zh; the choice survives process kill/relaunch.

## Startup: iOS Install Guard

`AppInstallGuard` runs early on iOS only: if SharedPreferences has no install
marker, it clears Secure Storage (Keychain may retain values) and then writes
the marker. Android skips this to avoid Keystore I/O before the first frame.

Manual check (iOS): Dev Sign In → delete the app → reinstall → you should land
on the sign-in page.

## DeviceInfo

Outbound requests (including refresh) carry a `deviceInfo` JSON header. Field
contract:
[DeviceInfo Header](docs/device-info-header.md).
`install_id` is generated once and stored in Secure Storage for the lifetime of
an install; after an iOS reinstall, Install Guard clears it and a new id is
created.

## App Update

Home → “Check for update (optional / forced)”: with `USE_MOCK_API=true` this
uses a mock dialog; otherwise it requests `APP_VERSION_CHECK_PATH`. Forced
updates cannot be dismissed; optional updates offer “Later”.

## WebView

`/webview?url=` uses `webview_flutter`. The allowlist comes from
`WEBVIEW_ALLOWED_HOSTS` / `AppConfig.webViewAllowedHosts` (default
`example.com`). Non-allowlisted hosts are rejected with a message. Do not use
`flutter_inappwebview` — this template does not include it.

## Logging

Use `AppLogger` / `loggerProvider`. Features must not construct `Logger()`
directly. Global exceptions go through `ErrorReporter`; the default sinks to
local logs only, with no third-party platform wired in. Integration and
redaction rules:
[observability](docs/observability.md).

## Local storage

| Abstraction | Default impl | Use for |
| --- | --- | --- |
| `KeyValueStorage` | SharedPreferences | Locale, preferences, etc. |
| `SecureStorage` | flutter_secure_storage | Tokens, credentials |

Keep sensitive values behind `StorageKeys` + `SecureStorage`; do not scatter
hard-coded keys.

## Quality checks

```bash
flutter analyze
flutter test
```

GitHub Actions runs format, generated-code, Doctor, Analyze, tests, and an
Android debug build. Local development still works if Actions is not enabled.

## Docs

- [Agent Playbook](docs/agent/agent-playbook.md)
- [Template usage and safe copy](docs/template-usage.md)
- [Flavors](docs/flavors.md)
- [Release and signing](docs/release.md)
- [Icons and splash](docs/branding.md)
- [Toolchain](docs/toolchain.md)
- [Optional capability skill plan](docs/agent/optional-capability-skills.md)
