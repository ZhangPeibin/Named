# ADR 0006: The companion is user-named and separate from the Learner Model

- **Status:** Accepted
- **Date:** 2026-11-25
- **Deciders:** 产品 / 客户端 / 后端
- **Related:** ADR 0004（Learner Model）；ADR 0005（about 可见 / learned 内部）；PRD §5.10、§5.11；`docs/feature/v2/companion-presence/discussion.md`；`docs/feature/v2/learner-model/discussion.md`

## Context

当前产品把一个固定的虚拟角色 "Milo" 当作同伴：真人参考肖像、固定名字、固定身份。用户第一次进入时没有问候，第一次 Talk 也没有"她先开口"的感觉；后端 prompt 各自以 "Named's ..." 开头，没有共享人格。

v2 的方向改变了这个定位：

- 同伴应该属于用户，而不是所有人共享一个固定角色。
- 用户第一次进入时应该遇到一只还没有名字的小猫，并给它取名。
- 名字、性别、爱好是用户可设定的；外观第一版固定为原创小黑猫 IP。
- 同伴是"同学/朋友"，不是老师，也不是宠物。
- 同伴消费同一份 Learner Model，但自身档案不属于 Learner Model。

## Decision

1. **Companion 是独立实体。** 新增 `CompanionProfile`，account-scoped，随账号删除；不放进 `SoulProfile`。Soul 描述学习者，Companion 描述同伴。
2. **用户命名。** 同伴默认没有名字；用户取名，跳过则保持无名，进入 Talk 时再邀请；再次跳过才由后端分配随机英文/罗马化名。名字、性别、爱好都可以在 Me 页修改。
3. **性别只影响自称。** `female / male / prefer_not_to_say`；只影响 pronoun 和自我介绍，不改变整套语气，不切换 TTS 声音。
4. **性格由 IP 固定。** calm、a little lazy、always positive、quietly funny。用户不可改性格；个性化来自名字、性别、爱好和 learner context。
5. **首次流程。** Timeline 空状态出现无名小猫的自我介绍和取名邀请；设置只有名字必填。首次卡只出现一次；「以后再说」存服务端，之后收成一条小 row。
6. **Presence。** Timeline 顶部常驻一条安静的小猫台词。后端 agent 只输出结构化语境（time / activity / topic / mood），app 用 i18n 模板渲染。只用用户明确提供的数据，不做年龄/时间推断。15 分钟 TTL，同一时段稳定，先显缓存再更新。
7. **Opener。** 每次 Talk 由同伴先开口，AI 生成、懒加载、持久化为 `sequence=1`、幂等。第一次 Talk 不重复自我介绍；第一次命名句只显示文字，不自动朗读。
8. **纠错不变。** 纠错卡保持展开，Talk prompt 的 `Corrections` 段落保持现状；不采用 recast + 折叠。
9. **Milo 移除。** 产品、README、UI 文档、代码和 slug 不再使用 Milo；历史 ADR 和旧讨论保留原文，只加 revision note。

## Consequences

正向：

- 同伴成为用户拥有的角色，拥有感强于固定角色。
- Companion 与 Soul 职责清晰，记忆归属和删除边界明确。
- Presence 的文案与本地化集中在前端，后端只产出结构化语境。
- 纠错逻辑不动，避免一次同时改人格和教学行为。

代价与风险：

- 名字、性别、爱好都是用户可控输入，需要审核和 prompt injection 防护。
- 用户取的名字可能 TTS 读不出，需要"首次不读名字"等规避。
- 固定 IP 外观限制了用户对"我的伙伴"的想象，但换来了资产和审核成本可控。
- 首次卡、跳过、Talk 门口邀请构成多步状态，需要清晰的服务端状态。
- 历史文档中的 Milo 会继续存在，需要 revision note 避免误导。

## Alternatives considered

1. **保留固定角色 Milo + 真人肖像。** 否决：用户不能拥有它，也不能命名；与"用户命名自己的伙伴"方向冲突。
2. **把 Companion 放进 Soul。** 否决：Soul 是学习者；混在一起会让记忆、可见性和删除边界失真。
3. **收集用户年龄/性别，并做完整四步引导。** 否决：增加摩擦，且与同伴的性别混淆；母语已经足够。
4. **性别驱动整套性格。** 否决：容易落入刻板印象；性别只影响自称和 pronoun。
5. **纯模板或纯 AI 的 Presence。** 否决：纯模板无法判断语境，纯 AI 难控、难本地化；选择结构化语境 + 模板。
6. **recast + 默认折叠纠错。** 否决：用户决定保持现状。
7. **用户上传头像 / 自由捏脸。** 否决：审核、资产、安全成本过高；第一版固定 IP。
