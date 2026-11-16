import '../../domain/question.dart';
import '../api/question_api.dart';

class QuestionRepository {
  const QuestionRepository(this._api);

  final QuestionApi _api;

  Future<Question> ask(String text) async {
    final dto = await _api.ask(text);
    return dto.toDomain();
  }

  Future<List<Question>> fetchHistory() async {
    final items = await _api.fetchHistory();
    return items.map((item) => item.toDomain()).toList();
  }
}
