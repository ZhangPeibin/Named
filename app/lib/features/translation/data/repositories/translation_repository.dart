import '../../domain/translation.dart';
import '../api/translation_api.dart';

class TranslationRepository {
  const TranslationRepository(this._api);

  final TranslationApi _api;

  Future<TranslationResult> translate(String text) async {
    return (await _api.translate(text)).toDomain();
  }
}
