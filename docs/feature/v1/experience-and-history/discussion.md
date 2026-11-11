# Experience 与 History - 需求讨论

**Status:** ready-for-prd
**Release:** v1
**Feature:** experience-and-history
**PRD:** #36

## 问题

Talk 已经能保存完整对话、纠正和标注，但这些交流还没有沉淀成用户能回访的个人经历。

用户结束一段有意义的对话后，当前只能看到一条 Talk 记录。用户无法快速找回：

- 自己分享过什么真实经历
- 这次实际练习了什么表达
- 这段经历关联了哪个 Word、Scene 或 Discovery
- 当时自己是怎么说的，后来有没有更自然的表达

现有 `memory_items` 中的 `experience` 类型是 Milo 的内部上下文，不适合直接作为 History：

- 相同文本会被合并，不能保留独立事件
- 没有生活经历与学习经历的区分
- 没有 Word／Scene／Conversation 的完整来源关系
- 用户不可见，也无法回访

本功能要在 Conversation 之上增加独立的 Experience 层，并提供用户可以回看的 History。

## 用户与结果

- 用户完成 Talk 后，系统自动提炼本次交流中值得保留的经历，不需要手工写总结。
- 用户可以区分“我真实经历过的事”和“我这次练习了什么”。
- 用户可以在 History 中按时间回看经历，并回到原始对话、Word 或 Scene。
- 在后续阶段，用户继续聊到相关话题时，Milo 可以使用已保存的经历作为上下文，但不得把练习或推测当成用户事实。
- 同一段对话多次补充时，经历会更新，而不是生成大量重复卡片。
- 用户删除账号后，相关经历、来源和后台任务一起清理。

可观察的成功标准：

- 一次包含真实分享的 Talk 结束后，History 出现对应的生活经历卡片。
- 一次只有练习或纠正的 Talk，最多出现学习经历，不出现生活经历。
- 从 History 卡片可以打开来源 Conversation 和关联的 Word／Scene。
- 后续阶段，Talk 能自然使用相关经历，但不宣称记住了用户未提供的信息。

## 当前体验

- Talk 从 Word 或 Scene 卡片的 `Talk about it` 进入：`app/lib/features/timeline/presentation/timeline_page.dart:325`、`:333`。
- 已有 Talk event 卡片可以重新打开同一段 Conversation：`timeline_page.dart:338`。
- 后端 Conversation 只接受 `focus_type = word | scene`：`backend/src/talk/schemas.py:77`。
- 当前没有独立的自由聊天入口。
- App 没有可靠的结束对话动作；Companion Memory 已经因此改为按 Talk 轮次抽取，而不能依赖 conversation end。
- `memory_items` 已经支持 `experience` 等类型，用于 Talk／Help 的内部上下文：`backend/src/memory/service.py`。
- App 当前没有 History 路由；Timeline 是原始活动流。
- 账号删除已覆盖 Conversation、Discovery、Memory 等账号数据。

## Scope

### In Scope

- 独立的 Experience 数据模型和来源关系。
- 独立 ExperienceAgent，异步于 Talk 回复运行。
- 从完整 Conversation 提炼生活经历和学习经历。
- 同一 Conversation 内的经历合并／更新。
- 证据校验：只能使用真实用户消息和真实关联对象。
- History 时间线页面。
- Experience 详情页／详情视图。
- 从 Experience 回到来源 Conversation、Word、Scene。
- 账号隔离、级联清理和失败恢复。
- 后台 Experience job 的持久化、去抖和重试。
- 为后续 Talk 上下文使用 Experience 预留读取能力。

### Out of Scope

- 自动修改 Soul profile 或 Soul items。
- 完整 Knowledge Graph。
- 按 Word／Scene 展开的完整成长树。
- 用户手工编辑、删除或合并 Experience。
- Experience 的复杂搜索、筛选、统计和成长分析。
- 在 History 中复制所有 Timeline 原始事件。
- 多用户协作、家庭账号或协助者权限。

## Required Behaviour

### Experience 分类

- `life`：用户明确分享的真实接触、事件、关系、地点或感受。
- `learning`：用户在这次交流中实际讨论、尝试、理解或练习的内容。
- 练习句、假设句、角色扮演和 AI 编造的内容只能成为 `learning`，不能成为 `life`。
- 没有足够依据时，两类经历都可以不生成。

### 提炼触发

- Talk 正常保存消息、纠正和标注后，更新该 Conversation 的 Experience job。
- Talk 响应不等待 ExperienceAgent。
- 同一 Conversation 只保留一个待处理 job；新 Turn 更新 `available_at`，避免连续多轮重复调用模型。
- 建议默认去抖 3 秒；如果用户继续发送消息，job 延后。
- 用户离开后，到期 job 仍由后台 worker 处理。

### ExperienceAgent

- 使用独立的 ExperienceAgent，不与 TalkAgent 共用结构化输出。
- 输入为完整 Conversation、focus、纠正、标注和消息序号。
- 输出最多一条生活经历和一条学习经历建议。
- 生活经历和学习经历分别包含：摘要、可选细节、证据消息序号、相关表达、置信度。
- Agent 不生成数据库 ID，不决定账号权限，不直接写数据库。
- 摘要使用用户母语；英文词语和表达保留英文原文。
- Agent 必须优先返回空结果，而不是猜测。

### 后端校验与保存

- 证据消息序号必须属于当前 Conversation。
- `life` 的证据必须来自用户消息。
- `related_terms` 必须能在消息、纠正或标注中找到依据。
- 后端负责把 Word／Scene／Discovery／Expression 绑定到真实 ID。
- 同一 `(conversation_id, kind)` 使用 upsert，更新原 Experience，不重复生成卡片。
- 低置信度候选应丢弃，阈值在技术设计中确定。
- 账号删除时清理 Experience、Experience Sources 和 Experience Jobs。

### History 读取

- History 只读取已保存的 Experience，不调用 Agent。
- 第一版按时间倒序展示 Experience，按日期分组。
- 卡片展示：摘要、类型、时间、关联 Word／Scene、来源 Conversation。
- Experience 详情展示：摘要、原话证据、英文提示或关联表达、来源对象、回到 Conversation 的入口。
- History 使用游标分页。
- App 第一版从 Timeline composer 的 `+` 菜单进入 History，不先改主导航。
- 如果 Experience 尚未提炼完成，History 可以暂时不显示该卡片；刷新后出现。

### 后续 Talk 使用

- 第一阶段先完成 Experience 保存和 History。
- Experience 质量稳定后，再把高置信度、相关经历注入 Talk／Help 上下文。
- 使用时必须区分真实生活经历和练习经历，不能把学习经历说成用户真实做过的事。
- 第一版不自动修改 Soul。

### 失败与恢复

- ExperienceAgent 超时或失败不影响 Talk。
- job 最多重试 3 次；失败后记录错误码，不记录正文。
- 同一 Conversation 后续有新 Turn 时，可以重新激活失败的 job。
- 没有可提炼内容时，job 标记完成但不生成 Experience。
- 证据不匹配或输出不合法时，丢弃候选，不生成半条经历。

## Edge and Failure Cases

- 用户只练习、不分享真实经历：只允许生成学习经历。
- 用户分享真实经历，但使用中文：允许生成生活经历，英文提示来自已有消息字段或关联表达。
- 用户在同一段 Talk 中补充同一事件的细节：更新同一张经历卡片。
- 用户在同一段 Talk 中讲两个明显不同的事件：第一版默认保留一条主要生活经历；其余暂不生成，后续再决定是否支持多条。
- 用户说“如果我去……”或进行角色扮演：不能生成生活经历。
- 用户纠正前面的说法：新 Experience 应反映最新一条有依据的表达；原始对话继续保留。
- Agent 返回不存在的消息序号：丢弃候选。
- Agent 返回无法匹配的 Word／Scene：只保留来源 Conversation，不伪造关联。
- job 在进程重启前未处理：下次 worker 启动后继续处理。
- 多个 API 实例同时运行 worker：需要数据库级 claim 或单 worker 限制；v1 先按单实例设计。
- 用户打开 History 时提炼仍未完成：显示空状态或旧数据，不阻塞页面。
- 账号删除：Experience、来源、job 都不可再读取，并按现有 30 天硬删除流程清理。

## Constraints and Dependencies

- 基于现有 Word／Scene 入口的 Conversation；当前没有自由聊天入口。
- App 当前不调用 Conversation end，因此不能依赖结束事件触发提炼。
- 使用现有 Pydantic AI／DeepSeek 配置；ExperienceAgent 是独立模型调用。
- 后台任务使用数据库 job + API 进程内 worker，不引入 Redis／Celery。
- 媒体、账号和删除生命周期复用现有后端结构。
- History 读取必须账号隔离。
- 日志不能记录完整对话、Experience 正文、图片或音频内容。
- 第一版为单 API 实例；多实例 worker claim 留到部署扩展时处理。

## Decisions

- **Experience 是独立实体，不复用 MemoryItem 作为用户历史。** Memory 用于 Milo 上下文；Experience 用于可追溯的用户历史。
- **采用独立 ExperienceAgent 异步提炼。** 不阻塞 Talk 回复，Prompt 和输出更专注于经历质量。
- **使用数据库 job，而不是只依赖进程内后台任务。** 进程重启后仍可恢复。
- **同一 Conversation 只有一个 job 并做去抖。** 避免每轮 Talk 都重复调用模型。
- **每段 Conversation 默认最多一条生活经历和一条学习经历。** 多轮内容更新同一卡片，避免 History 噪音。
- **生活经历和学习经历严格区分。** 练习、假设和角色扮演不能成为生活经历。
- **Agent 只输出候选，后端负责证据校验和真实 ID 绑定。**
- **History 第一版只展示 Experience，不复制 Timeline。**
- **History 从 Timeline 的 `+` 菜单进入。**
- **Experience 摘要使用母语，英文词语和表达保留英文。**
- **第一版不自动修改 Soul。**
- **先完成保存和 History，再把 Experience 注入 Talk 上下文。**
- **不做用户手工编辑／删除 Experience。**

## Open Questions

1. **History 卡片最终视觉形态。** 是纯列表、日期分组卡片，还是带更明显的生活／学习分段？  
   - 默认：日期分组 + 类型徽标 + 关联词 + 来源入口。  
   - 可在 UI 设计阶段解决，不阻塞 PRD。

2. **Experience 置信度阈值和重试上限。**  
   - 默认：低置信度丢弃，最多重试 3 次。  
   - 属于技术设计，需用真实对话校准。

3. **一段 Conversation 中两个明显不同生活事件的处理。**  
   - 默认：先保留一条主要生活经历。  
   - 如果真实使用中经常发生，再扩展为多条生活经历。

4. **Experience 注入 Talk 的时机和预算。**  
   - 默认：History 稳定后单独做第二阶段。  
   - 需要确定取多少条、如何排序，以及是否与 Memory 共用上下文预算。

5. **Experience 是否允许用户主动删除。**  
   - 第一版不做；用户删除 Conversation 或账号时由生命周期处理。  
   - 需要在后续数据管理功能中重新评估。

## Evidence

- `docs/prd-v1.0.md` 第 4、5.4、5.8、5.10、5.11 节：核心闭环、History、Soul、Experience。
- `docs/feature/v1/companion-memory/discussion.md`：Memory 是内部上下文，按 Talk 轮次抽取，App UI 不变。
- `docs/feature/v1/talk-and-conversation/discussion.md`：Conversation 保存与 Experience 提炼分离。
- `app/lib/features/timeline/presentation/timeline_page.dart`：Word／Scene Talk 入口和 Talk event 重开入口。
- `backend/src/talk/schemas.py`：Conversation focus 只支持 Word／Scene。
- `backend/src/memory/service.py`：现有 Memory 的抽取、去重和加权检索。
- `backend/src/models.py`：MemoryItem 和 Conversation 数据模型。

## Session Log

- 2026-11-11：确认 P0 已完成，下一阶段选择 Experience + History。确定 Experience 是独立于 Memory 的用户可见层，Talk 只从 Word／Scene 进入，当前没有自由聊天入口。
- 2026-11-11：比较了同步 TalkAgent 与独立异步 ExperienceAgent，用户选择独立异步方案。确定使用数据库 job、同一 Conversation 去抖、最多一条生活经历和一条学习经历、History 只展示 Experience、第一版不自动修改 Soul。
- 2026-11-11：确认 Experience 摘要使用中文、英文表达保留原文；History 首版从 Timeline 的 `+` 菜单进入；先完成 History，再把 Experience 注入 Talk 上下文。
- 2026-11-11：用户确认讨论结果，批准进入 PRD；PRD 发布于 #36。
