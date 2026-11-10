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
