import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/secure_storage_provider.dart';
import '../data/session_repository.dart';

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

  /// Local-only sign-in that writes fake tokens for router / interceptor demos.
  Future<void> devSignIn() async {
    await ref
        .read(sessionRepositoryProvider)
        .saveSession(
          accessToken: 'dev-access-token',
          refreshToken: 'dev-refresh-token',
        );
    state = const AsyncData(AuthStatus.signedIn);
  }

  Future<void> signOut() async {
    await ref.read(sessionRepositoryProvider).clearSession();
    state = const AsyncData(AuthStatus.signedOut);
  }

  Future<void> handleSessionExpired() async {
    await ref.read(sessionRepositoryProvider).clearSession();
    state = const AsyncData(AuthStatus.signedOut);
  }
}
