import '../../domain/history_experience.dart';

class ExperienceSourceDto {
  const ExperienceSourceDto({required this.type, required this.id, this.quote});

  factory ExperienceSourceDto.fromJson(Map<String, dynamic> json) {
    return ExperienceSourceDto(
      type: json['source_type'] as String? ?? '',
      id: json['source_id'] as String? ?? '',
      quote: json['quote'] as String?,
    );
  }

  final String type;
  final String id;
  final String? quote;

  ExperienceSource toDomain() {
    return ExperienceSource(type: type, id: id, quote: quote);
  }
}

class HistoryExperienceDto {
  const HistoryExperienceDto({
    required this.id,
    required this.kind,
    required this.summary,
    this.detail,
    required this.confidence,
    required this.createdAt,
    required this.focusType,
    required this.focusId,
    required this.focusTitle,
    required this.conversationId,
    this.sources = const [],
  });

  factory HistoryExperienceDto.fromJson(Map<String, dynamic> json) {
    return HistoryExperienceDto(
      id: json['id'] as String? ?? '',
      kind: json['kind'] == 'learning'
          ? ExperienceKind.learning
          : ExperienceKind.life,
      summary: json['summary'] as String? ?? '',
      detail: json['detail'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      focusType: json['focus_type'] as String? ?? '',
      focusId: json['focus_id'] as String? ?? '',
      focusTitle: json['focus_title'] as String? ?? '',
      conversationId: json['conversation_id'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExperienceSourceDto.fromJson)
          .toList(),
    );
  }

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
  final List<ExperienceSourceDto> sources;

  HistoryExperience toDomain() {
    return HistoryExperience(
      id: id,
      kind: kind,
      summary: summary,
      detail: detail,
      confidence: confidence,
      createdAt: createdAt,
      focusType: focusType,
      focusId: focusId,
      focusTitle: focusTitle,
      conversationId: conversationId,
      sources: sources.map((source) => source.toDomain()).toList(),
    );
  }
}

class HistoryPageDto {
  const HistoryPageDto({required this.items, required this.nextCursor});

  factory HistoryPageDto.fromJson(Map<String, dynamic> json) {
    return HistoryPageDto(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HistoryExperienceDto.fromJson)
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );
  }

  final List<HistoryExperienceDto> items;
  final String? nextCursor;

  HistoryFeed toDomain() {
    return HistoryFeed(
      items: items.map((item) => item.toDomain()).toList(),
      nextCursor: nextCursor,
    );
  }
}
