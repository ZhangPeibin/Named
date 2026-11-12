import '../../domain/assistant_intent.dart';
import '../api/assistant_api.dart';

class AssistantRepository {
  const AssistantRepository(this._api);

  final AssistantApi _api;

  Future<AssistantIntentResult> route(String text) async {
    final dto = await _api.route(text);
    return dto.toDomain();
  }
}
