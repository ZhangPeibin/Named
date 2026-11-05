/// Small abstraction over a non-secure key/value store such as
/// `shared_preferences`. Repositories and services should depend on this
/// interface so the underlying engine can be swapped or faked in tests.
abstract interface class KeyValueStorage {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<int?> getInt(String key);

  Future<void> setInt(String key, int value);

  Future<bool?> getBool(String key);

  Future<void> setBool(String key, bool value);

  Future<bool> containsKey(String key);

  Future<void> remove(String key);

  Future<void> clear();
}
