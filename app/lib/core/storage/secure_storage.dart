/// Abstraction over a secure key/value store such as `flutter_secure_storage`.
/// Use for tokens, credentials, and other sensitive values that should be
/// persisted using platform keystores instead of plain preferences.
abstract interface class SecureStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<bool> contains(String key);

  Future<void> delete(String key);

  Future<void> deleteAll();
}
