# ADR 0005: About items stay visible; learned memory stays internal

- **Status:** Accepted
- **Date:** 2026-11-23
- **Deciders:** 产品 / 客户端 / 后端
- **Related:** ADR 0004（部分被本决定取代）；ADR 0002（可见性部分恢复）；PRD §5.10、§5.11；#70、#71；`docs/feature/v2/learner-model/discussion.md`
- **2026-11-25 note:** The consumer named "Milo" is now the user-named companion. The visibility decisions below are unchanged; see ADR 0006 and `docs/feature/v2/companion-presence/discussion.md`.

## Context

ADR 0004 把 Soul / Memory 统一为 Learner Model，但同时决定 Memory 完全不可见，并移除 Me 页的 Soul notes 与会话级 `use_memory`。这与已经上线的 #64 以及 PRD §5.10 的「Soul 中的内容属于用户，用户必须能够查看与控制」直接冲突。

实际需要区分的不是「所有记忆可见 / 不可见」，而是：

- **about**：用户自己提供、或 AI 从明确陈述中提炼的原子事实（当前以 Soul notes 呈现）。
- **learned / boundary**：Milo 的学习观察与禁用边界，属于内部运行上下文。

用户需要能查看、纠正和删除 about；learned / boundary 不需要暴露。

## Decision

1. **about 保持可见、可改、可删。** 继续使用现有 Soul 入口展示、编辑、删除和新增，并标注来源；AI 提炼的 about 仍按 PRD §5.10 保持可见、可删。
2. **learned / boundary 保持内部。** 不提供 Memory 页面，也不在 Settings 提供 memory 开关。
3. **保留 `Conversation.use_memory`。** 它只门控 about / Soul 上下文，与 ADR 0002 和当前 `talk/service.py` 的行为一致；learned / boundary 上下文不受用户开关控制。
4. **只取代 ADR 0004 的决定 2、5、6。** ADR 0004 的决定 1、3、4、7 继续有效。
5. **不在本决定中改变 API 或 UI 契约。** 存储统一与 `SoulItem` 回填仍由后续 ticket 完成。

## Consequences

正向：

- 保留已上线的用户控制，避免静默回退 #64。
- 用户仍能纠正错误或过时的 about 内容。
- Milo 仍可使用内部 learned / boundary 记忆，不需要用户管理。

代价与风险：

- 需要长期维护 about 与 learned / boundary 的词汇和可见性边界。
- 用户仍无法查看或纠正 learned memory；这一风险继续由内部冲突规则、来源权威、置信度和过期承担。
- 文档中旧的「Memory 完全不可见」表述必须标注为已修订，否则会误导实现。

## Alternatives considered

1. **按 ADR 0004 完全隐藏记忆。** 否决：与 PRD §5.10 和已上线的 #64 冲突，且不是 Milo 个性化的必要条件。
2. **about 只读。** 否决：用户无法纠正错误内容，信任问题没有解决。
3. **直接改写 ADR 0004。** 否决：本仓库的 ADR 采用追加式记录（ADR 0001 的先例是标记 partially superseded），改写会丢失决策历史。
