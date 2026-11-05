import '../../domain/discover.dart';
import '../api/discover_api.dart';

class DiscoverRepository {
  const DiscoverRepository(this._api);

  final DiscoverApi _api;

  Future<Discovery> createText({required String text, String? context}) async {
    return (await _api.createText(text: text, context: context)).toDomain();
  }

  Future<Discovery> fetch(String discoveryId) async {
    return (await _api.fetch(discoveryId)).toDomain();
  }

  Future<Discovery> focus({
    required String discoveryId,
    String? candidateId,
    String? labelEn,
    bool wholeScene = false,
  }) async {
    return (await _api.focus(
      discoveryId: discoveryId,
      candidateId: candidateId,
      labelEn: labelEn,
      wholeScene: wholeScene,
    )).toDomain();
  }
}
