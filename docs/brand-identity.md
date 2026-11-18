# Named · Logo 与 App 图标设计规范

**状态:** 定稿（源自 identity round 7，选定方案 C · The Weave / Thread 细化）
**产品权威:** [PRD V1.0](prd-v1.0.md)
**体验方向:** [UI/UX 设计](ui-ux-design.md)
**组件契约:** [Mobile UI Design System](ui-design-system.md)
**源文件:** `docs/brand/logo/round7/c-weave/`

本文是 Named 品牌标识与 App 图标的唯一使用规范。所有界面、启动屏、图标与对外物料都以此为准。它取代旧的「Lora + 叶片」临时标识。

---

## 1. 设计理念

**One thread over and under: the new word tied to what you already know.**

一条线，一上一下，把刚命名的词，和已经知道的经历、对话与记忆系在一起。

标志取品牌首字母 **N**，但它不是一条简单的字母轮廓，而是一段**编织**：

- 两条竖笔（Ink）构成 N 的骨架，是「你知道的」；
- 一条 terracotta 斜线从上往下穿过，先在**左竖笔之上**、再钻到**右竖笔之下**，是「正在命名的那个词」。

这条线由细渐宽、再收细，看起来是「画出来的一根线」而非「拼出来的笔画」。它把 Named 的产品差异——词与经历之间的关系——直接画进了标志里。

识别原则：**一个标志，一个想法。** 标志是「关系的记号」，不是教学产品的图解。

---

## 2. 标志符号（Symbol）

### 2.1 图形

| 属性 | 值 |
| --- | --- |
| 画布 | `viewBox 0 0 256 256` |
| 结构 | 两条弯曲竖笔（Ink `#232A31`）+ 一条斜向 terracotta 线（`#B05230`） |
| 编织顺序 | 线在左竖笔**之上**、右竖笔**之下**（over / under 固定，不可颠倒） |
| 竖笔宽 | 23–27 |
| 线宽 | 由细渐宽再收细：`8 → 26 → 16`（Thread 细化版） |
| 细节 | 竖笔轻微弯曲，整体感偏「手绘」，而非几何构造 |

### 2.2 颜色

| 名称 | HEX | 用途 |
| --- | --- | --- |
| Cobalt 钴蓝 | `#2F4A6B` | App 图标底色、UI 主色 |
| Terracotta 陶土 | `#B05230` | 那根「系住词的线」 |
| Ink 墨 | `#232A31` | N 竖笔、标准字 |
| Paper 纸 | `#FBF8F2` | 反白竖笔、浅色底 |

规则：

- 标志**最多两色**（Ink + Terracotta）。Terracotta 只作那根线，不作大面积底色，也**不是**唯一承载含义的元素。
- 单色场景用 `exports/named-c-symbol-black.svg` / `-white.svg` / `-mono-2f4a6b.svg`。
- 深色底上用 `c-symbol-on-dark.svg`（Paper 竖笔 + Terracotta 线）。
- 线在钴蓝底上的小尺寸对比会下降，但 Paper 竖笔仍保住 N 的剪影，可读性不依赖那根线。

### 2.3 小尺寸截断（Small cut）

16 px 及 favicon / PWA 使用 `c-symbol-small.svg`（反白 `c-symbol-small-on-dark.svg`）。细线起点在小尺寸下会弱化，靠竖笔与 terracotta 斜线保留 N 的辨识度。

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
- 编织的 N 比 Manrope 800 轻，因此**主组合把 N 作为独立符号 + 标准字**，不把 N 直接嵌进词首。
- 「编织字标」（`c-wordmark-woven.svg`）是备选，仅用于允许较浅 N 作为词首的场合；默认不使用。

---

## 4. 组合（Lockups）

| 组合 | 文件 | 用途 |
| --- | --- | --- |
| **横排（主）** | `c-lockup-horizontal.svg` | 通用、App 内页脚、网站 |
| **竖排（主）** | `c-lockup-stacked.svg` | 方形画布、社交头像 |
| 横排·编织字标（备选） | `c-lockup-horizontal-woven.svg` | 少数需要 N 作词首的场合 |
| 竖排·编织字标（备选） | `c-lockup-stacked-woven.svg` | 同上 |
| 深色底变体 | 对应 `-on-dark.svg` | 钴蓝 / 墨色背景 |

主横排 = **N 符号 + 标准字**（符号与文字分离，让符号承载「编织」的个性）。

---

## 5. 安全间距与最小尺寸

### 5.1 安全间距（Clear space）

标志四周留白 **≥ 一个竖笔宽度**。在此范围内不得放置文字、图片或其他元素。

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

| 版本 | 底色 | N 竖笔 | 线 | 文件 |
| --- | --- | --- | --- | --- |
| **主图标** | Cobalt `#2F4A6B` | Paper `#FBF8F2` | Terracotta `#B05230` | `c-app-icon.svg` / `c-app-icon-square.svg` |
| 浅色备选 | Paper `#FBF8F2` | Ink `#232A31` | Terracotta `#B05230` | `c-app-icon-paper.svg` |

- 圆角底：`rx = 54`（256 画布）。iOS / 商店用**全出血方版** `c-app-icon-square.svg`，遮罩由系统处理。
- 符号居中，组缩放 `1.06 × 1.1`（相对 256 画布中心）。

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

- `app/assets/branding/app_icon.png` ← `c-weave/exports/c-app-icon-1024.png`
- 由 `flutter_launcher_icons` 生成全部 mipmap；改源后重跑 `make icons`。

### 6.3 启动屏（Splash）

| 场景 | 文件 |
| --- | --- |
| 浅色 | `c-splash-mark.svg` / `app/assets/branding/splash_mark.png` |
| 深色 | `c-splash-mark-dark.svg` / `app/assets/branding/splash_mark_dark.png` |

改源后重跑 `make splash`。

### 6.4 主题适配

App 图标与启动屏是**品牌常数**，不随 Ink & Cobalt / Ink & Parchment / Plum & Sand 三套主题或浅色/深色模式切换。标识永远是钴蓝底 + Paper N（主图标）。

---

## 7. 错误用法（Misuse）

以下一律禁止：

- 增加第二条线，或改变线的 over / under 顺序。
- 旋转、拉伸、倾斜或改变 N 的比例。
- 把 terracotta 线从 N 上拆离，或让线成为唯一载体。
- 用字体重新输入标准字或 N。
- 加投影、描边、渐变或装饰光晕。
- 把标志做成对话气泡、地球、猫头鹰等教学类陈词滥调的变体。
- 在真实照片上直接叠彩色标志（应使用 Paper 或单色反白版，且置于不透明色块上）。

---

## 8. 交付物清单

源文件位于 `docs/brand/logo/round7/c-weave/`：

| 类别 | 文件 |
| --- | --- |
| 符号 | `c-symbol.svg` · `c-symbol-on-dark.svg` · `c-symbol-small.svg` · `c-symbol-small-on-dark.svg` |
| 标准字 | `c-wordmark.svg` · `c-wordmark-on-dark.svg` · `c-wordmark-woven*.svg` |
| 组合 | `c-lockup-horizontal.svg` · `c-lockup-stacked.svg` · `*-woven.svg` · 各 `-on-dark.svg` |
| App 图标 | `c-app-icon.svg` · `c-app-icon-square.svg` · `c-app-icon-paper.svg` |
| 启动屏 | `c-splash-mark.svg` · `c-splash-mark-dark.svg` |
| 导出 | `exports/`（单色/反白 SVG、1200 / 1024 / 512 PNG、favicon / PWA 全套、webmanifest、head snippet） |
| 演示 | `board.html` · `board.png` · `slides/` |

---

## 9. 与设计系统的关系

- 本文取代 `ui-design-system.md` 第 6 节中「Lora + 叶片」的旧描述。
- 界面显示字体（Lora）与标准字字体（Manrope 800）分工明确，不混用。
- 品牌色与语义色一致：Cobalt `#2F4A6B` = 系统 `primary`（浅色）；Terracotta `#B05230` = 系统 `accent`。

---

## 10. 待办与声明

- 尚未做商标检索；上线前需委托专业检索（商标库 + 反向图片）。
- Manrope 为 SIL OFL，标准字已转轮廓，可商用。
- 若日后加「编织字标」为正式主标，需重新评估 N 与 Manrope 800 的字重匹配。
