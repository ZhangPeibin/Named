# 发布与签名

## Release Preflight

所有生产运行和构建命令都会先执行 `tool/release_preflight.dart`。检查失败时构建不会
开始，并会一次输出全部问题。

```bash
make preflight-prod     # 生产配置与模板标识
make preflight-android  # 追加 Android 权限、签名和 Keystore 检查
make preflight-ios      # 追加 iOS Scheme、Configuration 和 Team 检查
```

生产配置必须显式提供：

```text
APP_NAME
APP_ENV=prod
API_BASE_URL=https://...
USE_MOCK_API=false
REFRESH_TOKEN_PATH
APP_VERSION_CHECK_PATH
WEBVIEW_ALLOWED_HOSTS
```

Preflight 会拒绝 HTTP、localhost、`example.com`、Mock API、模板品牌和模板包名。
`dart-define` 会进入客户端二进制，不能存放任何 Secret。

## Android

正式 APK/AAB 构建要求以下环境变量全部存在：

```text
ANDROID_KEYSTORE_PATH
ANDROID_KEYSTORE_PASS
ANDROID_KEY_ALIAS
ANDROID_KEY_PASS
```

构建命令：

```bash
make build-appbundle  # prodRelease，Google Play 推荐
make build-apk        # prodRelease，正式 APK
```

缺少签名配置时，prod Release 会立即失败。仅用于本地验证的 debug 签名 Release：

```bash
make build-apk-local  # devRelease，不连接生产环境
```

Keystore、`key.properties` 和密码不得提交到 Git。Play Store 发布优先使用 AAB。

## iOS

```bash
make build-ios  # prod Scheme + Release-prod
```

业务项目需要在 Xcode 配置 Development Team、证书和 Provisioning Profile。CI 应从
Secret 安装证书并生成本地 `ios/ExportOptions.plist`，该文件已被忽略。

CI 需要严格检查 ExportOptions 时使用：

```bash
dart run tool/release_preflight.dart \
  --config=config/prod.json \
  --platform=ios \
  --require-ios-export-options
```

## 混淆符号

正式构建启用 `--obfuscate`，符号保存到 `build/symbols/<version>/`。该目录不会进入
Git，CI 必须将它作为与安装包同生命周期的 Artifact 保存，否则线上堆栈无法还原。
