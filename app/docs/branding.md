# 图标与启动页

品牌源文件统一放在 `assets/branding/`。当前使用 The Weave（Thread 精修）的 N 符号，采用**纸底墨色**呈现：

- `app_icon.png`：纸色底 `#FBF8F2` + 墨色 N `#232A31` + 陶土线 `#B05230`（1024×1024，无透明边距）。
- `splash_mark.png`：透明底，墨色 N + 陶土线（用于浅色启动页背景 `#FBF8F2`）。
- `splash_mark_dark.png`：透明底，纸色 N + 陶土线（用于深色启动页背景 `#171A1D`）。
- 修改品牌源后，先更新对应 PNG，再运行 `make icons` / `make splash`；图标保持 1024×1024、无透明边距。

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
