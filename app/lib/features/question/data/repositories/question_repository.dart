import '../../domain/question.dart';
import '../api/question_api.dart';

class QuestionRepository {
  const QuestionRepository(this._api);

  final QuestionApi _api;

  Future<QuestionThread> ask(String text, {QuestionContext? context}) async {
    final dto = await _api.ask(text, context: context);
    return dto.toDomain();
  }

  Future<List<QuestionThreadSummary>> fetchThreads() async {
    final items = await _api.fetchThreads();
    return items.map((item) => item.toDomain()).toList();
  }

  Future<QuestionThread> fetchThread(String threadId) async {
    final dto = await _api.fetchThread(threadId);
    return dto.toDomain();
  }

  Future<QuestionThread> followUp(String threadId, String text) async {
    final dto = await _api.followUp(threadId, text);
    return dto.toDomain();
  }

  Future<void> deleteThread(String threadId) {
    return _api.deleteThread(threadId);
  }

  Future<void> setFeedback({
    required String threadId,
    required String messageId,
    required String feedback,
  }) async {
    await _api.setFeedback(
      threadId: threadId,
      messageId: messageId,
      feedback: feedback,
    );
  }
}
