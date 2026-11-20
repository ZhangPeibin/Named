# Loop closure - 需求讨论

**Status:** discussion
**Release:** v1
**Feature:** loop-closure
**Parent:** #57

## 问题

Named 已经具备 Discover、Word、Moment、Talk、Review、Challenge 和 Soul，但学习闭环没有闭合。证据有四条：

1. **取词随机。** `app/lib/features/review/providers/review_providers.dart` 从 Words 取前 3 个非 `known` 词后调用 `shuffle()`，把后端 `_word_status` 已排好的 `needs_review → growing → known` 顺序打乱；复习内容不可预期。
2. **复习方向是翻译。** Review 先显示英文词，用户点「看释义」后读中文（`review_page.dart`）。这是识别加英→中映射，不是产出。
3. **写回无感。** 复习只增加 `review_count` 与 `last_reviewed_at`，这两个值只影响 composer 提示权重（`composer_hint.dart`），不改变用户在 Timeline 看到的词。
4. **返回入口竞争。** composer hint、daily read、challenge carousel、progress card 各自提示「回来做点事」，但没有一个说清楚「今天见哪三个词」。

预期中的知识图谱原本承担「把这些内容连起来」的职责。但图谱是横向的：多对多关系、可浏览。闭环是纵向的：一次循环带着累积状态回到起点。

> **知识图谱不是闭环的前提，状态才是。** 一个词的状态被它自己的经历改变，并在下一次相遇时被看见，闭环才成立。

因此本功能先不依赖图谱，用状态闭合；图谱作为后续增强。

## 闭环定义

**Discover → Attempt → Understand → Save → Review → Reuse**

| 环节 | 完成的判定 |
| --- | --- |
| Discover | 一次发现变为 ready，并关联到 Word 或 Moment |
| Attempt | 用户自己产出过该词或该句（`attempt_count ≥ 1`） |
| Understand | 用户打开了 Word／Moment 内容并看到释义或听读 |
| Save | 对话与发现自动保存，用户原话与改进建议分开保留 |
| Review | 用户在复习中先产出，再自评「说出来了」 |
| Reuse | 用户在 Talk 中用自己的话用出该词（记录 `used_count`） |

六步不要求每次顺序执行；闭环成立的条件是**同一个词在时间上走完一圈，且状态可见**。

## 词的生命周期

每个词对每个账号有一个 `WordProgress`。状态由 `_word_status()` 计算，并在 Words 列表与 word card 上展示。

| 状态 | 含义 | 进入条件 |
| --- | --- | --- |
| `needs_review` | 还没试过 | 无尝试，或最近一次尝试已超过 7 天 |
| `attempted` | 试过，还需要再见 | 7 天内有尝试，但没有在近期复习成功 |
| `growing` | 近期复习过 | `last_reviewed_at` 在 7 天内 |
| `known` | 用户自己认为会了 | `self_known_at` 非空（用户主动标记） |

- 排序优先级：`needs_review` → `attempted` → `growing` → `known`。
- `used_count`／`last_used_at` 作为证据记录，不单独成为状态；它们让「用上了」可见，但不自动升级状态。
- `known` 不表示掌握，只表示用户自己这样认为；退出该状态由用户操作。

状态转换：

```
发现 ──► needs_review ──attempt──► attempted ──reviewed(说出来了)──► growing
              ▲                        │                              │
              └──── 7 天无尝试/复习 ◄──┴──────────────────────────────┘
任意状态 ──用户标记──► known ──用户取消──► needs_review
```

## 单一返回触发器

- 唯一主入口：Timeline 顶部「今天要见的词（3）」。
- 数量固定 3，与现有 Review 3 一致；没有待见词时卡片不出现，不显示 0。
- composer hint 不再把 review 作为高权重类别；daily read、challenge、progress 保持各自职责，但都不是复习主入口。
- 理由：四个互相竞争的提示等于没有提示；用户需要一个明确的「回来做什么」。

## 先开口，再给答案

**不给句子，只给词。** 用户有可能自己产出的内容，产品不得先给。

| 场景 | 是否先要求产出 | 说明 |
| --- | --- | --- |
| Discover 单个名词 | 否 | 未接触过的词无法产出，直接给是恰当的 |
| Moment 整句 | 是 | 整句是用户的表达，AI 只提供示范 |
| Talk 每一轮 | 是 | AI 重述用户的话，不整段替换 |
| Review | 是 | 先产出，再看提示与答案 |
| `Help me say it` | 是 | 用户先尝试或明确说不会，才展开 |

例外，避免原则变得不可用：

1. **首次发现可免费揭示。** 新用户第一次 Discover 直接给答案，从第二次交互起要求先开口。
2. **未知词可直接给。** 判断依据是这个账号是否见过该词，而不是难度猜测。
3. **能力不足时降级。** 连续两次未产出则直接展开答案，不把用户卡在原地。
4. **技术失败不算沉默。** 识别、网络、语音失败时显示答案与重试，不解读为用户不会。

原则成立的前提是「尝试必须换来不同的结果」：尝试后得到针对性的修正或更准确的语块，而不是与跳过完全相同的示范，否则用户会学会跳过。

## Soul 用户控制

Soul 后端已有完整 CRUD（`GET/PATCH /soul`、`POST/PATCH/DELETE /soul/items`）与 `source` 字段，但用户看不到、改不了。本功能要求：

- 用户可以看到每一条 Soul item，并区分来源：初始引导、用户填写、AI 提炼。
- 用户可以编辑、删除、新增。
- 每个会话有「使用记忆」开关；关闭后该会话不注入任何 Soul item，新会话默认开启。
- 全局「自动提炼」开关；关闭后不再自动写入 AI 提炼项。
- 不做逐条审批：提炼项立即生效但保持可见、可删。审批打断交流，与「不把每次对话变成固定教学脚本」冲突。
- AI 提炼项可以影响话题选择，但不得作为用户事实复述；prompt 中必须明确这一点。

## 边界与失败情况

- 用户直接跳过尝试：允许，但该词状态不前进，并在下一次返回时排在前面。
- 词没有图片或音标：使用文字提示与可得音频，不阻塞复习。
- `attempt` 写入失败：复习继续，状态不前进，下一轮再次出现；不得伪装成功。
- 用户把词标记为 known 后又想复习：可从 Words 主动进入复习，不依赖「今天要见的词」。
- `used_count` 的匹配必须按词边界，避免 `can` 命中 `candle`。
- 同一账号内同词多次发现：状态按词聚合，发现次数作为证据展示，不重复创建状态。

## 决策

- **闭环靠状态，不靠图谱。** 图谱降级为后续增强，不阻塞本功能。
- **单一返回触发器。** Timeline 顶部卡片；其余提示降级。
- **复习方向翻转。** 先产出，再提示，最后揭晓；自评，不做读音评分。
- **新增 `attempted` 状态。** 保留 `needs_review / growing / known`，不引入掌握度。
- **尝试落库。** `attempt_count`／`last_attempt_at` 是闭环的证据，不是分数。
- **Talk 写回是包含匹配。** 不做 AI 判定，规则需可测试。
- **先开口再给答案，只针对句子。** 未知单词直接给。
- **Soul 用户控制不做逐条审批。** 用「可见 + 可删 + 会话开关」代替。
- **Challenge practice 本次不动。** 它已有 listen & say，避免重复实现。
- **不宣称掌握。** 任何状态与文案都不把次数等同于掌握。

## 待解决的设计问题

1. **提示阶梯的层级。** 首字母 → 音标 → 音频 → 答案 是否适用于所有词；无音标时如何降级。
2. **Moment 的复习形态。** 整句产出如何自评，是否允许只说出关键词。
3. **`used_count` 匹配的词边界规则。** 需要确认英文词形变化（`water` / `watering`）是否命中。
4. **Soul `source` 值域。** 现有 `onboarding`、`user_edit` 之外，AI 提炼使用哪个值，是否需要 `kind` 约束。
5. **自动提炼写入路径。** 当前仓库中未见自动写入 Soul item 的代码，需要确认该开关是否有实际作用对象。
6. **Review 的时长边界。** 3 个词之外的词何时再现，是否需要每日上限。

## 证据

- `backend/src/models.py:140`：`WordProgress` 现有字段 `self_known_at`、`review_count`、`last_reviewed_at`。
- `backend/src/discovery/service.py:623`：`_word_status()` 当前三态与 7 天窗口。
- `backend/src/discovery/service.py:641`：Words 排序按 `needs_review → growing → known`。
- `backend/src/discovery/service.py:672`：`mark_word_reviewed()` 只增加计数与时间。
- `backend/src/talk/service.py:169`：Soul item 以 `source` 注入 prompt。
- `backend/src/soul/router.py`：Soul item 已支持新增、修改、删除。
- `app/lib/features/review/providers/review_providers.dart:11`：随机取 3 个词。
- `app/lib/features/review/presentation/review_page.dart:33`：`showMeaning` 直接揭示中文。
- `app/lib/features/timeline/presentation/composer_hint.dart:27`：`reviewCount > 0` 提高提示权重。
- `docs/prd-v1.0.md` 第 3、4、5.5、5.10、5.11、9、12 节。

## Session Log

- 2026-11-20：确认闭环优先于知识图谱；确定状态式闭环、单一返回入口、复习方向翻转、先开口再给答案与 Soul 用户控制五项决策，拆分为 #58–#64。

## 实现记录

- **单一入口落在屏幕顶部固定区**，不是列表第一项：Timeline 打开时滚动到底部，历史列表的「顶部」是不可见的。卡片随 `dueReviewCountProvider` 出现，返回后自动刷新。
- **Review v2 暂用文字线索**：Words 列表不携带发现图片，复习以中文释义作为「说出它」的线索；有图时的形态留待数据支持后补充。
- **尝试与自评分开**：`POST /words/{id}/attempt` 只记录尝试；「说出来了」才调用 `reviewed`。尝试写入失败时复习继续，但状态不前进，并显示失败提示。
- **`used_count` 采用词边界匹配**：只匹配词或语块，`can` 不会命中 `candle`；不做 AI 判定。
- **Soul 自动提炼开关只落字段与读取判断**：仓库当前没有自动写入 Soul item 的路径，`soul_profiles.auto_extract` 已存在并可通过 `PATCH /soul` 修改，但尚无写入方消费它；不提供无效的 UI 开关。
- **会话级记忆开关已实现**：`conversations.use_memory` 默认 true，`PATCH /conversations/{id}` 修改；关闭后 Talk 与 Help 都不注入 Soul。
- **Challenge practice 未合并**：本次不改动其 listen & say 流程，避免重复实现。
