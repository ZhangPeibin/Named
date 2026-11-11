enum ExperienceKind { life, learning }

class ExperienceSource {
  const ExperienceSource({required this.type, required this.id, this.quote});

  final String type;
  final String id;
  final String? quote;
}

class HistoryExperience {
  const HistoryExperience({
    required this.id,
    required this.kind,
    required this.summary,
    required this.detail,
    required this.confidence,
    required this.createdAt,
    required this.focusType,
    required this.focusId,
    required this.focusTitle,
    required this.conversationId,
    this.sources = const [],
  });

  final String id;
  final ExperienceKind kind;
  final String summary;
  final String? detail;
  final double confidence;
  final DateTime createdAt;
  final String focusType;
  final String focusId;
  final String focusTitle;
  final String conversationId;
  final List<ExperienceSource> sources;

  bool get isLife => kind == ExperienceKind.life;

  List<String> get expressions => sources
      .where((source) => source.type == 'expression')
      .map((source) => source.id)
      .toSet()
      .toList();
}

class HistoryFeed {
  const HistoryFeed({required this.items, required this.nextCursor});

  final List<HistoryExperience> items;
  final String? nextCursor;
}
