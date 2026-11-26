# 图标与启动页

品牌源文件统一放在 `assets/branding/`。当前使用 round 8 的开口环 + 圆点标志，单色品牌红 `#D94F58`：

- `app_icon.png`：纸色底 `#FBF8F2` + 品牌红标志（1024×1024，无透明边距）。
- `splash_mark.png`：透明底，品牌红标志（用于浅色启动页背景 `#FBF8F2`）。
- `splash_mark_dark.png`：透明底，纸色 `#FBF8F2` 标志（用于深色启动页背景 `#171A1D`）。
- `marks/symbol_light.png` / `symbol_dark.png`：App 内启动页使用的浅色 / 深色标志。
- `marks/lockup_light.png` / `lockup_dark.png`：登录页使用的横排组合（浅色：红标志 + 墨色标准字；深色：纸色反白）。
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
