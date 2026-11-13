import '../../domain/progress.dart';
import '../api/progress_api.dart';

class ProgressRepository {
  const ProgressRepository(this._api);

  final ProgressApi _api;

  Future<Progress> fetch() async {
    final dto = await _api.fetch();
    return dto.toDomain();
  }
}
