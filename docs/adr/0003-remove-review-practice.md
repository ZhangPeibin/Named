# ADR 0003: Remove Review 3; Practice is a separate feature

- **Status:** Accepted
- **Date:** 2026-11-21
- **Deciders:** 产品 / 客户端 / 后端
- **Related:** ADR 0001（被本决定部分取代）；PRD §4、§5.5；`docs/ui-ux-design.md`

## Context

ADR 0001 把「先产出、再看提示与答案」的循环命名为 Review 3，并把它作为闭环的单一返回入口。实现后暴露了两个问题：

1. **命名冲突。** PRD 的 Review 指「回看自己的历史对话与经历」；Review 3 实际是「有反馈的产出练习」。同一个词指两件事，界面无法解释自己在干什么。
2. **机制不成立。** 取词只是「从未复习过优先 + 3 个上限」，没有每日剂量与完成态；线索是中文释义，练习仍是中→英翻译；自评不入库。它更像练习，而不是复习。

产品决定：**删除当前 Review 功能，重新设计 Practice**；Challenge 是独立的挑战流程，不并入 Practice。

## Decision

1. 删除 Review 3 的功能面：页面、入口卡片、路由、命令提示、助手 intent、i18n 与测试。
2. 删除后端 review 语义：`POST /words/{id}/reviewed`、`review_count`、`last_reviewed_at`、`growing` 状态与 `reviewed_this_week` 统计；迁移删除两列。
3. Practice 将作为新功能实现，不在这里复用 Review 组件：每日固定一组条目、先产出、提示阶梯、自评入库、有完成态。
4. Challenge 保持独立：它有自己的轮次、内容选择与练习步骤，不属于 Practice 功能。

## Consequences

正向：

- 词汇状态回到如实表达：`needs_review`（未练习或超过 7 天）、`attempted`（7 天内试过）、`known`（用户自评会了）。
- 移除假「今天」与无效配额，避免在错误的机制上继续堆 UI。
- 为 Practice 留出干净的数据模型空间（练习会话、条目结果）。

代价与风险：

- 删除后 Timeline 暂时没有「回到词」的入口，直到 Practice 上线；这是有意的过渡状态。
- 删除列会丢弃开发环境的复习计数（未上线，可接受）。
- ADR 0001 中关于 Review 3 的描述失效，需要以本 ADR 为准。

## Alternatives considered

1. **保留 Review 3，只改名叫 Practice。** 否决：机制（无每日剂量、无结果写回、翻译线索）仍需重做，保留旧页面会限制设计。
2. **把 Challenge 的练习步骤并入 Practice。** 否决：Challenge 是挑战，有自己的轮次与内容选择；合并会让两个概念都变模糊。
