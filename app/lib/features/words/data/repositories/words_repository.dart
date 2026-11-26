import '../../domain/word_shelf.dart';
import '../api/words_api.dart';

class WordsRepository {
  const WordsRepository(this._api);

  final WordsApi _api;

  Future<WordShelf> fetch() async {
    return (await _api.fetch()).toDomain();
  }

  Future<WordShelfItem> lookup(String text, {String level = 'full'}) async {
    return (await _api.lookup(text, level: level)).toDomain();
  }

  Future<WordShelfItem> fetchDetails(String wordId) async {
    return (await _api.fetchDetails(wordId)).toDomain();
  }

  Future<bool> addToShelf(String wordId) {
    return _api.addToShelf(wordId);
  }

  Future<void> setKnown({required String wordId, required bool known}) {
    return _api.setKnown(wordId: wordId, known: known);
  }

  Future<void> markReviewed(String wordId) {
    return _api.markReviewed(wordId);
  }

  Future<void> markAttempt({required String wordId, required String text}) {
    return _api.markAttempt(wordId: wordId, text: text);
  }

  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
    String? ipa,
    String? syllables,
    List<String> vowels = const [],
    List<String> consonants = const [],
    String? phonics,
  }) {
    return _api.saveFromTalk(
      label: label,
      meaningZh: meaningZh,
      partOfSpeech: partOfSpeech,
      grammar: grammar,
      exampleEn: exampleEn,
      ipa: ipa,
      syllables: syllables,
      vowels: vowels,
      consonants: consonants,
      phonics: phonics,
    );
  }
}
