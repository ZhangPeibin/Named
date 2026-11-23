# Practice - 需求讨论

**Status:** ready-for-prd
**Release:** v1
**Feature:** practice
**Related:** ADR 0003、PRD §5.5、`docs/ui-ux-design.md`

## 问题

已保存的词仍然只是词典条目。旧 Review 3 被删除（ADR 0003），因为它考的是回忆和英→中翻译，不是使用；它没有让词进入用户自己的表达。

核心问题不是「记不住」，而是：

- 用户记得词义，却不知道在自己的生活里怎么用；
- 词没有被用户真正说过，因此不「属于」用户；
- 现有 `needs_review / attempted / known` 只描述回忆状态，不描述使用能力。

Practice 的目标是**通过使用获得所有权**，不是复习记忆。

## 用户与结果

**用户：** 已经保存过词、希望把词用起来的英语学习者。

**可观察的结果：**

- 用户围绕一个已保存的词，用自己的生活内容完成一次真实交流；
- 该词产生一条 Practice 完成记录，并在之后的随机抽取中降低权重；
- 用户在 Trail 上看到累计完成的 Practice 次数。

## 当前体验

- Review 功能已删除（提交 `5edfde7`），Timeline 没有复习／练习入口。
- `WordProgress` 目前只有 `self_known_at`、`attempt_count`、`last_attempt_at`、`used_count`、`last_used_at`。
- 词内容已包含 IPA、音频、英文／中文释义、例句；发现记录保存用户原始输入。
- Timeline 底部固定 Trail card 显示 Words / Talks / Reads 三个统计。

## 范围

### In Scope

- 只练已保存的 **Words**。
- 用户主动开始，不绑定时间、不做每日任务、不做到期调度。
- 每次 Practice 抽一个词，按顺序走完五个节点。
- 每个节点只有一个 Next，流程单向。
- 五节点全部完成后，该词的 `practice_count` +1，Trail 的 Practice 次数 +1。
- 选择采用加权随机：练得越多，被抽中的概率越低。

### Out of Scope

- Moment、整句、未保存的 Discover 词。
- 每日固定一组、完成态、连续天数、分数、掌握度。
- 发音评分。
- 连读提示（v1 只做 IPA、重音、音频）。
- 把 Practice 中的对话写入 Talk 的 `used_count`。

## Required Behaviour

### 入口

- Timeline 底部 Trail card 增加第四个可点击统计 **Practices**。
- 数字 = 账号下所有 `WordProgress.practice_count` 之和。
- 点击后开始一次 Practice，由系统随机抽词。
- 没有已保存词时不显示该入口。

### 选词

- 在账号全部已保存词中做加权随机。
- 权重 `1 / (1 + practice_count)`；未练过的词权重最高。
- 不硬性排除任何词；旧词仍可能回来，但概率更低。
- 抽中后返回该词的内容、音频、用户原始上下文，以及 3 个来自其他已保存词的干扰项。

### 五个节点

1. **Understand**：只读。显示用户原始上下文、英文释义、一个例句。Next。
2. **Pronounce**：显示 IPA 与重音，播放 US/UK 音频；用户录音并回放。麦克风被拒时降级为只听。Next。
3. **Recognise**：播放单词音频，用户从 3–4 个选项中选出该词；选错直接显示答案。Next。
4. **Recall**：显示英文释义与原始上下文，用户输入或说出该词；提示阶梯为「首字母 → IPA → 音频 → 答案」。Next。
5. **Use in Conversation**：围绕该词与用户上下文进行两轮 AI 对话；AI 先回应意思，再给出一句更自然的说法，不替换用户原句。第二轮后 Next。

### 完成与计数

- 只有第五个节点完成后的 Next 才调用完成接口。
- 中途退出、返回、失败都不增加计数。
- 完成后 Trail 数字立即刷新。

## Edge and Failure Cases

- **没有已保存词**：不显示 Practice 入口；接口返回稳定错误。
- **只有 1–2 个词**：Recognise 减少选项，不阻塞。
- **缺少 IPA 或音频**：跳过对应提示，用可用线索继续。
- **麦克风被拒**：Pronounce 只听；Recall 仍可输入文字。
- **AI 或网络失败**：停在当前节点显示重试，不前进、不计数。
- **练习中途词被删除**：显示错误并回到入口。
- **重复完成请求**：同一 session 只允许完成一次，避免重复计数。

## Constraints and Dependencies

- 后端新增 `practice` 模块；`WordProgress` 增加 `practice_count`、`last_practiced_at`；通过 Alembic 迁移。
- 复用现有词内容、音频、发现上下文与 STT。
- 现有 `needs_review / attempted / known` 与 `used_count` 保持不变；Practice 不改写它们。
- AI 对话使用共享 agent runtime 与超时／重试策略。

## Decisions

- **只练 Words。** 句子的复习形态未定义，先不扩大范围。
- **不绑定时间。** 用户随时可练；没有每日剂量、到期或完成态。这取代 ADR 0003 中「每日固定一组 + 完成态」的部分。
- **一次一个词，走完五节点。** 保证一次 session 有明确的开始与结束。
- **加权随机，不排除旧词。** Review & Repeat 由概率自然产生，而不是时间表。
- **权重读 `practice_count`。** 只统计完整完成的 Practice，不混入 Talk 的 `used_count`。
- **入口放在 Trail card。** 与现有统计同一位置；不新增 Timeline 卡片。
- **五节点单向、只有 Next。** 不跳过、不重试、不设自评分支；中途退出不计入次数。
- **完成才计数。** 部分完成不提高权重。

## Open Questions

1. 权重公式的具体常数与是否需要下限；当前默认 `1 / (1 + practice_count)`，实现后按体感调整。
2. 「连读」内容如何生成；v1 不做，后续可让 AI 在 Pronounce 节点生成。
3. Recall 的语音输入是否默认开启，还是只保留文字输入 + 可选麦克风。
4. Use in Conversation 的 AI recast 质量与失败兜底话术。

## Evidence

- `docs/adr/0003-remove-review-practice.md`：删除 Review，Practice 作为独立功能。
- `backend/src/models.py:140`：`WordProgress` 现有字段。
- `backend/src/discovery/service.py:647`：词状态排序。
- `backend/src/progress/service.py`：Trail 统计来源。
- `app/lib/features/timeline/presentation/widgets/timeline_progress_card.dart`：Trail card。
- `app/lib/features/challenge/presentation/challenge_practice_page.dart`：录音、回放、STT 的现有实现。
- `docs/ui-ux-design.md` §Practice (pending)。

## Session Log

- 2026-11-22：确认只练已保存 Words；不绑定时间；一次一个词走完 Understand → Pronounce → Recognise → Recall → Use；加权随机且练得越多概率越低；Practice 完成次数作为权重与 Trail 统计；入口放在 Trail card；五节点单向只有 Next；只有全部完成才计数。用户确认默认值，要求直接拆 ticket 并开始实现。
