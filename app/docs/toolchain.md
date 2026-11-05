# 工具链

模板推荐 Flutter 3.41.9，对应版本记录在 `.fvmrc`，GitHub Actions 使用同一版本。

推荐使用 FVM：

```bash
fvm install
fvm flutter pub get
```

FVM 不是强制依赖，未安装时可以直接使用 `flutter`。运行 `make doctor` 会提示当前
Flutter 版本是否与模板一致。

基础要求：

- Flutter 3.41.9 / Dart 3.11.x
- Java 17
- Android minSdk 24，Android SDK 与 Flutter 当前 stable 要求一致
- iOS 13.0，使用当前 Flutter stable 支持的 Xcode 和 CocoaPods

Dependabot 每周检查 pub、Gradle 和 GitHub Actions 依赖。依赖升级仍需通过 Analyze、
Test 和 Android debug 构建后才能合并。
