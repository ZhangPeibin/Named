import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../data/dto/auth_code_dto.dart';
import '../data/session_repository.dart';
import '../domain/initial_soul.dart';
import 'auth_providers.dart';

enum AuthStatus { signedOut, signedIn }

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(secureStorageProvider));
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthStatus> {
  @override
  Future<AuthStatus> build() async {
    final hasSession = await ref.read(sessionRepositoryProvider).hasSession();
    return hasSession ? AuthStatus.signedIn : AuthStatus.signedOut;
  }

  Future<AuthCodeDto> requestCode(String email) {
    return ref.read(authApiProvider).requestCode(email);
  }

  Future<void> verify({
    required String email,
    required String code,
    InitialSoul? initialSoul,
  }) async {
    final session = await ref
        .read(authApiProvider)
        .verify(email: email, code: code, initialSoul: initialSoul);
    await ref.read(sessionRepositoryProvider).saveAccessToken(session.token);
    await ref.read(pendingSoulRepositoryProvider).clear();
    state = const AsyncData(AuthStatus.signedIn);
  }

  Future<void> signOut() async {
    await ref.read(sessionRepositoryProvider).clearSession();
    await ref.read(pendingSoulRepositoryProvider).clear();
    state = const AsyncData(AuthStatus.signedOut);
  }

  Future<void> handleSessionExpired() async {
    await ref.read(sessionRepositoryProvider).clearSession();
    state = const AsyncData(AuthStatus.signedOut);
  }
}
