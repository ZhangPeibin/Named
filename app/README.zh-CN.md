# Named

[English](README.md) | 中文

一个可复用的 Flutter 基础项目模板，用于快速启动新的 Android / iOS Flutter App。

## 定位

**一个 AI-native 的移动端（Android / iOS）团队级 App 地基**：用可执行检查把工程规范
固化下来，作为多个业务 App 的统一起点；内置通用平台能力，且各集成点可替换
（batteries-included but swappable）。

它明确「是什么」：

- **团队级基础设施，不是一次性脚手架**：架构边界由 `tool/architecture_check.dart`
  强制、`make check` 本地与 CI 同构、Agent 约束统一指向
  [工程规范](docs/engineering-standards.md)。这些投入只有在「多人 / 多 App / 长期
  维护」时才划算。
- **平台能力层，不是业务层**：提供每个 App 都要重造的通用轮子（Auth 骨架、网络栈、
  i18n、存储抽象等），业务逻辑留白（`todo_demo` 是可删示例）。
- **AI-native**：不仅有「不能做什么」的可执行拦截，还有「该怎么做」的建设层——
  [Agent Playbook](docs/agent/agent-playbook.md) + 脚手架生成器
  `dart run tool/new_feature.dart <name>`，让 agent / 新成员一次写对。

它明确「不是什么」：

- 不做全平台：仅 Android / iOS，`web` / `windows` / `linux` / `macos` 被规范禁止并由
  检查器拦截。
- 不绑业务 / 品牌：主题色、图标、Auth 均为中性占位。
- 不追大而全：可选能力（推送 / 分析 / 深链等）单列在
  [可选能力 Skills](docs/agent/optional-capability-skills.md)，按需再实现。

### 关键设计取舍（开放项）

- **模板路线**：通过「复制 + `setup_project.dart`」派生新 App，各 App 可自由魔改；
  代价是模板升级不会回流到已派生的 App。若未来 App 数量显著增长，可再评估把 `core/`
  抽为内部共享包。
- **codegen（待定）**：数据模型与 provider 当前为**手写实现（最小化）**，未引入
  `freezed` / `json_serializable` / `riverpod_generator`。codegen 作为**可选升级路径**
  保留，尚未拍板；一旦切换，需同步更新生成器模板与 Agent Playbook。

## 目标

- 保持基础工程可直接运行（多环境 + demo）。
- 提供清晰的目录结构，方便扩展路由、网络、状态管理和设计系统。
- 作为多个业务项目的起点，不绑定单一业务 / 品牌。
- 内置跨 App 通用平台能力：Toast、i18n、Auth 骨架、DeviceInfo、更新检查、WebView 壳等。

## 开箱能力

| 能力 | 说明 |
| --- | --- |
| 多环境配置 | `config/*.json` + `--dart-define-from-file` |
| 状态管理 | `flutter_riverpod` |
| 路由 | `go_router`（未登录 redirect → `/sign-in`） |
| 网络 | `dio` + logging / auth / refresh / deviceInfo / 全局错误 toast |
| 存储 | `KeyValueStorage` + `SecureStorage` |
| i18n | slang（en / zh）+ 语言持久化 |
| Toast | `AppToast` facade（底层 toastification） |
| Auth 骨架 | Dev Sign In 假 token；无产品登录 API |
| iOS Install Guard | 重装清 Keychain，避免「删 App 仍登录」 |
| DeviceInfo | 出站请求带 `deviceInfo` JSON header |
| App Update | 可选 / 强制更新 dialog 样例 |
| WebView | host allowlist（默认 `example.com`） |
| Demo | `todo_demo`：loading / empty / error / success |

## 目录结构

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
    auth/           # Dev Sign In 骨架
    app_update/     # 版本检查 + dialog
    home/
    not_found/
    settings/       # 语言设置
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

## 推荐阅读顺序

1. [README](README.md) / [中文 README](README.zh-CN.md)：项目能力、目录结构和常用命令总览。
2. [工程规范](docs/engineering-standards.md)：代码分层、Agent 约束、测试与质量门禁。
3. [Agent Playbook](docs/agent/agent-playbook.md)：常见任务（feature / API / 路由 / provider / i18n / 测试）的正确写法。
4. [模板使用](docs/template-usage.md)：如何从模板初始化新 App。
5. [环境与 Flavor](docs/flavors.md)：`dev` / `staging` / `prod` 与 `debug` / `profile` / `release`。
6. [发布流程](docs/release.md)：Release Preflight、签名和 APK / AAB / IPA 构建。
7. [工具链](docs/toolchain.md)：FVM、GitHub Actions 和 Git hooks。
8. [品牌资源](docs/branding.md)：应用图标和启动图替换。
9. [可观测性](docs/observability.md)：日志、脱敏、错误上报及第三方接入点。
10. [可选能力 Skills](docs/agent/optional-capability-skills.md)：后续按需实现的能力。

快速使用模板先看 `README -> 模板使用 -> 环境与 Flavor`；准备发布时再看
`发布流程`。

## 从模板创建新项目

1. 复制模板

   ```bash
   rsync -a --exclude-from=<template-dir>/.templateignore <template-dir>/ my_app/
   cd my_app
   ```

2. 执行重命名脚本

   ```bash
   dart run tool/setup_project.dart \
     --project-name my_app \
     --display-name "My App" \
     --android-package com.xxx.my_app \
     --ios-bundle-id com.xxx.my-app
   ```

   参数说明：

   - `project-name`：Dart package 名，写入 `pubspec.yaml`。
   - `display-name`：Android Launcher / iOS Home Screen 显示名。
   - `android-package`：Android `namespace`、`applicationId` 和 Kotlin package。
   - `ios-bundle-id`：可选；默认从 `android-package` 推导，并把 `_` 转成 `-`。

   脚本会同步修改 `pubspec.yaml`、`README.md`、`README.zh-CN.md`、`.vscode/launch.json`、`config/*.json`、Android / iOS 包名与显示名，以及 `lib/`、`test/`、`integration_test/` 下的模板包名。

   签名团队：打开 `ios/Runner.xcworkspace` → `Runner` → `Signing & Capabilities`。

3. 清理并拉依赖

   ```bash
   flutter clean
   flutter pub get
   dart run slang   # 若改过 i18n JSON
   ```

4. 安装 Git hooks

   ```bash
   brew install lefthook   # 若未安装
   make hooks
   ```

   安装后每次 `git commit` 自动跑格式、架构和静态分析检查，每次 `git push`
   自动跑完整的 `make check`。

5. 初始化 Git

   ```bash
   dart run tool/init_git.dart
   # 或：dart run tool/init_git.dart --commit --message "Initial commit"
   ```

6. 重新打开 IDE 项目根目录（不要只打开 `android/`）。

业务 App 常见下一步：换主题 / API、删 `todo_demo`、在 `features/` 加自己的业务。

## 运行

```bash
flutter pub get
make run-dev
# 或：
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

| 命令 | 作用 |
| --- | --- |
| `make get` | `flutter pub get` |
| `make bootstrap` | 从 `prod.example.json` 生成本地 `prod.json`（若不存在） |
| `make run-dev` | 运行 `devDebug`，支持调试和 Hot Reload |
| `make run-staging` | 运行 `stagingDebug`，连接测试环境 |
| `make run-prod` | 运行 `prodRelease`，连接生产环境 |
| `make build-apk-local` | 构建 `devRelease`，验证 Release 行为 |
| `make build-appbundle` / `build-apk` | 构建 Android `prodRelease` |
| `make build-ios` | 构建 iOS `Release-prod` IPA |
| `make preflight-prod` | 检查生产配置和模板标识 |
| `make preflight-android` / `preflight-ios` | 检查平台发布前置条件 |
| `make doctor` | 检查工具链、平台和必要配置 |
| `make new-feature name=xxx` | 脚手架生成分层 feature（见 [Agent Playbook](docs/agent/agent-playbook.md)） |
| `make check` | 运行格式、生成代码、架构、工具链、分析和测试检查 |
| `make fix` | 应用 Dart 自动修复、格式化并重新生成翻译代码 |
| `make analyze` / `make test` / `make clean` | 质量检查与清理 |

VS Code 启动配置：`Flutter Dev` / `Flutter Staging` / `Flutter Prod`。

代码分层、安全、测试及 Agent 协作要求统一定义在
[工程规范](docs/engineering-standards.md)。CI 与本地都通过 `make check` 执行同一组约束。

## 多环境配置

平台使用 `dev` / `staging` / `prod` Flavor，Dart 配置通过
`--dart-define-from-file` 注入。完整说明见 [多环境文档](docs/flavors.md)：

- `config/dev.json`
- `config/staging.json`
- `config/prod.example.json`（已提交）
- `config/prod.json`（本地，**已 gitignore**）

### 常用 define

| Key | 说明 | 示例 |
| --- | --- | --- |
| `APP_NAME` | Flutter 内显示名 | `Named` |
| `APP_ENV` | `dev` / `staging` / `prod` | `dev` |
| `API_BASE_URL` | Dio `baseUrl` | `https://jsonplaceholder.typicode.com` |
| `USE_MOCK_API` | demo / 部分能力走本地 mock | `true` |
| `REFRESH_TOKEN_PATH` | refresh 相对路径 | `/api/v1/auth/refresh` |
| `APP_VERSION_CHECK_PATH` | 版本检查相对路径 | `/api/v1/app/version/check` |
| `WEBVIEW_ALLOWED_HOSTS` | 逗号分隔 host allowlist | `example.com,www.example.com` |

`APP_NAME` 影响 `MaterialApp.title` 等；Launcher 显示名仍由平台配置 / `setup_project`
决定。`APP_ENV` 使用严格解析，并在启动时与原生 `appFlavor` 比较；缺失、拼写错误或
环境错配都会阻止业务启动。生产构建检查详见 [发布与签名](docs/release.md)。

## 依赖一览

| 包 | 用途 |
| --- | --- |
| `flutter_riverpod` | 状态管理 |
| `go_router` | 路由 |
| `dio` | 网络 |
| `logger` | 日志（经 `AppLogger`） |
| `shared_preferences` / `flutter_secure_storage` | KV / 安全存储 |
| `toastification` | Toast（经 `AppToast`） |
| `slang` / `slang_flutter` | i18n |
| `pinput` | OTP 输入 |
| `device_info_plus` / `package_info_plus` | DeviceInfo header |
| `url_launcher` | 打开应用商店等外链 |
| `webview_flutter` | 壳 WebView |
| `flutter_launcher_icons` / `flutter_native_splash` | 图标与原生启动页生成 |

## 状态管理

`lib/main.dart` 启动时创建 `AppConfig`、初始化 `SharedPreferences`（及 iOS Install Guard），并通过 `ProviderScope` 覆盖 `appConfigProvider` / `sharedPreferencesProvider`。页面用 `ref.watch(appConfigProvider)` 读配置。

## 设计系统

Token 在 `lib/app/theme/`，通用组件在 `lib/core/widgets/`。

### Theme tokens

| 文件 | 作用 |
| --- | --- |
| `app_colors.dart` | 品牌色与语义色（中性 placeholder，非业务品牌） |
| `app_text_styles.dart` | 字体层级 |
| `app_spacing.dart` | 间距 / 圆角 / `AppRadius` / `AppSize` |
| `app_theme.dart` | 组装 `ThemeData` |

### Common widgets

| 组件 | 作用 |
| --- | --- |
| `AppScaffold` | 页面标题、宽度、padding |
| `AppButton` | `primary` / `secondary` / `text` |
| `AppTextField` | 输入框 |
| `AppLoadingView` / `AppEmptyView` / `AppErrorView` | 通用状态 |
| `AppSkeleton` | shimmer 占位 |
| `AppListEmptyView` | 列表空状态（i18n） |
| `AppOtpField` / `SendCodeButton` | OTP + 发码倒计时 |
| `AppFilterBar` | 筛选 chip + sheet |
| `AppTextTabBar` / `AppTabPageTopBar` | Tab 相关 |
| `AppOptionTile` / `AppTwoLineListItem` | 列表行 |
| `AppTextDivider` / `AppBarCloseButton` / `AppRichText` / `AppIconBadge` | 其它通用 UI |
| `SplashWidget` | 启动页骨架（默认 Named） |

## 路由与 Auth

路由在 `lib/app/router/app_router.dart`（`appRouterProvider`）。未登录 redirect 到 `/sign-in`；`Dev Sign In` 写入假 token 后进首页。

| 路径 | 说明 |
| --- | --- |
| `/` | Home |
| `/sign-in` | 占位登录 |
| `/todo-demo` | API demo |
| `/settings/language` | 语言 |
| `/webview?url=` | WebView |

| 文件 | 作用 |
| --- | --- |
| `features/auth/presentation/sign_in_page.dart` | Dev Sign In |
| `features/auth/providers/auth_notifier.dart` | 登录态 |
| `core/network/auth_interceptor.dart` | `Authorization` header |
| `core/network/refresh_token_interceptor.dart` | 401 刷新重试（路径/解析可注入） |
| `core/storage/storage_keys.dart` | access / refresh / install id |

`USE_MOCK_API=true` 时 refresh 走本地 Dev client，不打真实 endpoint。

新增路由示例：

```dart
GoRoute(
  path: AppRoutePaths.profile,
  name: AppRouteNames.profile,
  builder: (context, state) => const ProfilePage(),
);

context.pushNamed(AppRouteNames.profile);
```

## 网络

`dioProvider` 使用 `AppConfig.apiBaseUrl`，并挂上：

1. `DeviceInfoInterceptor`
2. `AuthInterceptor`
3. `RefreshTokenInterceptor`
4. `ErrorInterceptor`（`ApiException` + 全局 toast 防抖）
5. `DioLoggingInterceptor`

可选 envelope：`unwrapApiData`（`lib/core/network/api_envelope.dart`）约定 `{ code, message, data }` 且 `code == 0` 成功；业务 envelope 不同时替换该 helper 即可。

### 全局错误 Toast

| 文件 | 作用 |
| --- | --- |
| `core/feedback/app_toast.dart` | 统一 facade（业务不要直接 import toastification） |
| `core/errors/app_error_localizer.dart` | transport 文案（走 slang `error.*`） |
| `core/network/error_interceptor.dart` | fault-state lock + 最小间隔 |

- 首次 network / timeout / server 失败 toast 一次并锁定同类故障。
- 任意成功请求后解锁，下一次故障可再 toast。

### `todo_demo` 与 `USE_MOCK_API`

| `USE_MOCK_API` | 行为 |
| --- | --- |
| `true`（dev 默认） | success / empty / error 走 `MockTodoApi` |
| `false` | success 走远程 `API_BASE_URL`；empty / error 仍用本地 mock |

手动验收：

```bash
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

1. Dev Sign In → 首页 → Todo Demo：Success / Empty / Error。
2. Error 应触发全局网络 toast；Retry 可重试。
3. `USE_MOCK_API=false` 且 baseUrl 为 JSONPlaceholder 时，Success 拉 `/todos/1`。

## 国际化（i18n）

[slang](https://pub.dev/packages/slang)：源文件 `lib/i18n/*.i18n.json`，生成 `strings*.g.dart`（不要手改）。语言持久化 key：`app.locale`。

```bash
dart run slang
```

```dart
Text(context.t.common.retry);
```

首页「Language」可切换 en/zh；杀进程重开保持选择。

## 启动：iOS Install Guard

`AppInstallGuard` 仅在 iOS 启动早期运行：SharedPreferences 无安装标记时清空 Secure Storage（Keychain 可能残留），再写入标记。Android 跳过，避免首帧前 Keystore I/O。

手动验收（iOS）：Dev Sign In → 删 App 重装 → 应回到登录页。

## DeviceInfo

出站请求（含 refresh）带 `deviceInfo` JSON header。字段约定见
[DeviceInfo Header](docs/device-info-header.md)。`install_id` 首次生成后写入 Secure
Storage，同一次安装内稳定；iOS 重装经 Install Guard 清空后会重新生成。

## App Update

首页「检查更新（可选 / 强制）」：`USE_MOCK_API=true` 时走 mock dialog；否则请求 `APP_VERSION_CHECK_PATH`。强制更新不可 dismiss；可选可点「稍后」。

## WebView

`/webview?url=` 使用 `webview_flutter`。Allowlist 来自 `WEBVIEW_ALLOWED_HOSTS` / `AppConfig.webViewAllowedHosts`（默认 `example.com`）。非白名单拒绝并提示。不要使用 `flutter_inappwebview`（本模板未引入）。

## 日志

经 `AppLogger` / `loggerProvider` 使用，业务不要直接 `Logger()`。全局异常经
`ErrorReporter` 转发，默认只写本地日志，不接入第三方平台。接入方式和脱敏规则见
[异常与可观测性](docs/observability.md)。

## 本地存储

| 抽象 | 默认实现 | 场景 |
| --- | --- | --- |
| `KeyValueStorage` | SharedPreferences | 语言、偏好等 |
| `SecureStorage` | flutter_secure_storage | token、凭证 |

Token 等敏感数据请用 `StorageKeys` + `SecureStorage`，不要写死 key 散落各处。

## 质量检查

```bash
flutter analyze
flutter test
```

GitHub Actions 会执行格式、生成代码、Doctor、Analyze、测试和 Android debug 构建；
仓库未启用 Actions 时不影响本地开发。

## 工程文档

- [Agent Playbook（常见任务正确写法）](docs/agent/agent-playbook.md)
- [模板创建与安全复制](docs/template-usage.md)
- [多环境与 Flavor](docs/flavors.md)
- [发布与签名](docs/release.md)
- [图标与启动页](docs/branding.md)
- [工具链](docs/toolchain.md)
- [可选能力 Skill 规划](docs/agent/optional-capability-skills.md)
