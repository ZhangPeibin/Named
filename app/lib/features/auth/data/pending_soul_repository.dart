import '../../../core/storage/key_value_storage.dart';

/// Keeps the initial Soul draft on this device until verification succeeds.
class PendingSoulRepository {
  const PendingSoulRepository(this._storage);

  static const _nativeLanguageKey = 'pending_soul.native_language';

  final KeyValueStorage _storage;

  Future<String?> readNativeLanguage() {
    return _storage.getString(_nativeLanguageKey);
  }

  Future<void> saveNativeLanguage(String value) {
    return _storage.setString(_nativeLanguageKey, value);
  }

  Future<void> clear() {
    return _storage.remove(_nativeLanguageKey);
  }
}
