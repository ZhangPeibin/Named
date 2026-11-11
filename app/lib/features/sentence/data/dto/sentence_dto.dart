import '../../domain/sentence_detail.dart';

class SentenceChunkDto {
  const SentenceChunkDto({
    required this.phrase,
    required this.meaningNative,
    this.exampleEn,
  });

  factory SentenceChunkDto.fromJson(Map<String, dynamic> json) {
    return SentenceChunkDto(
      phrase: json['phrase'] as String? ?? '',
      meaningNative: json['meaning_native'] as String? ?? '',
      exampleEn: json['example_en'] as String?,
    );
  }

  final String phrase;
  final String meaningNative;
  final String? exampleEn;

  SentenceChunk toDomain() {
    return SentenceChunk(
      phrase: phrase,
      meaningNative: meaningNative,
      exampleEn: exampleEn,
    );
  }
}

class SentenceKeyWordDto {
  const SentenceKeyWordDto({
    required this.word,
    required this.meaningNative,
    this.partOfSpeech,
  });

  factory SentenceKeyWordDto.fromJson(Map<String, dynamic> json) {
    return SentenceKeyWordDto(
      word: json['word'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String?,
      meaningNative: json['meaning_native'] as String? ?? '',
    );
  }

  final String word;
  final String? partOfSpeech;
  final String meaningNative;

  SentenceKeyWord toDomain() {
    return SentenceKeyWord(
      word: word,
      partOfSpeech: partOfSpeech,
      meaningNative: meaningNative,
    );
  }
}

class SentenceDetailDto {
  const SentenceDetailDto({
    required this.original,
    required this.naturalEnglish,
    required this.explanationNative,
    required this.grammarNotes,
    required this.chunks,
    required this.keyWords,
  });

  factory SentenceDetailDto.fromJson(Map<String, dynamic> json) {
    return SentenceDetailDto(
      original: json['original'] as String? ?? '',
      naturalEnglish: json['natural_english'] as String? ?? '',
      explanationNative: json['explanation_native'] as String? ?? '',
      grammarNotes: json['grammar_notes'] as String? ?? '',
      chunks: (json['chunks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SentenceChunkDto.fromJson)
          .toList(),
      keyWords: (json['key_words'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SentenceKeyWordDto.fromJson)
          .toList(),
    );
  }

  final String original;
  final String naturalEnglish;
  final String explanationNative;
  final String grammarNotes;
  final List<SentenceChunkDto> chunks;
  final List<SentenceKeyWordDto> keyWords;

  SentenceDetail toDomain() {
    return SentenceDetail(
      original: original,
      naturalEnglish: naturalEnglish,
      explanationNative: explanationNative,
      grammarNotes: grammarNotes,
      chunks: chunks.map((chunk) => chunk.toDomain()).toList(),
      keyWords: keyWords.map((word) => word.toDomain()).toList(),
    );
  }
}
