# DeviceInfo Header

所有 Dio 请求默认携带 `deviceInfo` Header，值为 JSON 字符串，Schema 版本为 1。

```json
{
  "schema_version": 1,
  "platform": "ios",
  "environment": "prod",
  "install_id": "base64url-id",
  "app_name": "My App",
  "app_version": "1.0.0",
  "build_number": "1",
  "package_name": "com.example.app",
  "os_name": "iOS",
  "os_version": "18.0",
  "brand": "Apple",
  "manufacturer": "Apple",
  "model": "iPhone",
  "device": "iPhone17,1",
  "is_physical_device": true
}
```

字段获取失败时会被省略，不能阻断请求。`install_id` 是安装级随机标识，不是广告 ID，
不得用来绕过用户隐私选择。后端新增字段必须保持向后兼容，并根据 `schema_version`
解析。
