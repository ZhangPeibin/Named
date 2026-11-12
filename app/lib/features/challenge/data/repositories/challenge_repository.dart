import '../../domain/challenge.dart';
import '../api/challenge_api.dart';

class ChallengeRepository {
  const ChallengeRepository(this._api);

  final ChallengeApi _api;

  Future<List<Challenge>> fetch() async {
    return (await _api.fetch()).map((dto) => dto.toDomain()).toList();
  }

  Future<Challenge> create({
    required String name,
    required int plannedDays,
    required List<String> discoveryIds,
  }) async {
    return (await _api.create(
      name: name,
      plannedDays: plannedDays,
      discoveryIds: discoveryIds,
    )).toDomain();
  }

  Future<Challenge> fetchById(String id) async {
    return (await _api.fetchById(id)).toDomain();
  }

  Future<Challenge> markVisited(String challengeId, String itemId) async {
    return (await _api.markVisited(challengeId, itemId)).toDomain();
  }

  Future<Challenge> end(String id) async {
    return (await _api.end(id)).toDomain();
  }
}
