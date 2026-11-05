class DiscoveryCandidate {
  const DiscoveryCandidate({
    required this.id,
    required this.labelEn,
    required this.labelZh,
    required this.confidence,
    required this.reason,
    required this.selected,
  });

  final String id;
  final String labelEn;
  final String labelZh;
  final double confidence;
  final String reason;
  final bool selected;
}

class WordSense {
  const WordSense({
    required this.definitionEn,
    required this.definitionZh,
    required this.exampleEn,
    required this.exampleZh,
  });

  final String definitionEn;
  final String definitionZh;
  final String exampleEn;
  final String exampleZh;
}

class WordChunk {
  const WordChunk({
    required this.phrase,
    required this.meaningZh,
    required this.exampleEn,
  });

  final String phrase;
  final String meaningZh;
  final String exampleEn;
}

class VarietyNote {
  const VarietyNote({
    required this.kind,
    required this.descriptionZh,
    required this.us,
    required this.uk,
    required this.exampleEn,
  });

  final String kind;
  final String descriptionZh;
  final String? us;
  final String? uk;
  final String? exampleEn;
}

class SceneExtension {
  const SceneExtension({
    required this.labelEn,
    required this.labelZh,
    required this.relationship,
  });

  final String labelEn;
  final String labelZh;
  final String relationship;
}

class DiscoveredWord {
  const DiscoveredWord({
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

  final String spelling;
  final Map<String, String> ipa;
  final List<String> pos;
  final List<WordSense> senses;
  final String grammar;
  final List<String> related;
  final List<WordChunk> chunks;
  final List<VarietyNote> varietyNotes;
  final List<SceneExtension> sceneExtensions;

  WordSense? get primarySense => senses.isEmpty ? null : senses.first;
}

class Discovery {
  const Discovery({
    required this.id,
    required this.inputText,
    required this.context,
    required this.inputLanguage,
    required this.status,
    required this.focusKind,
    required this.wordId,
    required this.candidates,
    required this.word,
    required this.needsConfirmation,
    required this.warnings,
  });

  final String id;
  final String? inputText;
  final String? context;
  final String? inputLanguage;
  final String status;
  final String? focusKind;
  final String? wordId;
  final List<DiscoveryCandidate> candidates;
  final DiscoveredWord? word;
  final bool needsConfirmation;
  final List<String> warnings;

  bool get isReady => status == 'ready';
  bool get isScene => focusKind == 'scene';
}
