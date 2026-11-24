# ADR 0004: The Learner Model is for Milo, not a user memory feature

- **Status:** Accepted (partially superseded by ADR 0005)
- **Date:** 2026-11-23
- **Deciders:** 产品 / 客户端 / 后端
- **Related:** ADR 0002（被本决定取代）；ADR 0005（取代本决定第 2、5、6 条）；PRD §5.10、§5.11；`docs/feature/v2/learner-model/discussion.md`

## Context

v1 的 Soul 与 Memory 是两套并行能力：`SoulItem` 由 onboarding 和用户手写产生，`MemoryItem` 由 Talk 自动提炼；两者都只部分进入 prompt。ADR 0002 要求 Soul 对用户可见、可改、可关闭，并为会话提供 `use_memory` 开关。

v2 的产品方向变了：Soul / Memory 的第一消费者是 **Milo / LLM**。它们存在的目的是让 Milo 知道「这个人是谁」，并在 Talk、Daily Read、Practice、Challenge 等场景里做出针对性行为。用户不需要管理记忆；记忆不应成为产品主界面。

## Decision

1. **一个 Learner Model。** `SoulProfile` 保存 profile；`MemoryItem` 统一保存 about / learned / boundary；`Experience` 保持独立。
2. **Memory 完全不可见。** 不提供 Memory 页面、Settings 开关、会话级 `use_memory` 开关；Talk 永远使用 Memory。
3. **Word 输入是 `word + time` 记忆。** 不做 book / video / news 来源分类；`WordEncounter` 保留每次输入，`MemoryItem(kind=word)` 做聚合。
4. **冲突在内部处理。** 明确否定/时间变化自动 supersede；AI 无法判断时标记 `conflicted` 并不注入 prompt；保留 `superseded` 历史；不询问用户。
5. **Me 页不再暴露 Soul notes / Memory。** 保留 profile、Settings 和 Sign out。
6. **移除 `Conversation.use_memory`**（或恒为 true），因为用户不再有会话级记忆开关。
7. **ADR 0002 被本 ADR 取代。**

> 第 2、5、6 条由 ADR 0005 取代；其余决定继续有效。

## Consequences

正向：

- 一个统一的 Learner Model，所有 Milo capability 共享同一份理解。
- 不再需要维护用户可见的记忆界面，减少交互摩擦。
- 从所有 surface 摄入信号，Milo 在 Talk 之外也能个性化。

代价与风险：

- 用户无法查看、纠正、删除错误记忆；可靠性依赖内部冲突规则、来源权威、置信度和过期。
- 隐私与合规风险由产品接受；账号删除必须彻底清理记忆与来源。
- 错误或过时的记忆可能持续影响 Milo，需要内部审计与可观测性。
- ADR 0002 的「可见 / 可改 / 可关闭」承诺不再成立，需要在 v2 文档中明确。

## Alternatives considered

1. **保留可见 Memory 页面。** 否决：产品目标是把记忆用于 Milo，而不是让用户管理记忆；页面会变成维护负担。
2. **只去掉页面，保留 Settings 开关 / 会话开关。** 否决：用户明确选择不需要任何记忆控制；Talk 永远使用 Memory。
3. **继续保留 Soul 与 Memory 两套存储。** 否决：重复、冲突和四段 prompt 问题无法从根上解决。
