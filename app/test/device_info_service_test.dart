import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/device/device_info_service.dart';
import 'package:named/core/network/device_info_interceptor.dart';
import 'package:named/core/storage/secure_storage.dart';
import 'package:named/core/storage/storage_keys.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('reuses a stable install_id across header builds', () async {
    final storage = _MemorySecureStorage();
    final service = DeviceInfoService(
      secureStorage: storage,
      config: const AppConfig(
        appName: 'Test App',
        environment: AppEnvironment.dev,
        apiBaseUrl: 'https://api.test',
      ),
      packageInfoLoader: () async => PackageInfo(
        appName: 'Test App',
        packageName: 'com.example.test',
        version: '1.0.0',
        buildNumber: '1',
      ),
    );

    final first =
        jsonDecode(await service.headerValue()) as Map<String, dynamic>;
    service.resetCacheForTesting();
    final second =
        jsonDecode(await service.headerValue()) as Map<String, dynamic>;

    expect(first['install_id'], isA<String>());
    expect(first['install_id'], isNotEmpty);
    expect(second['install_id'], first['install_id']);
    expect(
      await storage.read(StorageKeys.deviceInstallId),
      first['install_id'],
    );
    expect(first['app_name'], 'Test App');
    expect(first['schema_version'], 1);
  });

  test('interceptor attaches deviceInfo header', () async {
    const reader = _FakeDeviceInfoReader('{"schema_version":1}');
    const interceptor = DeviceInfoInterceptor(reader);
    final options = RequestOptions(path: '/ping');

    await interceptor.onRequest(options, _NoOpRequestHandler());

    expect(
      options.headers[DeviceInfoService.headerName],
      '{"schema_version":1}',
    );
  });
}

class _FakeDeviceInfoReader implements DeviceInfoReader {
  const _FakeDeviceInfoReader(this._value);

  final String _value;

  @override
  Future<String> headerValue() async => _value;
}

class _NoOpRequestHandler extends RequestInterceptorHandler {
  @override
  void next(RequestOptions options) {}
}

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<bool> contains(String key) async => _values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _values.clear();
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
