# 可选能力 Skill 规划

以下能力不进入主模板。后续分别实现为独立 Skill，由 Skill 负责依赖选择、平台配置、
代码接入、测试和回滚说明。

| Skill | 输入 | 主要产出 | 验收重点 |
| --- | --- | --- | --- |
| `add-push-notifications` | 厂商、环境、点击路由 | 推送初始化、Token 注册、通知路由 | 前后台、冷启动、权限拒绝 |
| `add-deep-links` | Domain、路由映射 | Android App Link、iOS Universal Link | 未安装、冷启动、非法 URL |
| `add-app-permissions` | 权限清单、用途文案 | 权限服务与平台声明 | 拒绝、永久拒绝、系统设置 |
| `add-analytics` | 平台、事件规范、Consent | Analytics Adapter、事件模型 | 隐私同意前不采集、参数脱敏 |
| `add-remote-config` | 平台、默认值、刷新策略 | Feature Flag Adapter 与缓存 | 离线默认值、类型校验、回滚 |
| `add-image-upload` | API、尺寸、格式限制 | 选择、压缩、上传与进度 | 权限、取消、大文件、失败重试 |
| `add-biometrics` | 保护场景、降级策略 | 生物识别服务与安全存储联动 | 无硬件、锁定、切换账号 |
| `add-offline-cache` | 数据类型、TTL、冲突策略 | 本地数据库、同步队列 | 断网、迁移、冲突、数据清理 |

每个 Skill 应先检查现有架构，优先覆盖 Provider 接入点，不直接改业务页面；完成后必须
运行格式化、Analyze、相关测试以及 Android/iOS 配置检查。
