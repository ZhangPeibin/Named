# Challenge - 需求讨论

**Status:** ready-for-prd
**Release:** v1
**Feature:** challenge
**PRD:** #44

## Problem

Named 已经支持 Discover、Talk、Words、Review、Experience 和 History，但用户还没有一种方式把若干真实发现组织成一轮持续学习。用户回到 App 时，缺少明确的 Continue 入口；内容会积累，但学习节奏没有被组织起来。

## Users and Outcomes

- 用户可以从已有 Word / Moment 发现中选择一组内容，创建一轮 Challenge。
- 用户可以设置名称和计划天数（2 天、一周或自定义）。
- 用户可以在 Timeline 看到一个明确的 Start / Continue 入口。
- 用户可以查看本轮内容、已查看进度，并继续探索。
- 用户可以手动结束本轮；周期只是计划，不自动结束。
- 结束 Challenge 不会删除 Word、Moment、Talk 或 Experience。
- 历史 Challenge 可以回看和再次使用。

## Scope

### In Scope

- Challenge 列表、创建和详情。
- 同一账号最多一个 active Challenge。
- 名称、计划天数、选择已有 Word/Moment Discovery。
- 从 Challenge 打开内容时标记为已查看。
- Timeline banner 和 Me 页面入口。
- 手动结束、历史回看。
- 账号隔离和删除生命周期。

### Out of Scope

- AI 自动推荐 Challenge 内容。
- 到期自动结束。
- 多个同时进行中的 Challenge。
- 掌握度、正确率、连续打卡、积分。
- Experience 直接加入 Challenge。
- 推送、提醒和通知。
- 系统模板或固定课程。

## Required Behaviour

- 创建 Challenge 时必须至少选择一个当前账号的 ready Discovery。
- 已有 active Challenge 时再次创建返回 409。
- 计划天数只用于计划和到期提示，不自动改状态。
- Challenge 详情显示内容清单、已查看数量和总数。
- 从 Challenge 打开内容时记录 `visited_at`。
- 进度只表示“打开过”，不表示掌握。
- 结束后仍可打开内容；历史 Challenge 可查看。
- 账号删除时清理 Challenge 和 Challenge items。

## Decisions

- **周期是计划，手动结束。** 到期只提示，不自动结束。
- **同时只允许一个进行中 Challenge。**
- **进度 = 从 Challenge 打开过内容。**
- **第一版内容只支持 Word + Moment 发现。**
- **不复制 Discovery 数据。** Challenge item 只关联 Discovery。
- **不表示掌握。** 进度文案明确是“已查看/已探索”。

## Evidence

- `docs/prd-v1.0.md` 5.7、6、8、9、10。
- `docs/ui-ux-design.md` Challenge 交互。
- `docs/prototypes/named.js` Challenge 列表、创建、详情与继续流程。

## Session Log

- 2026-11-12：确认 Challenge 第一版规则：周期只是计划，手动结束；最多一个进行中；打开内容计进度；内容为 Word + Moment；不支持 AI 推荐、自动结束或掌握度。
- 2026-11-12：Challenge 已实现并合并；PRD #44，ticket #45。
