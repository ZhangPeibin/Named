import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/providers/secure_storage_provider.dart';
import 'package:named/core/storage/secure_storage.dart';
import 'package:named/core/storage/storage_keys.dart';
import 'package:named/features/auth/data/session_repository.dart';
import 'package:named/features/auth/providers/auth_notifier.dart';

void main() {
  test('dev sign-in writes tokens and marks session signed in', () async {
    final storage = _MemorySecureStorage();
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(authNotifierProvider.future),
      AuthStatus.signedOut,
    );

    await container.read(authNotifierProvider.notifier).devSignIn();

    expect(container.read(authNotifierProvider).value, AuthStatus.signedIn);
    expect(await storage.read(StorageKeys.accessToken), 'dev-access-token');
    expect(await storage.read(StorageKeys.refreshToken), 'dev-refresh-token');
  });

  test('session repository reports hasSession from access token', () async {
    final storage = _MemorySecureStorage();
    final repository = SessionRepository(storage);

    expect(await repository.hasSession(), isFalse);
    await repository.saveSession(accessToken: 'token', refreshToken: 'refresh');
    expect(await repository.hasSession(), isTrue);
  });
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
