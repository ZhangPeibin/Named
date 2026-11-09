import '../../../discover/data/dto/discover_dto.dart';
import '../../domain/word_shelf.dart';

class WordShelfItemDto {
  const WordShelfItemDto({
    required this.id,
    required this.label,
    required this.word,
    required this.audio,
    required this.discoveryCount,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.status,
    required this.reviewCount,
    required this.lastReviewedAt,
  });

  factory WordShelfItemDto.fromJson(Map<String, dynamic> json) {
    final rawWord = json['content'];
    final rawAudio = json['audio'];
    return WordShelfItemDto(
      id: json['id'] as String? ?? '',
      label: json['label_en'] as String? ?? '',
      word: rawWord is Map<String, dynamic>
          ? DiscoveredWordDto.fromJson(rawWord)
          : null,
      audio: rawAudio is Map<String, dynamic>
          ? WordAudioDto.fromJson(rawAudio)
          : null,
      discoveryCount: (json['discovery_count'] as num?)?.toInt() ?? 0,
      firstSeenAt: _parseDate(json['first_seen_at']),
      lastSeenAt: _parseDate(json['last_seen_at']),
      status: wordShelfStatusFromJson(json['status'] as String?),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      lastReviewedAt: _parseNullableDate(json['last_reviewed_at']),
    );
  }

  final String id;
  final String label;
  final DiscoveredWordDto? word;
  final WordAudioDto? audio;
  final int discoveryCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final WordShelfStatus status;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  WordShelfItem toDomain() {
    return WordShelfItem(
      id: id,
      label: label,
      word: word?.toDomain(),
      audio: audio?.toDomain(),
      discoveryCount: discoveryCount,
      firstSeenAt: firstSeenAt,
      lastSeenAt: lastSeenAt,
      status: status,
      reviewCount: reviewCount,
      lastReviewedAt: lastReviewedAt,
    );
  }
}

class WordsStatsDto {
  const WordsStatsDto({
    required this.total,
    required this.newThisWeek,
    required this.reviewedThisWeek,
    required this.usedInTalkThisWeek,
  });

  factory WordsStatsDto.fromJson(Map<String, dynamic> json) {
    return WordsStatsDto(
      total: (json['total'] as num?)?.toInt() ?? 0,
      newThisWeek: (json['new_this_week'] as num?)?.toInt() ?? 0,
      reviewedThisWeek: (json['reviewed_this_week'] as num?)?.toInt() ?? 0,
      usedInTalkThisWeek:
          (json['used_in_talk_this_week'] as num?)?.toInt() ?? 0,
    );
  }

  final int total;
  final int newThisWeek;
  final int reviewedThisWeek;
  final int usedInTalkThisWeek;

  WordsStats toDomain() {
    return WordsStats(
      total: total,
      newThisWeek: newThisWeek,
      reviewedThisWeek: reviewedThisWeek,
      usedInTalkThisWeek: usedInTalkThisWeek,
    );
  }
}

class WordShelfDto {
  const WordShelfDto({required this.stats, required this.words});

  factory WordShelfDto.fromJson(Map<String, dynamic> json) {
    return WordShelfDto(
      stats: WordsStatsDto.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      words: (json['words'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WordShelfItemDto.fromJson)
          .toList(),
    );
  }

  final WordsStatsDto stats;
  final List<WordShelfItemDto> words;

  WordShelf toDomain() {
    return WordShelf(
      stats: stats.toDomain(),
      words: words.map((item) => item.toDomain()).toList(),
    );
  }
}

DateTime _parseDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _parseNullableDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
