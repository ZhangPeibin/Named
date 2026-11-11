import '../../domain/sentence_detail.dart';
import '../api/sentence_api.dart';

class SentenceRepository {
  const SentenceRepository(this._api);

  final SentenceApi _api;

  Future<SentenceDetail> lookup(String text) async {
    return (await _api.lookup(text)).toDomain();
  }
}
