import '../../domain/history_experience.dart';
import '../api/history_api.dart';

class HistoryRepository {
  const HistoryRepository(this._api);

  final HistoryApi _api;

  Future<HistoryFeed> fetch({String? before}) async {
    return (await _api.fetch(before: before)).toDomain();
  }

  Future<HistoryExperience> fetchExperience(String id) async {
    return (await _api.fetchExperience(id)).toDomain();
  }
}
