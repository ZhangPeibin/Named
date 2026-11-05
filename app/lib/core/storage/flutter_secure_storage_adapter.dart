import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

/// `SecureStorage` backed by `flutter_secure_storage`, with platform defaults
/// suitable for most apps. Callers can inject a custom `FlutterSecureStorage`
/// (e.g. with custom Keychain/Keystore options) in tests or for advanced setups.
class FlutterSecureStorageAdapter implements SecureStorage {
  FlutterSecureStorageAdapter({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  // Android: from flutter_secure_storage v10+, EncryptedSharedPreferences is
  // deprecated; the plugin falls back to its own ciphers automatically.
  // iOS: `first_unlock` allows reads in the background after the user has
  // unlocked the device at least once since boot.
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<bool> contains(String key) => _storage.containsKey(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
