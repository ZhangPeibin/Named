# Learner Model - Requirements Discussion

**Status:** ready-for-prd
**Release:** v2
**Feature:** learner-model
**Related:** PRD #70；PRD §5.10、§5.11；ADR 0004（部分被 ADR 0005 取代）；ADR 0005；ADR 0002（被 ADR 0004 取代）；`docs/feature/v1/companion-memory/discussion.md`

> **2026-11-23 修订：** 可见性决定由 ADR 0005 取代。about 保持可见 / 可改 / 可删；learned 与 boundary 保持内部；`use_memory` 保留，且只门控 about。下方「Memory 完全不可见」「Me 页移除 Soul notes」「移除 use_memory」等表述为历史记录，不再适用。

## Problem

Milo 在 Talk 之外并不真正认识用户。Soul、Memory、ErrorPattern、Experience 是四套分散的存储，只有 Talk 消费；冲突没有处理；Daily Read、Practice、Discover、Challenge 既不产生也不消费长期上下文。

结果：产品看起来个性化，实际内容仍然是通用的。v2 要把这些统一成一个 **Learner Model**，让 LLM / Milo 知道「这个人是谁」，并在不同场景里做出针对性行为。

## Users and Outcomes

- **学习者**：通过 Milo 的行为感到被认识，而不是通过一个记忆管理界面。
- **Milo**：每次调用拿到有边界、有优先级、可信的 learner context。
- **产品**：内部可观测、可审计；账号删除时彻底清理；不向用户暴露记忆内容。

成功标准不是「用户能管理记忆」，而是：**Milo 越用越懂这个人，并在不同 surface 上体现出来。**

## Current Experience

- `SoulProfile`：母语、年龄、性别、`auto_extract`。
- `SoulItem`：onboarding 兴趣 + 用户手写 note；当前可见、可编辑。
- `MemoryItem`：Talk 每轮提炼；7 种 kind；用户不可见；只注入 Talk/Help。
- `ErrorPattern`：反复错误；隐藏；单独注入。
- `Experience`：生活/学习经历；History 可见；异步提炼。
- `Conversation.use_memory`：当前会话级记忆开关。

各 surface 的现状：

| Surface | 现在用的上下文 | 缺什么 |
| --- | --- | --- |
| Talk / Help | Soul + Memory + ErrorPattern + Experience | 四套存储重复、没有统一优先级 |
| Daily Read | 母语 + 最近 5 个词 + 轮换主题 | 没用兴趣、目标、偏好、经历；读完不回写 |
| Practice | 已保存词 + 练习次数 | 没用错误、目标、兴趣、相关经历 |
| Challenge | 用户显式选择的内容 | 没有基于 Milo 理解的推荐 |
| Discover | 用户输入 + 母语 | 没有长期兴趣引导 |

## Scope

### In Scope

- 一个统一的 **Learner Model**：`SoulProfile` + `MemoryItem`（about / learned / boundary）。
- `Experience` 保持独立。
- 每个 Milo capability 自己的 **Context Pack**。
- 第一阶段：Talk + Daily Read。
- Memory **完全不可见**：没有 Memory 页面、没有 Settings 开关、没有会话级开关。
- Talk 永远使用 Memory。
- 冲突处理：内部混合策略，保留 `superseded`；不询问用户。
- 从所有 surface 摄入信号并回写。
- 每个 word 输入产生 `word + time` 记忆；不做来源分类。
- Me 页移除 Soul notes / Memory；保留 profile、Settings、Sign out。

**2026-11-23 修订：** "Memory 完全不可见" 与 "Me 页移除 Soul notes" 由 ADR 0005 取代。about 保持可见 / 可改 / 可删；learned 与 boundary 保持内部；`use_memory` 保留。

### Out of Scope

- 实时语音对话。
- 完整记忆搜索 / 复杂编辑器。
- 用户查看、编辑、删除、确认记忆。
- Settings 中的记忆开关或清除入口。
- 会话级「使用记忆」开关。
- 书 / 视频 / 新闻导入（只是例子，不是 v2 输入来源）。
- 模型微调、掌握度评分、排行榜。

**2026-11-23 修订：** "用户查看、编辑、删除、确认记忆" 与 "会话级开关" 不再适用于 about；about 仍可见、可改、可删，`use_memory` 保留。learned 与 boundary 仍不可见。

## Required Behaviour

### 1. Learner Model

```text
SoulProfile
  account_id PK
  native_language
  age?
  gender?
  auto_extract

MemoryItem
  id PK
  account_id FK
  scope: about | learned | boundary
  kind
  text
  canonical_key
  source_type, source_id
  confidence, importance, mention_count
  first_seen_at, last_seen_at, last_used_at
  valid_from, valid_until
  status: active | superseded | conflicted
  superseded_by
  deleted_at        # internal tombstone only; no user delete UI

Experience（不变）
  kind, summary, detail, confidence
  + ExperienceSource

ErrorPattern（只做统计，不再单独注入 prompt）
```

`kind` 建议：

- about：`identity | relationship | interest | preference | goal | routine`
- learned：`learning_error | word | expression | topic`
- boundary：`do_not_mention | do_not_remember`

`source_type=user_input` 表示用户明确说过，具有最高权威；没有 `user_confirmed` / `user_edited`，因为 v2 不提供用户确认或编辑界面。

### 2. Memory 不可见

- 没有 Memory 页面，也没有 Me 里的 Memory 区块。
- 没有 Settings 里的「关闭记忆 / 清除记忆」。
- 没有会话级「使用记忆」开关；Talk 永远使用 Memory。
- `Conversation.use_memory` 在 v2 移除或恒为 true。
- 用户不能查看、编辑、删除、确认记忆；账号删除时级联清理。
- 内部管理 / 开发工具可以查看，但不属于 App 功能。

### 3. MemoryItem 的粒度

- **about** 使用原子事实：如「用户有一个女儿」「用户不喜欢被纠正发音」。
- **learned** 使用模式：如「用户经常漏第三人称单数」，原始句子放 source/example。
- **experience** 不进入 MemoryItem，交给 Experience 表。
- **topic** 是 learned 观察；重复出现且置信度足够高时，可自动升级为 about 的 interest。

### 4. Word 记忆

每个 word 输入都是一条 `word + time` 记忆：

```text
Word              共享内容：spelling / IPA / meaning
WordEncounter     每次输入：word_id, occurred_at, source_type=user_input
WordProgress      学习状态：attempts, used, practice
MemoryItem        聚合记忆：kind=word, mention_count, first/last seen
```

- Word 本身不是个人记忆。
- 「什么时候输入过这个词」是情节记忆。
- 「这个词见过三次但没用过」是语义记忆。
- 不做 book / video / news 来源分类。
- 不把每个 encounter 都塞进 prompt；ContextBuilder 只取最近/相关的少量。

### 5. 冲突规则（内部）

| 情况 | 处理 |
| --- | --- |
| 同义重复 | 合并，`mention_count + 1` |
| 明确否定 / 时间变化 | 旧条 `superseded`，新条 `active` |
| 用户明确陈述 vs AI 推断 | 用户优先，AI 条 `superseded` |
| AI vs AI，新条置信度足够高 | 旧条 `superseded` |
| AI vs AI，无法判断 | `conflicted`，不注入 prompt |
| 任意 `conflicted` | 不进入 Context Pack，等待后续信号重新评估 |
| 边界 | 最高优先级，过滤所有相关内容 |

旧条目保留为 `superseded`，不删除。整个冲突流程不询问用户。

### 6. Context Contract

| Milo 场景 | 读取 | 回写 |
| --- | --- | --- |
| Talk / Help | about + learning + moments + 最近对话 | 记忆、错误、话题、经历 |
| Daily Read | 兴趣/目标/偏好 + 水平 + 最近词/主题 + 相关经历 | 完成、主题、用到的词、跳过 |
| Practice | 反复错误、到期词、兴趣、相关经历 | 结果、提示使用、完成 |
| Challenge | 目标/兴趣 + 最近学习状态 | 到访、完成、跳过 |
| Discover | 兴趣（轻量） | 新词/场景 |

所有场景先应用 `boundary`；所有场景都读取 Memory，没有 opt-out。

### 7. 输入来源

- 用户输入 word
- 用户明确陈述（在 Talk 中）
- Talk 每轮
- Daily Read 完成 / 跳过
- Practice 结果
- Challenge 到访
- Discover（照片 / 文字）

书 / 视频 / 新闻只是用户举的例子，不是 v2 的输入来源。

## Architecture

```text
        Word input / Talk / Read / Practice / Challenge / Discover
                              │
                              ▼
                 ┌────────────────────────┐
                 │    Signal ingestion    │
                 │  normalize + conflict  │
                 └───────────┬────────────┘
                             │ write
                             ▼
                 ┌────────────────────────┐
                 │     Learner Model      │
                 │ SoulProfile            │
                 │ MemoryItem             │
                 │ WordEncounter          │
                 │ Experience             │
                 └───────────┬────────────┘
                             │ read
                             ▼
                 ┌────────────────────────┐
                 │   Context Builder      │
                 │ per capability + budget│
                 │ active + ranked        │
                 │ boundaries applied     │
                 └───────────┬────────────┘
                             │ context pack
                             ▼
                 ┌────────────────────────┐
                 │    Milo capabilities   │
                 │ Talk / Help            │
                 │ Read / Practice        │
                 │ Challenge / Discover   │
                 └───────────┬────────────┘
                             │
                             ▼
                 outcome signals ──► Signal ingestion
```

- 一个 Learner Model，多个 Context Pack。
- 原始表是 source of truth；给 LLM 的是生成的、限长的 `user.md` 表示。
- 没有用户可见的记忆界面；App 不提供记忆读写 API。

## Edge and Failure Cases

- 同一个事实重复出现：合并，`mention_count` 增加。
- 两条事实矛盾：内部按冲突规则处理；`conflicted` 不进 prompt，不询问用户。
- 用户说「不要提这个」：写 boundary，所有上下文过滤。
- 用户无法纠正错误记忆：只能依赖内部规则、来源权威、置信度、过期和对话中的明确否定。
- AI 失败：不影响用户操作；记忆写入 best-effort。
- 来源缺失：仍可保存；ContextBuilder 降级。
- Context 超预算：按优先级截断。
- 账号删除：级联清理所有记忆、经历和来源。
- 隐私/合规风险由产品接受；日志不得记录完整记忆内容。

## Constraints and Dependencies

- 后端 FastAPI + MySQL；App Flutter；共享 agent runtime。
- v2 为破坏性版本：ADR 0002 的「可见 / 可改 / 可关闭」被 ADR 0004 取代。
- 旧数据迁移或开发环境重置；迁移方案在技术设计中定。
- Prompt 字符预算：Talk 1800、Read 1200、Practice 1000，后续调整。
- 需要 feature flag / v2 开关，避免一次性替换。

## Decisions

- v2；LLM-first；一个 Learner Model，多个 Context Pack。
- `SoulItem` 合并进 `MemoryItem`；`Experience` 独立。
- Memory 完全不可见；没有 Memory UI、Settings 开关、会话级开关。
- Talk 永远使用 Memory；`Conversation.use_memory` 移除或恒为 true。
- Word 输入 = `word + time`；不做 book / video / news 来源分类。
- 冲突内部混合处理；保留 `superseded`；`conflicted` 不注入 prompt；不询问用户。
- 用户不能查看/编辑/删除/确认记忆；账号删除时级联清理。
- 第一阶段 Talk + Daily Read。
- Me 页移除 Soul notes / Memory；保留 profile、Settings、Sign out。
- ADR 0002 被 ADR 0004 取代。

**2026-11-23 修订：** ADR 0005 取代 ADR 0004 的决定 2、5、6。about 保持可见 / 可改 / 可删；learned 与 boundary 保持内部；`use_memory` 保留并只门控 about。

## Implementation Outline

| 阶段 | 内容 | 验收 |
| --- | --- | --- |
| 0 | v2 discussion + ADR 0004 + schema/contract | 文档可评审 |
| 1 | 迁移 + MemoryService + 冲突处理 + 移除 `use_memory` | 冲突/合并/边界/tombstone 测试通过 |
| 2 | ContextBuilder + Talk/Help 接入（永远使用 Memory） | Talk prompt 不再四段重复，回归测试通过 |
| 3 | Daily Read 个性化 + 回写 | Read 用上兴趣/目标/主题，完成后有信号 |
| 4 | Practice 个性化 + 回写 | 选词用错误/兴趣/经历 |
| 5 | Me 页清理：移除 Soul notes / 会话开关 | 无 Memory UI；profile/Settings 正常 |
| 6 | Challenge / Discover + 反馈调权 | 推荐和排序使用反馈 |
| 7 | 全量测试 + iOS 安装 | `make check` + 模拟器截图 |

**2026-11-23 修订：** 阶段 1 不再移除 `use_memory`；阶段 5 的 Me 页清理取消，保留 Soul notes 与会话开关。

## Open Questions（技术，不阻塞 PRD）

1. 旧数据迁移 vs 开发环境重置；推荐先写迁移，同时允许 dev reset。
2. LLM 的 about 提议规则：只能来自用户明确陈述，还是允许 AI 推断后自动 active。
3. 年龄/性别是否保留在 profile；推荐保留为可选，放在 Settings。
4. 冲突阈值、置信度阈值、Context 预算的具体数值。
5. `Conversation.use_memory` 是删除列，还是保留字段恒为 true；推荐删除。（2026-11-23 已解决：保留；只门控 about / Soul 上下文。）

## Migration Notes

- `0027_memory_lifecycle` 增加 `status`、`superseded_by`、`valid_from`、`valid_until`，并移除旧的唯一约束。
- `0028_memory_scope` 增加 `scope`，把未删除的 `soul_items` 回填为 `memory_items(scope='about')`。
- `/soul` 已改读写 `memory_items(scope='about')`；`0029_drop_soul_items` 删除旧的 `soul_items` 表。
- 开发环境允许 reset；生产环境通过 `make migrate` 应用。

## Evidence

- `backend/src/models.py`：`SoulProfile`、`MemoryItem`、`Experience`、`ErrorPattern`。
- `backend/src/talk/service.py`：Soul / Memory / Error / Experience 四段注入。
- `backend/src/memory/service.py`：MemoryItem 去重、排序、检索。
- `backend/src/soul/service.py`：onboarding 和手动写入。
- `app/lib/features/soul/presentation/soul_page.dart`：Me / Soul 页。
- `docs/adr/0002-soul-user-control.md`。
- `docs/adr/0004-learner-model.md`。
- `docs/feature/v1/companion-memory/discussion.md`。

## Session Log

- 2026-11-23：确认 v2；Soul/Memory 是 Milo 的上下文底座，不是用户记忆管理。决定统一 Learner Model、Experience 独立、混合冲突策略、保留 superseded。
- 2026-11-23：确认 Memory 完全不可见；没有 Memory 页面、Settings 开关、会话级开关；Talk 永远使用 Memory。Word 输入只记 `word + time`，不做书/视频/新闻来源分类。冲突内部处理，不询问用户。用户确认分析完成，状态设为 `ready-for-prd`。
- 2026-11-23：PRD 已发布为 GitHub Issue #70；新增 ADR 0004，ADR 0002 标记为被取代。
- 2026-11-23：ADR 0005 修订可见性：about 保持可见 / 可改 / 可删；learned 与 boundary 保持内部；`use_memory` 保留并只门控 about。拆分为 #71–#76。
