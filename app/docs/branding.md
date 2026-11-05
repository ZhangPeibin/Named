# 图标与启动页

品牌源文件统一放在 `assets/branding/`。默认图标是中性占位资源，新项目初始化后应先
替换 `assets/branding/app_icon.png`，建议使用 1024x1024 的无透明边距 PNG。

生成 Android/iOS 图标：

```bash
make icons
```

生成原生启动页：

```bash
make splash
```

配置位于 `pubspec.yaml` 的 `flutter_launcher_icons` 和
`flutter_native_splash`。修改背景色、暗色模式或 Android 12 图标后，需要重新执行
生成命令并检查 Android、iPhone 和 iPad 的实际效果。
