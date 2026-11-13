import '../../domain/daily_read.dart';
import '../api/daily_api.dart';

class DailyRepository {
  const DailyRepository(this._api);

  final DailyApi _api;

  Future<DailyRead> fetchToday({DateTime? date}) async {
    final dto = await _api.fetchToday(date: date);
    return dto.toDomain();
  }

  Future<DailyTranslation> fetchTranslation({DateTime? date}) async {
    final dto = await _api.fetchTranslation(date: date);
    return dto.toDomain();
  }

  Future<DailyCompletion> complete({int? durationSeconds}) async {
    final dto = await _api.complete(durationSeconds: durationSeconds);
    return dto.toDomain();
  }
}
