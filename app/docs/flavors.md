# 多环境与 Flavor

模板只支持 Android 和 iOS，并提供 `dev`、`staging`、`prod` 三套环境。

| 环境 | Android applicationId | iOS Bundle ID | 显示名 |
| --- | --- | --- | --- |
| dev | `<base>.dev` | `<base>.dev` | `<App> Dev` |
| staging | `<base>.staging` | `<base>.staging` | `<App> Staging` |
| prod | `<base>` | `<base>` | `<App>` |

## 本地运行

| 命令 | Android Variant | iOS Configuration | 用途 |
| --- | --- | --- | --- |
| `make run-dev` | `devDebug` | `Debug-dev` | 日常开发、断点和 Hot Reload |
| `make run-staging` | `stagingDebug` | `Debug-staging` | 调试测试环境 |
| `make run-prod` | `prodRelease` | `Release-prod` | 在设备上运行生产版本 |
| `make build-apk-local` | `devRelease` | - | 用 dev 配置验证 Release 行为 |
| `make build-apk` | `prodRelease` | - | 构建正式 APK |
| `make build-appbundle` | `prodRelease` | - | 构建 Google Play AAB |
| `make build-ios` | - | `Release-prod` | 构建正式 IPA |

`flutter run` 未指定构建模式时默认使用 Debug，因此 `make run-dev` 是
`devDebug`，不是 `devRelease`。

等价的 Flutter 命令必须同时指定 Flavor 和 Dart 配置：

```bash
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

需要性能分析时手工使用 Profile 模式：

```bash
flutter run \
  --flavor dev \
  --profile \
  --dart-define-from-file=config/dev.json
```

这对应 Android `devProfile` 和 iOS `Profile-dev`。Flavor 决定使用哪个环境，
Debug/Profile/Release 决定如何编译，两者是独立维度。

## Flavor 与 Dart 配置校验

Flutter 会通过官方 `appFlavor` 常量暴露 `--flavor` 的值。应用在初始化存储、认证和
网络之前比较 `appFlavor` 与 `APP_ENV`，只允许以下组合：

```text
dev + APP_ENV=dev
staging + APP_ENV=staging
prod + APP_ENV=prod
```

未指定 Flavor、`APP_ENV` 拼写错误或两者不一致都会阻止业务启动。Debug/Profile
直接抛出详细错误；Release 只显示通用配置错误页面并通过 `ErrorReporter` 上报，不会
泄露 API 地址等内部配置。

VS Code 已提供三套对应启动配置。

## Android

Flavor 定义在 `android/app/build.gradle.kts`。生产环境不添加后缀，dev 和
staging 使用 `applicationIdSuffix`，因此三个 App 可以同时安装。

## iOS

共享 Scheme 为 `dev`、`staging`、`prod`，分别使用对应的 Debug、Profile、
Release Build Configuration。首次修改 Flavor 结构后执行 `pod install`。

在 Xcode 中始终打开 `ios/Runner.xcworkspace`，不要打开 `.xcodeproj`。

## 第三方配置

Firebase、推送、Deep Link 等平台配置应按环境分别维护。真实生产配置和证书不得
提交到模板。业务项目接入时，应将本地文件加入 `.gitignore`，由 CI Secret 在构建时
写入。
