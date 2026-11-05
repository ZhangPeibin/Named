# 异常与可观测性

启动入口统一捕获 Flutter Framework、Platform Dispatcher 和未处理 Zone 异常，并转发
到 `ErrorReporter`。

模板默认使用 `ConsoleErrorReporter`，不会上传任何数据。接入 Sentry、Crashlytics 等
第三方平台时：

1. 实现 `ErrorReporter`。
2. 在 `main()` 中调用 `bootstrapApp(appErrorReporter: reporter)`；启动函数会使用同一实例
   覆盖 `errorReporterProvider`，Framework、Platform 和 Zone 异常都会进入该实例。
3. 保持业务代码只依赖接口，不直接调用第三方 SDK。
4. 配置隐私授权、采样率、用户信息脱敏和数据保留策略。

生产环境的默认 Logger 只输出 warning/error。Dio URL 中的 Token、密码、API Key、
OTP 等查询参数会被替换为 `[REDACTED]`。新增请求体日志时必须复用脱敏策略，禁止记录
Authorization Header、密码、验证码和完整个人信息。
