import '../../domain/word_shelf.dart';
import '../api/words_api.dart';

class WordsRepository {
  const WordsRepository(this._api);

  final WordsApi _api;

  Future<WordShelf> fetch() async {
    return (await _api.fetch()).toDomain();
  }

  Future<void> setKnown({required String wordId, required bool known}) {
    return _api.setKnown(wordId: wordId, known: known);
  }

  Future<void> markReviewed(String wordId) {
    return _api.markReviewed(wordId);
  }
}
