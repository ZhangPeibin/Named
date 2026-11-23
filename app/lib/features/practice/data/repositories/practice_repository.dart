import '../../domain/practice_word.dart';
import '../api/practice_api.dart';

class PracticeRepository {
  const PracticeRepository(this._api);

  final PracticeApi _api;

  Future<PracticeWord> next() async {
    return (await _api.next()).toDomain();
  }

  Future<int> complete(String wordId) async {
    return (await _api.complete(wordId)).practiceCount;
  }

  Future<PracticeReply> reply({
    required String wordId,
    required String text,
    required List<PracticeTurn> history,
  }) async {
    return (await _api.reply(
      wordId: wordId,
      text: text,
      history: history,
    )).toDomain();
  }
}
