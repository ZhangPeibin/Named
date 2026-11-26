# Named · Logo 与 App 图标设计规范

**状态:** 定稿（identity round 8，新标志由 `纯图标.svg` 提供）
**产品权威:** [PRD V1.0](prd-v1.0.md)
**体验方向:** [UI/UX 设计](ui-ux-design.md)
**组件契约:** [Mobile UI Design System](ui-design-system.md)
**源文件:** `docs/brand/logo/round8/`

本文是 Named 品牌标识与 App 图标的唯一使用规范。所有界面、启动屏、图标与对外物料都以此为准。它取代 round 7 的编织 N 标识。

---

## 1. 设计理念

**One line, one point. 一条线，一个点。**

标志是一条连续的品牌红线，绕成一个开口的环，环内收着一个圆点。线条不封口，视线从开口进入，被中心的点接住。它不读作某个字母，而是一个记号：把注意力收束到一个点上，再回到这条线上。

这个形状承担三件事：

- **收束**：环把分散的信息围在一起。
- **回访**：开口让线可以再次进入，对应复习与重访。
- **落点**：圆点是那个被命名、被记住的瞬间。

识别原则不变：**一个标志，一个想法。** 新标志比编织 N 更抽象，因此不叠加任何装饰或第二层含义。

---

## 2. 标志符号（Symbol）

### 2.1 图形

| 属性 | 值 |
| --- | --- |
| 源画布 | `viewBox 480 280 1080 1080`（`纯图标.svg`） |
| 导出画布 | `viewBox 0 0 256 256` |
| 结构 | 一条连续曲线围成开口环 + 环内一个实心圆点 |
| 颜色 | 单色 Brand Red `#D94F58`（浅色底） |
| 线宽 | 由源图形定义，不得单独缩放线宽 |
| 圆点 | 与线条同色；半径由源图形定义，不得拆出单独使用 |

### 2.2 颜色

| 名称 | HEX | 用途 |
| --- | --- | --- |
| Brand Red 品牌红 | `#D94F58` | 浅色底上的标志 |
| Ink 墨 | `#232A31` | 标准字、正文 |
| Paper 纸 | `#FBF8F2` | App 图标底、深色底上的反白标志与标准字 |

规则：

- 标志**只有一色**。浅色底用 Brand Red，深色底用 Paper 反白。
- Cobalt `#2F4A6B` 和 Terracotta `#B05230` 仍是 UI 语义色，不参与标志配色。
- 不要给标志加渐变、描边、投影或第二种颜色。

### 2.3 小尺寸

新标志是实心形状，缩小时比细线标志更稳。16 px、favicon 与 PWA 直接使用同一图形，不做断线或简化版本；导出时把内容放大到画布的 86%。

---

## 3. 标准字（Wordmark）

| 属性 | 值 |
| --- | --- |
| 字体 | **Manrope 800**（SIL OFL，可商用） |
| 字距 | `-0.03em` |
| 内容 | `Named`（首字母大写，不重排字母） |
| 形式 | 已转轮廓，勿用字体直接重排 |

说明：

- 界面展示字体仍用 **Lora**；Manrope 仅用于标准字，二者不混用。
- 标准字文件沿用已转轮廓的 Manrope 800 路径，不因新标志重新排版。

---

## 4. 组合（Lockups）

| 组合 | 文件 | 用途 |
| --- | --- | --- |
| **横排（主）** | `named-lockup-horizontal.svg` | 通用、网站导航、App 内页脚 |
| **竖排** | `named-lockup-stacked.svg` | 方形画布、社交头像 |
| 深色底横排 | `named-lockup-horizontal-on-dark.svg` | 深色背景 |
| 深色底竖排 | `named-lockup-stacked-on-dark.svg` | 深色方形画布 |

主横排 = **符号 + 标准字**，符号与文字分离。符号高度约为标准字高度的 1.5 倍，间距为符号内容宽度的约 0.2 倍。不要重新调整这个比例。

---

## 5. 安全间距与最小尺寸

### 5.1 安全间距（Clear space）

标志四周留白 **≥ 一个圆点直径**。在此范围内不得放置文字、图片或其他元素。

### 5.2 最小尺寸

| 元素 | 最小 |
| --- | --- |
| 符号（单独） | 16 px |
| 标准字 | 160 px 宽 |
| 横排组合 | 200 px 宽 |
| 竖排组合 | 80 px 高（参考） |

---

## 6. App 图标（App Icon）

### 6.1 构图

| 版本 | 底色 | 标志 | 文件 |
| --- | --- | --- | --- |
| **主图标** | Paper `#FBF8F2` | Brand Red `#D94F58` | `named-app-icon.svg` |
| iOS / 商店母版 | Paper `#FBF8F2` | Brand Red `#D94F58` | `named-app-icon-square.svg` |

- 预览版圆角 `rx = 54`（256 画布）。iOS / 商店用**全出血方版**，遮罩由系统处理。
- 标志居中，内容约占画布 74%。不要为了“填满”继续放大。

### 6.2 平台尺寸

**iOS（App Store）**

| 规格 | 尺寸 |
| --- | --- |
| App Store 母版（必填） | 1024 × 1024 |
| iPhone / iPad 各档 | 由 1024 母版生成（120 / 180 / 152 / 167 / 76 / 40 / 60 / 29 / 20 …） |

**Android**

| 规格 | 尺寸 |
| --- | --- |
| 旧式方形 | 48 / 72 / 96 / 144 / 192 px |
| Adaptive 母版 | 512 × 512（前景 + 背景） |
| 前景安全区 | 108 × 108 dp 画布，核心内容在中央 66 dp 安全区内 |
| Maskable | 512 × 512，重要内容在中央 66% 安全区内 |

**Flutter 落地**

- `app/assets/branding/app_icon.png` ← `round8/exports/app-icon-1024.png`
- 由 `flutter_launcher_icons` 生成全部 mipmap；改源后重跑 `make icons`。

### 6.3 启动屏（Splash）

| 场景 | 文件 |
| --- | --- |
| 浅色 | `named-splash-mark.svg` / `app/assets/branding/splash_mark.png` |
| 深色 | `named-splash-mark-dark.svg` / `app/assets/branding/splash_mark_dark.png` |

浅色启动屏用 Brand Red，深色启动屏用 Paper 反白；两者是同一图形。改源后重跑 `make splash`。

### 6.4 主题适配

App 图标与启动屏是**品牌常数**，不随 Ink & Cobalt / Ink & Parchment / Plum & Sand 三套主题或浅色/深色模式切换。App 图标永远是纸底 + 品牌红标志。

---

## 7. 错误用法（Misuse）

以下一律禁止：

- 旋转、拉伸、倾斜或改变环与圆点的比例。
- 把开口闭合，或把圆点移出环外。
- 把圆点拆出来当作列表符号、加载指示或按钮图标。
- 改变标志颜色，或给标志加第二种颜色、描边、渐变、投影。
- 用字体重新输入标准字。
- 在真实照片上直接叠彩色标志（应使用 Paper 或单色反白版，且置于不透明色块上）。

---

## 8. 交付物清单

源文件位于 `docs/brand/logo/round8/`：

| 类别 | 文件 |
| --- | --- |
| 符号 | `named-symbol.svg` · `named-symbol-on-dark.svg` |
| 标准字 | `named-wordmark.svg` · `named-wordmark-on-dark.svg` |
| 组合 | `named-lockup-horizontal.svg` · `named-lockup-horizontal-on-dark.svg` · `named-lockup-stacked.svg` · `named-lockup-stacked-on-dark.svg` |
| App 图标 | `named-app-icon.svg` · `named-app-icon-square.svg` |
| 启动屏 | `named-splash-mark.svg` · `named-splash-mark-dark.svg` |
| 导出 | `exports/`（app icon、splash、lockup PNG、favicon / PWA 全套） |
| 生成脚本 | `generate.py` |

---

## 9. 与设计系统的关系

- 本文取代 `ui-design-system.md` 第 6 节中编织 N 的描述。
- 界面显示字体（Lora）与标准字字体（Manrope 800）分工明确，不混用。
- 品牌红是标志专用色；Cobalt `#2F4A6B` = 系统 `primary`，Terracotta `#B05230` = 系统 `accent`。三者不互换。

---

## 10. 待办与声明

- 尚未做商标检索；上线前需委托专业检索（商标库 + 反向图片）。
- Manrope 为 SIL OFL，标准字已转轮廓，可商用。
- 新标志的源文件只有 `纯图标.svg`；其余 SVG 由 `round8/generate.py` 生成，不要手工修改导出文件。
