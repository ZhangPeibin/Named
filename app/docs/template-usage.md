# 模板创建约定

推荐通过 `init-flutter-app` Skill 创建项目。Skill 复制文件时必须读取根目录的
`.templateignore`，然后调用 `tool/setup_project.dart` 完成品牌和包名替换。

手工复制示例：

```bash
rsync -a --exclude-from=<template-dir>/.templateignore <template-dir>/ my_app/
```

复制后执行初始化脚本、`flutter pub get`、`dart run slang` 和 `make doctor`。

`config/prod.json`、签名文件、构建目录和本地 IDE 状态不能从模板复制。所有
`dart-define` 值都会进入客户端二进制，只能保存 API 地址、环境名和功能开关，不能
存放私钥、服务端 Secret 或无法公开的凭证。
