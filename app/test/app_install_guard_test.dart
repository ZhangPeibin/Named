import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/startup/app_install_guard.dart';
import 'package:named/core/storage/key_value_storage.dart';
import 'package:named/core/storage/secure_storage.dart';

void main() {
  test('clears secure storage on first install then sets marker', () async {
    final prefs = _MemoryKeyValueStorage();
    final secure = _MemorySecureStorage()
      ..writeSync('access.token', 'stale-token');

    final guard = AppInstallGuard(
      keyValueStorage: prefs,
      secureStorage: secure,
    );

    await guard.ensureCurrentInstall();

    expect(await secure.read('access.token'), isNull);
    expect(await prefs.getBool(AppInstallGuard.installMarkerKey), isTrue);
  });

  test('no-ops when install marker already exists', () async {
    final prefs = _MemoryKeyValueStorage()
      ..setBoolSync(AppInstallGuard.installMarkerKey, true);
    final secure = _MemorySecureStorage()..writeSync('access.token', 'keep-me');

    await AppInstallGuard(
      keyValueStorage: prefs,
      secureStorage: secure,
    ).ensureCurrentInstall();

    expect(await secure.read('access.token'), 'keep-me');
  });
}

class _MemoryKeyValueStorage implements KeyValueStorage {
  final Map<String, Object> _values = {};

  void setBoolSync(String key, bool value) {
    _values[key] = value;
  }

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> _values = {};

  void writeSync(String key, String value) {
    _values[key] = value;
  }

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
