import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/dio_provider.dart';
import '../data/api/challenge_api.dart';
import '../data/repositories/challenge_repository.dart';
import '../domain/challenge.dart';

final challengeApiProvider = Provider<ChallengeApi>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockApi) {
    return MockChallengeApi();
  }
  return RemoteChallengeApi(ref.watch(dioProvider));
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(ref.watch(challengeApiProvider));
});

final challengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) {
  return ref.watch(challengeRepositoryProvider).fetch();
});

final challengeProvider = FutureProvider.autoDispose.family<Challenge, String>((
  ref,
  id,
) {
  return ref.watch(challengeRepositoryProvider).fetchById(id);
});

class ChallengeActions {
  const ChallengeActions(this._ref);

  final Ref _ref;

  Future<Challenge> create({
    required String name,
    required int plannedDays,
    required List<String> discoveryIds,
  }) async {
    final challenge = await _ref
        .read(challengeRepositoryProvider)
        .create(
          name: name,
          plannedDays: plannedDays,
          discoveryIds: discoveryIds,
        );
    _ref.invalidate(challengesProvider);
    return challenge;
  }

  Future<Challenge> markVisited(String challengeId, String itemId) async {
    final challenge = await _ref
        .read(challengeRepositoryProvider)
        .markVisited(challengeId, itemId);
    _ref.invalidate(challengesProvider);
    _ref.invalidate(challengeProvider(challengeId));
    return challenge;
  }

  Future<Challenge> end(String id) async {
    final challenge = await _ref.read(challengeRepositoryProvider).end(id);
    _ref.invalidate(challengesProvider);
    _ref.invalidate(challengeProvider(id));
    return challenge;
  }
}

final challengeActionsProvider = Provider<ChallengeActions>((ref) {
  return ChallengeActions(ref);
});
