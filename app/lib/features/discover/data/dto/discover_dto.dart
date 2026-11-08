import '../../domain/discover.dart';

class DiscoveryCandidateDto {
  const DiscoveryCandidateDto({
    required this.id,
    required this.labelEn,
    required this.labelZh,
    required this.confidence,
    required this.reason,
    required this.selected,
  });

  factory DiscoveryCandidateDto.fromJson(Map<String, dynamic> json) {
    return DiscoveryCandidateDto(
      id: json['id'] as String? ?? '',
      labelEn: json['label_en'] as String? ?? '',
      labelZh: json['label_zh'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? '',
      selected: json['selected'] as bool? ?? false,
    );
  }

  final String id;
  final String labelEn;
  final String labelZh;
  final double confidence;
  final String reason;
  final bool selected;

  DiscoveryCandidate toDomain() {
    return DiscoveryCandidate(
      id: id,
      labelEn: labelEn,
      labelZh: labelZh,
      confidence: confidence,
      reason: reason,
      selected: selected,
    );
  }
}

class WordSenseDto {
  const WordSenseDto({
    required this.definitionEn,
    required this.definitionZh,
    required this.exampleEn,
    required this.exampleZh,
  });

  factory WordSenseDto.fromJson(Map<String, dynamic> json) {
    return WordSenseDto(
      definitionEn: json['definition_en'] as String? ?? '',
      definitionZh: json['definition_zh'] as String? ?? '',
      exampleEn: json['example_en'] as String? ?? '',
      exampleZh: json['example_zh'] as String? ?? '',
    );
  }

  final String definitionEn;
  final String definitionZh;
  final String exampleEn;
  final String exampleZh;

  WordSense toDomain() {
    return WordSense(
      definitionEn: definitionEn,
      definitionZh: definitionZh,
      exampleEn: exampleEn,
      exampleZh: exampleZh,
    );
  }
}

class WordChunkDto {
  const WordChunkDto({
    required this.phrase,
    required this.meaningZh,
    required this.exampleEn,
  });

  factory WordChunkDto.fromJson(Map<String, dynamic> json) {
    return WordChunkDto(
      phrase: json['phrase'] as String? ?? '',
      meaningZh: json['meaning_zh'] as String? ?? '',
      exampleEn: json['example_en'] as String? ?? '',
    );
  }

  final String phrase;
  final String meaningZh;
  final String exampleEn;

  WordChunk toDomain() {
    return WordChunk(
      phrase: phrase,
      meaningZh: meaningZh,
      exampleEn: exampleEn,
    );
  }
}

class VarietyNoteDto {
  const VarietyNoteDto({
    required this.kind,
    required this.descriptionZh,
    required this.us,
    required this.uk,
    required this.exampleEn,
  });

  factory VarietyNoteDto.fromJson(Map<String, dynamic> json) {
    return VarietyNoteDto(
      kind: json['kind'] as String? ?? 'usage',
      descriptionZh: json['description_zh'] as String? ?? '',
      us: json['us'] as String?,
      uk: json['uk'] as String?,
      exampleEn: json['example_en'] as String?,
    );
  }

  final String kind;
  final String descriptionZh;
  final String? us;
  final String? uk;
  final String? exampleEn;

  VarietyNote toDomain() {
    return VarietyNote(
      kind: kind,
      descriptionZh: descriptionZh,
      us: us,
      uk: uk,
      exampleEn: exampleEn,
    );
  }
}

class SceneExtensionDto {
  const SceneExtensionDto({
    required this.labelEn,
    required this.labelZh,
    required this.relationship,
  });

  factory SceneExtensionDto.fromJson(Map<String, dynamic> json) {
    return SceneExtensionDto(
      labelEn: json['label_en'] as String? ?? '',
      labelZh: json['label_zh'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
    );
  }

  final String labelEn;
  final String labelZh;
  final String relationship;

  SceneExtension toDomain() {
    return SceneExtension(
      labelEn: labelEn,
      labelZh: labelZh,
      relationship: relationship,
    );
  }
}

class DiscoveredWordDto {
  const DiscoveredWordDto({
    required this.spelling,
    required this.ipa,
    required this.pos,
    required this.senses,
    required this.grammar,
    required this.related,
    required this.chunks,
    required this.varietyNotes,
    required this.sceneExtensions,
  });

  factory DiscoveredWordDto.fromJson(Map<String, dynamic> json) {
    final rawIpa = json['ipa'];
    final ipa = <String, String>{};
    if (rawIpa is Map) {
      for (final entry in rawIpa.entries) {
        if (entry.value is String) {
          ipa[entry.key.toString()] = entry.value as String;
        }
      }
    }

    return DiscoveredWordDto(
      spelling: json['spelling'] as String? ?? '',
      ipa: ipa,
      pos: (json['pos'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      senses: (json['senses'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WordSenseDto.fromJson)
          .toList(),
      grammar: json['grammar'] as String? ?? '',
      related: (json['related'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      chunks: (json['chunks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WordChunkDto.fromJson)
          .toList(),
      varietyNotes: (json['variety_notes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VarietyNoteDto.fromJson)
          .toList(),
      sceneExtensions: _sceneExtensionsFromJson(
        json['scene_extensions'] as List<dynamic>? ?? const [],
      ),
    );
  }

  final String spelling;
  final Map<String, String> ipa;
  final List<String> pos;
  final List<WordSenseDto> senses;
  final String grammar;
  final List<String> related;
  final List<WordChunkDto> chunks;
  final List<VarietyNoteDto> varietyNotes;
  final List<SceneExtensionDto> sceneExtensions;

  DiscoveredWord toDomain() {
    return DiscoveredWord(
      spelling: spelling,
      ipa: ipa,
      pos: pos,
      senses: senses.map((sense) => sense.toDomain()).toList(),
      grammar: grammar,
      related: related,
      chunks: chunks.map((chunk) => chunk.toDomain()).toList(),
      varietyNotes: varietyNotes.map((note) => note.toDomain()).toList(),
      sceneExtensions: sceneExtensions
          .map((extension) => extension.toDomain())
          .toList(),
    );
  }
}

List<SceneExtensionDto> _sceneExtensionsFromJson(List<dynamic> raw) {
  final result = <SceneExtensionDto>[];
  for (final item in raw) {
    if (item is String) {
      result.add(
        SceneExtensionDto(labelEn: item, labelZh: '', relationship: ''),
      );
    } else if (item is Map<String, dynamic>) {
      result.add(SceneExtensionDto.fromJson(item));
    }
  }
  return result;
}

class SceneChunkDto {
  const SceneChunkDto({
    required this.phrase,
    required this.meaningNative,
    required this.exampleEn,
  });

  factory SceneChunkDto.fromJson(Map<String, dynamic> json) {
    return SceneChunkDto(
      phrase: json['phrase'] as String? ?? '',
      meaningNative: json['meaning_native'] as String? ?? '',
      exampleEn: json['example_en'] as String?,
    );
  }

  final String phrase;
  final String meaningNative;
  final String? exampleEn;

  SceneChunk toDomain() {
    return SceneChunk(
      phrase: phrase,
      meaningNative: meaningNative,
      exampleEn: exampleEn,
    );
  }
}

class SceneCorrectionDto {
  const SceneCorrectionDto({
    required this.original,
    required this.suggestion,
    required this.note,
  });

  factory SceneCorrectionDto.fromJson(Map<String, dynamic> json) {
    return SceneCorrectionDto(
      original: json['original'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  final String original;
  final String suggestion;
  final String note;

  SceneCorrection toDomain() {
    return SceneCorrection(
      original: original,
      suggestion: suggestion,
      note: note,
    );
  }
}

class ScenePayloadDto {
  const ScenePayloadDto({
    required this.naturalEnglish,
    required this.keyChunks,
    required this.keyWords,
    required this.correction,
  });

  factory ScenePayloadDto.fromJson(Map<String, dynamic> json) {
    final rawCorrection = json['correction'];
    return ScenePayloadDto(
      naturalEnglish: json['natural_english'] as String? ?? '',
      keyChunks: (json['key_chunks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SceneChunkDto.fromJson)
          .toList(),
      keyWords: (json['key_words'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      correction: rawCorrection is Map<String, dynamic>
          ? SceneCorrectionDto.fromJson(rawCorrection)
          : null,
    );
  }

  final String naturalEnglish;
  final List<SceneChunkDto> keyChunks;
  final List<String> keyWords;
  final SceneCorrectionDto? correction;

  ScenePayload toDomain() {
    return ScenePayload(
      naturalEnglish: naturalEnglish,
      keyChunks: keyChunks.map((chunk) => chunk.toDomain()).toList(),
      keyWords: keyWords,
      correction: correction?.toDomain(),
    );
  }
}

class SceneAudioDto {
  const SceneAudioDto({required this.url, required this.status});

  factory SceneAudioDto.fromJson(Map<String, dynamic> json) {
    return SceneAudioDto(
      url: json['url'] as String?,
      status: json['status'] as String? ?? 'unavailable',
    );
  }

  final String? url;
  final String status;

  SceneAudio toDomain() {
    return SceneAudio(url: url, status: status);
  }
}

class WordAudioDto {
  const WordAudioDto({required this.usUrl, required this.ukUrl});

  factory WordAudioDto.fromJson(Map<String, dynamic> json) {
    final us = json['us'];
    final uk = json['uk'];
    return WordAudioDto(
      usUrl: us is Map<String, dynamic> ? us['url'] as String? : null,
      ukUrl: uk is Map<String, dynamic> ? uk['url'] as String? : null,
    );
  }

  final String? usUrl;
  final String? ukUrl;

  WordAudio toDomain() {
    return WordAudio(usUrl: usUrl, ukUrl: ukUrl);
  }
}

class DiscoverDto {
  const DiscoverDto({
    required this.id,
    required this.inputText,
    required this.context,
    required this.inputLanguage,
    required this.status,
    required this.focusKind,
    required this.wordId,
    required this.candidates,
    required this.word,
    this.scene,
    required this.audio,
    this.sceneAudio,
    required this.needsConfirmation,
    required this.warnings,
  });

  factory DiscoverDto.fromJson(Map<String, dynamic> json) {
    final rawWord = json['word'];
    final rawScene = json['scene'];
    final rawAudio = json['audio'];
    final rawSceneAudio = json['scene_audio'];
    return DiscoverDto(
      id: json['id'] as String? ?? '',
      inputText: json['input_text'] as String?,
      context: json['context'] as String?,
      inputLanguage: json['input_language'] as String?,
      status: json['status'] as String? ?? 'needs_confirmation',
      focusKind: json['focus_kind'] as String?,
      wordId: json['word_id'] as String?,
      candidates: (json['candidates'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DiscoveryCandidateDto.fromJson)
          .toList(),
      word: rawWord is Map<String, dynamic>
          ? DiscoveredWordDto.fromJson(rawWord)
          : null,
      scene: rawScene is Map<String, dynamic>
          ? ScenePayloadDto.fromJson(rawScene)
          : null,
      audio: rawAudio is Map<String, dynamic>
          ? WordAudioDto.fromJson(rawAudio)
          : null,
      sceneAudio: rawSceneAudio is Map<String, dynamic>
          ? SceneAudioDto.fromJson(rawSceneAudio)
          : null,
      needsConfirmation: json['needs_confirmation'] as bool? ?? false,
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  final String id;
  final String? inputText;
  final String? context;
  final String? inputLanguage;
  final String status;
  final String? focusKind;
  final String? wordId;
  final List<DiscoveryCandidateDto> candidates;
  final DiscoveredWordDto? word;
  final ScenePayloadDto? scene;
  final WordAudioDto? audio;
  final SceneAudioDto? sceneAudio;
  final bool needsConfirmation;
  final List<String> warnings;

  Discovery toDomain() {
    return Discovery(
      id: id,
      inputText: inputText,
      context: context,
      inputLanguage: inputLanguage,
      status: status,
      focusKind: focusKind,
      wordId: wordId,
      candidates: candidates.map((candidate) => candidate.toDomain()).toList(),
      word: word?.toDomain(),
      scene: scene?.toDomain(),
      audio: audio?.toDomain(),
      sceneAudio: sceneAudio?.toDomain(),
      needsConfirmation: needsConfirmation,
      warnings: warnings,
    );
  }
}
