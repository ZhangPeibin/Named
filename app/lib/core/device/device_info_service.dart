import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

abstract interface class DeviceInfoReader {
  Future<String> headerValue();
}

class DeviceInfoService implements DeviceInfoReader {
  DeviceInfoService({
    required SecureStorage secureStorage,
    required AppConfig config,
    DeviceInfoPlugin? deviceInfoPlugin,
    Future<PackageInfo> Function()? packageInfoLoader,
  }) : _secureStorage = secureStorage,
       _config = config,
       _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  static const headerName = 'deviceInfo';

  final SecureStorage _secureStorage;
  final AppConfig _config;
  final DeviceInfoPlugin _deviceInfoPlugin;
  final Future<PackageInfo> Function() _packageInfoLoader;

  Future<String>? _headerValueFuture;

  @override
  Future<String> headerValue() {
    return _headerValueFuture ??= _buildHeaderValue();
  }

  @visibleForTesting
  void resetCacheForTesting() {
    _headerValueFuture = null;
  }

  Future<String> _buildHeaderValue() async {
    final payload = <String, Object?>{
      'schema_version': 1,
      'platform': _platformLabel(),
      'environment': _config.environment.name,
      'install_id': await _readOrCreateInstallId(),
      ...await _appInfo(),
      ...await _platformDeviceInfo(),
    };

    return jsonEncode(_compact(payload));
  }

  Future<Map<String, Object?>> _appInfo() async {
    try {
      final packageInfo = await _packageInfoLoader();
      return {
        'app_name': _config.appName,
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
      };
    } catch (_) {
      return {'app_name': _config.appName};
    }
  }

  Future<Map<String, Object?>> _platformDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        return {
          'os_name': 'Android',
          'os_version': info.version.release,
          'sdk_int': info.version.sdkInt,
          'brand': info.brand,
          'manufacturer': info.manufacturer,
          'model': info.model,
          'device': info.device,
          'product': info.product,
          'hardware': info.hardware,
          'is_physical_device': info.isPhysicalDevice,
        };
      }

      if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        return {
          'os_name': info.systemName,
          'os_version': info.systemVersion,
          'brand': 'Apple',
          'manufacturer': 'Apple',
          'model': info.modelName.isNotEmpty ? info.modelName : info.model,
          'device': info.utsname.machine,
          'is_physical_device': info.isPhysicalDevice,
        };
      }
    } catch (_) {
      // Fall through to the generic platform payload below.
    }

    return {
      'os_name': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
    };
  }

  Future<String?> _readOrCreateInstallId() async {
    try {
      final existing = await _secureStorage.read(StorageKeys.deviceInstallId);
      if (existing != null && existing.trim().isNotEmpty) {
        return existing.trim();
      }

      final next = _newInstallId();
      await _secureStorage.write(StorageKeys.deviceInstallId, next);
      return next;
    } catch (_) {
      return null;
    }
  }

  String _newInstallId() {
    final random = Random.secure();
    final bytes = Uint8List.fromList([
      for (var i = 0; i < 16; i += 1) random.nextInt(256),
    ]);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _platformLabel() {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return Platform.operatingSystem;
  }

  Map<String, Object?> _compact(Map<String, Object?> value) {
    return Map.fromEntries(
      value.entries
          .map((entry) {
            final compactValue = _compactValue(entry.value);
            return MapEntry(entry.key, compactValue);
          })
          .where((entry) => entry.value != null),
    );
  }

  Object? _compactValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final sanitized = value.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
      return sanitized.isEmpty ? null : sanitized;
    }
    if (value is Map<String, Object?>) {
      final compacted = _compact(value);
      return compacted.isEmpty ? null : compacted;
    }
    if (value is Iterable) {
      final items = value.map(_compactValue).whereType<Object>().toList();
      return items.isEmpty ? null : items;
    }
    return value;
  }
}
