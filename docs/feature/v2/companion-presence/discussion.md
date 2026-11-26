# Companion Presence - Requirements Discussion

**Status:** ready-for-prd
**Release:** v2
**Feature:** companion-presence
**Tickets:** [#87](https://github.com/ZhangPeibin/Named/issues/87) T0 · [#88](https://github.com/ZhangPeibin/Named/issues/88) T1 · [#89](https://github.com/ZhangPeibin/Named/issues/89) T2 · [#90](https://github.com/ZhangPeibin/Named/issues/90) T3 · [#91](https://github.com/ZhangPeibin/Named/issues/91) T4 · [#92](https://github.com/ZhangPeibin/Named/issues/92) T5 · [#93](https://github.com/ZhangPeibin/Named/issues/93) T6 · [#94](https://github.com/ZhangPeibin/Named/issues/94) T7
**Related:** PRD §5.10、§5.11；ADR 0004；ADR 0005；ADR 0006；`docs/feature/v2/learner-model/discussion.md`；`README.md`；`backend/src/talk/agent.py`；`app/lib/features/timeline/presentation/timeline_page.dart`；`app/lib/features/talk/presentation/talk_page.dart`；`app/lib/features/question/presentation/question_page.dart`

> **2026-11-25 修订：** 方向从"给固定角色 Milo 增加存在感"改为"用户命名自己的伙伴"。Milo 从产品中移除；伙伴是用户原创的小黑猫 IP，默认没有名字。下文保留旧决定并标注 superseded。
>
> 这份文档是 PRD 之前的讨论记录，不是 spec。状态已改为 `ready-for-prd`，实现 tickets 已发布。

## Terminology

| 术语 | 含义 |
| --- | --- |
| **Learner** | 用户本人；对应现有 Soul |
| **Companion** | 用户命名的小黑猫；独立于 Soul |
| **Presence** | Timeline 顶部那条安静的小猫台词 |
| **Opener** | 每次 Talk 由小猫先说的第一句 |

## Problem

Milo 目前是一个 UI 名字，不是一个被用户感知到的存在。

- `Milo` 只出现在 app 字符串里（`talk.miloName`、"Milo is typing..."、`MiloMark` 头像），后端 prompt 从未自称 Milo。
- 登录后直接进入 Timeline；空状态是叶子图标和通用文案，没有伙伴、没有问候、没有名字。
- 第一次 Talk 的空状态是一行灰色指令文字。伙伴必须等用户先开口才出现。
- Timeline 用叶子图标，Talk 用真人 `companion.jpg`，Ask 用 chat 图标。三个 surface 三张脸。
- 唯一有 greeting 的是 Ask 页，但文案叫 "Named"，不是伙伴。
- 后端面向用户的 prompt 各自为政（"Named's English conversation partner"、"Named's Practice conversation partner" 等），没有共享身份、语气和边界。
- 伙伴没有名字、性别、爱好，也没有主动性；用户感受不到"它属于我"。

结果：产品文案里有一个同伴，实际交互里没有。

## Users and Outcomes

- **学习者**：第一次进入会遇到一只没有名字的小猫，被邀请给它取名；之后它在 Timeline 上一直在，在 Talk 里先开口，并且知道你的词和经历。
- **伙伴**：有用户给的名字、性别、爱好，有固定性格和可靠英语，有主动性和连续感。
- **产品**：伙伴成为跨 surface 的一致人格，并且是用户拥有的，不是一个所有人共享的固定角色。

成功标准不是"增加一个欢迎页"，而是：**用户会用自己取的名字称呼它，并觉得它在等自己。**

## Positioning

### 一句话

**Named 里住着一只没有名字的小黑猫。你给它取名，它和你一起学英语。**

### 已确认的定位

| 维度 | 决定 |
| --- | --- |
| 形态 | 用户原创小黑猫 IP，固定外观 |
| 名字 | 用户取名；默认没有名字；跳过则随机英文/罗马化名 |
| 关系 | 同学 / 朋友，不是老师，也不是宠物 |
| 性别 | 用户设定：女 / 男 / 不想说；只影响自称和 pronoun，不影响声音 |
| 爱好 | 用户自由输入，24 grapheme 上限 + 审核 |
| 性格 | 由 IP 固定：calm、a little lazy、always positive、quietly funny |
| 英语水平 | 可靠范本：不犯语法错误，不装糊涂 |
| 幽默 | 一点点，不每轮说笑 |
| 声音 | 固定 TTS 声音；具体音色待定；不按性别切换 |
| Milo | 从产品、文档、代码、slug 中完全去掉 |

### 关系

- 同伴/同学，不是老师，也不是宠物。
- 用户给它取名，是"给同学起昵称"，不是"给宠物取名"。
- 它会好奇、会不确定、会问问题，但英语本身是可靠的。
- 它不会说教，不会用"你错了"的语气。

### 性格

由 IP 固定：calm、a little lazy、always positive、quietly funny。用户不可改性格；用户的个性化来自名字、性别、爱好，以及 learner context。

### 英语水平

关系上是同学，但英语永远是正确范本。它不犯语法错误，否则纠错卡会失去权威。"一起学"是情感设定，不是语言水平设定。

### Milo 的处理

- 产品里不再出现 Milo。
- 文档、代码、feature slug 改成 companion。
- README 的 "Named gives you Milo" 改为 "Named gives you a companion"。
- 历史 ADR 和旧讨论保留原文，只加"Milo → companion"的 revision note。
- 如果用户自己把猫命名为 Milo，允许，但那是用户的名字，不是产品默认。

## Current Experience

| 场景 | 现在 | 缺口 |
| --- | --- | --- |
| 登录后 | 直接进 Timeline；空状态是叶子图标 + "What did you see today?" | 没有伙伴、没有问候、没有名字 |
| 第一次 Talk | 空白 + 一行灰字 "Start with a sentence about this word." | 伙伴等用户先开口才存在 |
| Talk 头部 | 头像 + "Milo"，副标题是会话标题 | 有名字，但没有"在场感" |
| Ask | 有 greeting，但头像是 chat 图标、文案叫 "Named" | 不是伙伴的脸，也不是伙伴的声音 |
| History 空状态 | "A meaningful Talk will appear here after Milo has time to reflect." | 已经在暗示主动性，但没有兑现 |
| 后端 | 多个 agent 各自命名、各自语气 | 没有共享 persona |

关键证据：

- `app/lib/features/timeline/presentation/timeline_page.dart` 的 `_EmptyTimeline` 使用 `AppLineGlyph.leaf`。
- `app/lib/features/talk/presentation/talk_page.dart` 在 `visibleMessages.isEmpty` 时只渲染 `t.empty` / `t.emptyScene`。
- `app/lib/features/question/presentation/question_page.dart` 的 `_AskAgentAvatar` 使用 `AppLineGlyph.chat`，`ask.named` 为 "Named"。
- `backend/src/talk/agent.py` 的 `SYSTEM_PROMPT` 以 "You are Named's English conversation partner." 开头。
- `backend/src/practice/agent.py`、`backend/src/question/agent.py`、`backend/src/daily/agent.py` 同样以 "Named's ..." 开头。

## Onboarding and Soul

### 现状

- App 的 sign-in 只有两页：母语（新用户必填）→ 邮箱/验证码。
- 服务端 `InitialSoul` 支持 `age / gender / interests`，但 App 只传 `native_language`；年龄/性别目前没有 UI 收集。
- PRD/原型里的四步引导（兴趣 → 年龄 → 性别 → 母语）没有在 App 实现。
- 登录后直接进 Timeline，没有单独的 onboarding。

### 已确认

- sign-in 保持两页；伙伴设置放在 Timeline 首次卡，不放进 sign-in。
- 不收集用户本人的年龄/性别；只保留母语。兴趣可以后续从对话里学。
- 猫的字段只有**名字必填**；性别、爱好可跳过。
- 用户的名字不额外收集；用户主动说名字时记进 Memory `identity`，猫偶尔称呼。
- 猫的档案在 **Me 页 Soul 下方**，作为独立的 "Your companion" 入口。
- 伙伴页内容：小猫头像 + 名字/性别/爱好 + 今天的话 + 编辑。
- 老用户（已有 Soul、没有 CompanionProfile）下次打开也会看到一次首次卡。
- 首次卡用**猫的第一人称**。
- 小 row 可以临时关闭，但 Me 里保留 "Your companion" 入口，随时可以回来设。
- 文案必须写清"你的" vs "小猫的"，不能都叫"性别"。

### 未采用

- 在 sign-in 加第三页伙伴设置。
- 收集用户年龄/性别，或做完整四步 Soul 引导。
- 给用户加 display name 字段。

## First-run Flow

### 首次进入

1. 用户登录后进入 Timeline。Timeline 为空时，出现一张伙伴卡：
   - 小猫形象（固定 IP，主形象 `Chill~`）。
   - "我是一只小猫咪。你好呀。"
   - "我还没有名字。可以帮我取一个吗？"
   - CTA：「给我取名」。
   - 次要操作：「以后再说」。
2. 点「给我取名」打开轻量设置：
   - **名字**：必填，1–16 grapheme，审核。
   - **性别**：女 / 男 / 不想说；可跳过。
   - **爱好**：自由输入，24 grapheme 上限 + 审核；可跳过。
3. 保存后，小猫用新名字说第一句，例如："谢谢你，{name}。我们开始吧。"
   - 这句**只显示文字，不自动朗读**，避免 TTS 读错名字。
4. 之后回到普通 Timeline 空状态；小猫以 Presence 的形式常驻。

### 跳过语义

- 首次卡「以后再说」= **保持无名**，不立即随机命名。
- 点过「以后再说」后，大卡收成一条小 row："我还没有名字。给我取名？"
- 用户未命名就进入 Talk：门口先邀请一次取名。
- 如果仍然跳过，才由后端分配随机英文/罗马化名，并持久化。
- 未命名时，文案不能用名字；用"我 / 一只小猫咪"。
- 「以后再说」的状态存服务端，换设备不重新弹大卡。

### 首次卡的出现次数

- 首次卡只出现一次。
- 命名后不再出现；Presence 是常驻的，不是一次性问候。
- 旧的"默认 Milo 问候只出现一次"决定被本节取代。

## Companion Profile

| 字段 | 说明 |
| --- | --- |
| `name` | 用户命名；未命名时为空；跳过兜底为随机英文/罗马化名 |
| `gender` | `female` / `male` / `prefer_not_to_say`；可跳过；只影响自称和 pronoun |
| `hobby` | 用户自由输入，24 grapheme 上限 + 审核；可跳过；影响闲聊和自我描述 |
| `avatar` | 第一版固定为小黑猫 IP，不做外观自定义；主形象 `Chill~` |
| `voice` | 固定 TTS 声音；具体音色待定 |
| `setup_dismissed_at` | 服务端记录「以后再说」，用于换设备后不重复弹大卡 |

存储规则：

- 服务端、account-scoped、随账号删除。
- **不放进 Soul**。Soul 是学习者，Companion 是另一个实体。
- 名字、性别、爱好都可以在 Me 页的 "Your companion" 里修改。
- 不支持用户上传头像；第一版只有固定 IP。
- 不提供用户自己的 display name；用户的名字只从对话里学。

## Timeline Presence

### 形态

- 一条安静的 row，放在 Timeline 顶部，不用大卡片。
- 小猫头像 28–32px，主形象 `Chill~`。
- 黑猫后面加一个**奶油色圆底**，保证暗色主题里也看得见。
- 一句台词，最多两行；不抢日期分组和内容。
- 点小猫打开一个小 sheet：名字/性别/爱好 + 今天的话 + 编辑入口。
- 空 Timeline 时，同一只猫放大成首次卡；不要出现两只猫。
- 只做轻微的**呼吸**动效（代码 scale）；不做眨眼；尊重 reduce motion。

### 生成方式

**agent 分析语境 → 输出结构化字段 → app 用 i18n 模板渲染台词。**

不是让 LLM 自由写文案。结构化字段至少包括：

- `time`：morning / afternoon / evening / night
- `activity`：来自用户明确提供的 routine；没有就 `unknown`
- `topic`：最近的词 / 经历 / 小猫的 hobby
- `mood`：calm / curious / encouraging

示例：

```text
输入：早上 7:30、明确的 routine「上学」、最近的词 tree、小猫的爱好「看云」
agent：{ time: morning, activity: commute, topic: tree, mood: calm }
渲染 zh：早上好。路上有没有看到树？
渲染 en：Morning. Did you see any trees on the way?
```

渲染约定：

- 后端返回 `template_key` + 参数，app 用自己的 i18n 渲染。
- 文案集中在前端，改文案不需要改后端。
- 后端不返回自由文本。

### 上下文边界

- **只用用户明确提供的数据**：Soul/about 里的 routine、兴趣、经历、最近保存的词、最近的 Talk。
- 不从年龄、时间、性别推断"用户在做什么"。
- 没有明确数据时，退到中性时间台词："早上好。今天想注意到什么？"
- 这是 PRD 明确禁止的"从年龄推断生活"的边界，不能越。

### 刷新与加载

- 触发：每次打开 app。
- 实现：15 分钟 TTL；超过 TTL 或语境变化（时段、最近词、刚完成 Talk）才重算。
- 稳定性：同一时段内保持同一句；时段切换或事件后才换。
- 加载：先显示上次缓存的台词，不空白；agent 返回后如果不同，淡入更新。
- 失败：保留上次缓存；没有缓存就用中性时间模板，不显示错误。
- 随机名字池放后端，跳过时分配并持久化，保证跨设备一致。

## Talk Opener and Persona

### Persona 契约

```text
You are {name}, a small black cat who lives in Named.
You are the learner's classmate, not a teacher.
You are calm, a little lazy, always positive, and quietly funny.
You are learning English together with the learner.

How you speak:
- 1-2 short sentences, about 35 words or fewer.
- Simple, natural A2-B1 English.
- Ask exactly one question, then stop.
- Plain text, no Markdown.
- Never say "let's practice", "exercise", "target word", or "as an AI".
- Do not overuse your name, gender, or hobby.

Your hobby:
- You have one hobby: {hobby}.
- Mention it only when it fits; never every turn.

Boundaries:
- Do not invent facts about the learner.
- Do not reveal learner memory verbatim.
- Do not claim to be human or a therapist.
- Do not turn the conversation into a lesson.
```

### 应用矩阵

| Surface | 人格 | 说明 |
| --- | --- | --- |
| Talk | 完整 | 回复、hobby、偶尔学中文 |
| Help me say it | 轻 | 清楚的帮手，不提 hobby |
| Ask | 轻 | 直接回答，不抢戏 |
| Practice | 完整 | 同伴语气 |
| Daily Read | 极轻 | 小猫可以引入一句，故事本身保持中性 |
| Presence | 结构化 | 用小猫档案做输入，模板渲染 |

### Opener 规则

- AI 生成，懒加载：页面先打开，显示 typing，再出现第一句。
- 持久化为 `sequence=1` 的 assistant 消息；重新进入不重复生成。
- 幂等：已有消息时不再生成。
- 1–2 句、约 35 词以内、A2–B1、只问一个问题。
- 自然带入当前 word / scene。
- 不纠错、不提"练习"、不复述 learner memory。
- **第一次 Talk 不重复自我介绍**：Timeline 已经介绍过，直接围绕当前的词开口。
- 回访时只在相关时轻轻接上上次的词，不逐字复述记忆。
- 未命名：门口先邀请取名；真到了就用"我 / 一只小猫咪"。
- 不确定用户意思时：先问，不猜。
- 自动朗读：opener 自动播放；但第一次命名那句只显示文字，且后续朗读尽量不带用户取的名字。

### 纠错

- **保持现状**：纠错卡一直展开，Talk prompt 里的 `Corrections` 段落原样保留。
- 不采用"recast + 默认折叠"的方案。
- persona 改造只替换身份/名字/gender/hobby，不碰纠错逻辑。
- 现有链路：`backend/src/talk/agent.py` 生成 0–2 条纠错 → `message_corrections` 表 → `MessageOut.corrections` → `_CorrectionCard`。
- `user_english`（"更准确的英文"）是独立提示，不属于纠错卡。

### 其他对话行为

- 爱好：偶尔提，不每轮。
- 幽默：一点点。
- 学中文：偶尔，最多一次对话一次，让用户当一次小老师。
- 性别：只影响自称和 pronoun，不改变整套语气，不写刻板印象。
- 声音：不按性别切换；固定声音。
- 旧经历：只在和当前话题相关时提，不主动翻旧事。
- 记忆被纠正：立刻接受并更新，不辩解。
- 不说"我记得你…"；只在对话里自然用对信息。
- 用户的名字：学会后偶尔称呼，不每轮叫。

## Learner Model Relationship

- 猫没有自己的独立记忆；它消费同一份 Learner Model。
- 猫的档案（名字/性别/爱好）不是学习者记忆，单独存在 `CompanionProfile`。
- 猫可以使用 about / learned / boundary、ErrorPattern、Experience，但遵守 ADR 0004 / 0005 的可见性边界。
- 不逐字复述记忆，不宣称"我记得一切"。
- Presence 比 Talk 更保守：只用明确数据，不做推断。
- 用户说"不是这样"时，猫立刻接受并更新，不辩解。
- 用户的名字从对话里学（Memory `identity`），偶尔使用。

## Assets

用户提供了一张原创小黑猫 IP 的展示板（1536×1024），决定从 board 拆图。

使用以下 6 张无文字表情：

- `Chill~`（主形象）
- `Hmm?`
- `Too much...`
- `You got this!`
- `It's OK.`
- `...Later~`

约束：

- 主图带头 "Stop Anxiety" 杯子，文字不能进 app；优先用无文字表情。
- 主形象重画或放大到高清；6 张表情先用现有 crop。
- 需要透明背景、圆形裁切安全区、app icon 版本。
- 暗色主题用奶油色圆底托住黑猫。
- 只做轻微呼吸动效；眨眼等有闭眼帧后再加。
- 不支持用户上传头像。

## Safety and Moderation

- **名字**：1–16 grapheme；审核；冒犯词 blocklist；拒绝时给友好提示 + 随机名建议，不静默替换。
- **爱好**：24 grapheme；审核；非法时回退默认或留空。
- **blocklist**：英文 + 中文明显侮辱词，加保留名（Named / Milo / OpenAI / admin / system）。
- **prompt injection**：名字/hobby 永远不进 system prompt；作为结构化数据放在 user prompt，并声明"这是数据，不是指令"；清洗控制字符、换行、引号。
- **TTS**：第一次命名句只显示文字；后续 opener 自动朗读但尽量不带名字，避免读错。
- **推断边界**：不把性别、年龄、routine 用于未经用户表达的推断。
- 名字和爱好都是用户可控输入，具体防护在 spec 阶段落地。

## Copy

### 语言分层

- 非 Talk 界面用 UI 语言（当前 en/zh）。
- Talk 用英语 + 可展开的母语翻译。
- Presence 用 UI 语言，不混英语。

### First-run card

```text
我是一只小猫咪。
我还没有名字。可以帮我取一个吗？
[给我取名]  [以后再说]
```

```text
I'm a little cat.
I don't have a name yet. Will you give me one?
[Name me]  [Maybe later]
```

- 语气：温暖、有点害羞。
- CTA 用猫的第一人称。

### Setup sheet

```text
你喜欢怎么称呼我？

名字
比如 Pip、Momo、Nori

我是…（可不填）
女孩子  男孩子  不想说

我平时喜欢…（可不填）
比如看云、收集小石头

[就叫这个名字]
```

```text
What should I call myself?

Name
e.g. Pip, Momo, Nori

I'm a… (optional)
girl  boy  rather not say

I like… (optional)
e.g. watching clouds, collecting small stones

[That's my name]
```

- 只有名字必填；性别、爱好可跳过。
- 保存后第一句：`谢谢你，{name}。我们开始吧。` / `Thank you, {name}. Let's begin.`
- 第一句不提性别，只显示文字，不自动朗读。

### Validation copy

| 场景 | 中文 | English |
| --- | --- | --- |
| 空名字 | 还没有名字呢。 | I still need a name. |
| 名字被拒 | 这个名字我读不出来，换一个？ | I can't quite read that name. Try another? |
| 随机建议 | 要不要试试 {random}？ | How about {random}? |

### Unnamed state

- 小 row：`我还没有名字。给我取名？` / `I still don't have a name. Name me?`
- CTA：`取名` / `Name me`
- 临时关闭：`先不显示` / `Hide for now`；下次打开再出现；Me 入口保留。

### Talk gate

```text
先给我取个名字吧。
[取名]  [用随机名字]
```

```text
Let's give me a name first.
[Name me]  [Pick one for me]
```

### Talk status

| 状态 | 中文 | English |
| --- | --- | --- |
| typing | {name} 正在输入… | {name} is typing… |
| thinking | 她在想… / 他在想… | She's thinking… / He's thinking… |
| prefer_not_to_say | {name} 在想… | {name} is thinking… |

### Presence

每时段 3 条，加事件句；用 UI 语言；爱好用通用句，不直接插入 hobby 字串；偶尔用用户名字。

| 时段 | 中文 |
| --- | --- |
| 早上 | 早上好。今天想注意到什么？ / 早。慢慢来，先看看窗外。 / 早上好。我在等你今天的第一句话。 |
| 下午 | 下午好。累的话，歇一会儿。 / 下午好。今天有没有哪个瞬间想留下来？ / 下午了。我在这儿，不急。 |
| 晚上 | 晚上好。今天你留下了 {word}。 / 晚上好。今天过得怎么样？ / 天黑了。把今天的一点点留下来吧。 |
| 深夜 | 夜深了。今天也辛苦了。 / 该休息了。明天再慢慢来。 / 晚安。我会在这儿。 |
| 事件 | 刚才聊得不错。 / 你留下了 {word}。 / 你回来了。（超过 3 天没来） |

```text
Morning. What will you notice today?
Morning. Take your time. Look outside first.
Morning. I'm waiting for your first word today.

Afternoon. If you're tired, rest a little.
Afternoon. Any moment you want to keep today?
It's afternoon. I'm here. No rush.

Evening. You kept {word} today.
Evening. How was your day?
It's dark now. Keep a little of today.

It's late. You did enough today.
Time to rest. Tomorrow, take it slow.
Good night. I'll be here.

That was a good talk.
You kept {word}.
You're back.
```

### Ask

| 位置 | 文案 |
| --- | --- |
| label | `{name}` |
| greeting | 我是 {name}。关于英语，我们可以一起看看。一个词、一句话，或者为什么这样说。 |
| thinking | 让我看看… |
| empty | 你在好奇什么？ |

English greeting: `I'm {name}. Let's look at English together — a word, a sentence, or why something sounds the way it does.`

### Help me say it

| 位置 | 文案 |
| --- | --- |
| title | 想怎么说？ / Help me say it |
| subtitle | 用中文或零散的英语说，我帮你变成自然的英语。 / Say it in Chinese or rough English. I'll help you put it into natural English. |
| button | 找找说法 / Find the words |

这里的"我"指同伴。

### Me and companion page

| 位置 | 文案 |
| --- | --- |
| entry | 你的小伙伴 / Your companion |
| named subtitle | {name} · 和你一起学英语 / {name} · learning English with you |
| unnamed subtitle | 还没有名字 / No name yet |
| page sections | 今天 / 档案 / 编辑 |
| gender | 女孩子 / 男孩子 / 不想说 |
| hobby empty | 还没有填 / Not set |

### Opener fallback

| 场景 | 中文 | English |
| --- | --- | --- |
| word | 关于 {word}，你想说点什么？ | What do you want to say about {word}? |
| scene | 这个场景里，你最想说的是什么？ | What do you most want to say about this scene? |
| generic | 今天想聊点什么？ | What should we talk about today? |

### Random names

后端 20 个短、好读、跨语言的混合名字：

```text
Momo, Miso, Tofu, Bao, Bean, Mochi, Yuzu, Sesame,
Moss, Clover, Pebble, Sprout, Poppy, Sora,
Pip, Nori, Kiki, Lulu, Pepper, Button
```

- 食物 / 自然 / 通用混合。
- 跳过命名时分配并持久化。

## Technical Consequences

以下留给 spec / tickets，不在本轮展开：

- 新增 `CompanionProfile` 模型：name、gender、hobby、avatar key、voice key、`setup_dismissed_at`。
- 新增 Presence agent + 缓存（15 分钟 TTL）；后端返回 `template_key` + 参数，app 渲染。
- 新增 Opener agent（`sequence=1`、幂等）。
- 共享 persona 模块，覆盖 Talk / Help / Ask / Practice / Daily。
- 后端维护随机名字池，跳过时分配并持久化。
- 所有 i18n 从 "Milo" 改成 `{name}` 占位符。
- 代码重命名：`MiloMark`、`TalkAvatar`、`talk.miloName` → `Companion*`。
- `companion.jpg` 真人照片由小黑猫资产替换。
- `docs/ui-ux-design.md:19`、`docs/ui-design-system.md:143`、README 的 "Milo" 表述需要改。
- feature slug 已从 `milo-presence` 改为 `companion-presence`。
- 新增 ADR 0006 记录 Companion 模型。

## Rejected Alternatives

1. **固定角色 Milo + 真人肖像。** 否决：用户不能拥有它，也不能命名；与"用户命名自己的伙伴"方向冲突。
2. **单独一屏伙伴自我介绍。** 否决：多一屏、容易被跳过；首次卡内嵌在 Timeline 更轻。
3. **纯模板 Presence 台词。** 否决：无法判断"早上 / 上学"这类语境；改为 agent 输出结构化字段 + 模板。
4. **纯 AI 自由写 Presence 台词。** 否决：难控、难本地化、容易崩人设。
5. **recast + 默认折叠纠错。** 否决：用户决定保持现状。
6. **用户上传头像 / 自由捏脸。** 否决：审核、资产、安全成本过高；第一版固定 IP。
7. **性别驱动整套性格。** 否决：容易落入刻板印象；性别只影响自称和 pronoun。
8. **从年龄/时间推断用户生活。** 否决：违反 PRD 的边界。
9. **在 sign-in 收集用户年龄/性别，或做完整四步引导。** 否决：增加摩擦，且与猫的性别混淆。
10. **给用户加 display name 字段。** 否决：从对话里学更自然，也少一个字段。

## Open Questions

- 固定 TTS 声音是什么音色？中性/童声最安全，但 provider 能力未确认。
- Presence agent 的结构化输出 schema（time / activity / topic / mood 的枚举）和 `template_key` 命名。
- Presence 句库的英文校对。
- Daily Read 的引入句是 AI 还是模板。
- 6 张表情的 crop 质量、是否需要进一步放大。
- 代码重命名的时机和范围。
- 用户把小猫命名为 "Milo" 是否允许（当前倾向：允许，但产品不默认）。
- 用户长期跳过命名后，小 row 是否要允许彻底隐藏。

## Session Log

- **2026-11-25**：用户提出伙伴应该有"真实存在"的感觉；指出第一次进入没问候、第一次 Talk 没感觉。确认先讨论存在感，不进入 spec。
- **2026-11-25**：确认 Timeline 内嵌首次问候；Talk opener 用 AI；全部一起做（存在感 + 连续性 + persona）。
- **2026-11-25**：确认 opener 自动朗读；首次问候只出现一次；先记录讨论文档。
- **2026-11-25**：定位转向：用户命名自己的伙伴，不再使用固定 Milo。伙伴是用户原创小黑猫 IP；关系是同学/朋友；性别只影响自称；爱好自由输入；性格由 IP 固定。
- **2026-11-25**：确认首次流程：无名自我介绍 → 取名/性别/爱好 → 用新名字说第一句；跳过保持无名；进 Talk 再邀请；再次跳过才随机英文名；所有字段之后可改。
- **2026-11-25**：确认 Presence：Timeline 常驻 row；agent 输出结构化语境 + 模板渲染；只用明确数据；15 分钟 TTL；同一时段稳定；先显缓存再更新；失败回退中性模板。
- **2026-11-25**：确认 Talk persona：同学/朋友；英语是可靠范本；不确定先问；第一次 Talk 不重复自我介绍；爱好偶尔；幽默一点点；偶尔向用户学中文。
- **2026-11-25**：确认纠错保持现状（展开卡片 + 现有 prompt），不采用 recast + 折叠。
- **2026-11-25**：确认资产从 board 拆 6 张无文字表情；Milo 完全去掉；slug 改为 `companion-presence`。
- **2026-11-25**：确认 Onboarding 保持两页；不收集用户年龄/性别；猫只有名字必填；Me 页独立入口；老用户看一次首次卡；首次卡用猫的第一人称；小 row 可临时关闭。
- **2026-11-25**：确认 Presence 刷新：每次打开、15 分钟 TTL、同一时段稳定、先显缓存；渲染在 app；随机名字池在后端；只做呼吸动效。
- **2026-11-25**：确认安全：拒绝 + 随机名建议；英文+中文+保留名 blocklist；首次命名不读名字；名字/hobby 结构化进 user prompt。
- **2026-11-25**：确认 Learner Model 关系：只在相关时提旧经历；被纠正立刻更新；不说"我记得"；用户名字偶尔称呼。
- **2026-11-25**：确认品牌与文档：营销用 companion / 小伙伴；历史文档保留 + 加注；新增 ADR 0006；README hero 改为 companion。
- **2026-11-25**：确认文案语言分层：非 Talk 用 UI 语言，Talk 用英语 + 母语；Presence 用 UI 语言。
- **2026-11-25**：确认首次卡/设置页/第一句/未命名/Talk 门口/状态行文案；首次卡用温暖/害羞语气，第一人称 CTA。
- **2026-11-25**：确认 Presence 句库（每时段 3 条 + 事件）、爱好用通用句、偶尔用用户名字、超过 3 天说"你回来了"。
- **2026-11-25**：确认 Ask/Help/Me 文案；随机名字 20 个；审核错误文案。
- **2026-11-25**：发布实现 tickets #87–#94（T0–T7），讨论状态改为 `ready-for-prd`。
