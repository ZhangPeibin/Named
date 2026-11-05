import '../../domain/timeline_item.dart';
import '../api/timeline_api.dart';

class TimelineRepository {
  const TimelineRepository(this._api);

  final TimelineApi _api;

  Future<TimelinePage> fetch({
    int limit = 30,
    String? before,
    String? type,
  }) async {
    return (await _api.fetch(
      limit: limit,
      before: before,
      type: type,
    )).toDomain();
  }
}
