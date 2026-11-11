class SentenceChunk {
  const SentenceChunk({
    required this.phrase,
    required this.meaningNative,
    this.exampleEn,
  });

  final String phrase;
  final String meaningNative;
  final String? exampleEn;
}

class SentenceKeyWord {
  const SentenceKeyWord({
    required this.word,
    required this.partOfSpeech,
    required this.meaningNative,
  });

  final String word;
  final String? partOfSpeech;
  final String meaningNative;
}

class SentenceDetail {
  const SentenceDetail({
    required this.original,
    required this.naturalEnglish,
    required this.explanationNative,
    required this.grammarNotes,
    required this.chunks,
    required this.keyWords,
  });

  final String original;
  final String naturalEnglish;
  final String explanationNative;
  final String grammarNotes;
  final List<SentenceChunk> chunks;
  final List<SentenceKeyWord> keyWords;
}
