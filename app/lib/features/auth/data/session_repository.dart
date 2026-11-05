import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/storage_keys.dart';

/// Minimal session storage — no product auth API.
class SessionRepository {
  const SessionRepository(this._secureStorage);

  final SecureStorage _secureStorage;

  Future<bool> hasSession() async {
    final accessToken = await _secureStorage.read(StorageKeys.accessToken);
    return accessToken != null && accessToken.trim().isNotEmpty;
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(StorageKeys.accessToken, accessToken);
    await _secureStorage.write(StorageKeys.refreshToken, refreshToken);
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
  }

  Future<String?> readRefreshToken() {
    return _secureStorage.read(StorageKeys.refreshToken);
  }
}
