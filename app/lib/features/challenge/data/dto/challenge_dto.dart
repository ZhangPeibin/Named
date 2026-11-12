import '../../domain/challenge.dart';

class ChallengeItemDto {
  const ChallengeItemDto({
    required this.id,
    required this.discoveryId,
    required this.position,
    required this.visitedAt,
    required this.focusType,
    required this.focusId,
    required this.title,
    this.subtitle,
  });

  factory ChallengeItemDto.fromJson(Map<String, dynamic> json) {
    return ChallengeItemDto(
      id: json['id'] as String? ?? '',
      discoveryId: json['discovery_id'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      visitedAt: _date(json['visited_at']),
      focusType: json['focus_type'] as String? ?? 'word',
      focusId: json['focus_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
    );
  }

  final String id;
  final String discoveryId;
  final int position;
  final DateTime? visitedAt;
  final String focusType;
  final String focusId;
  final String title;
  final String? subtitle;

  ChallengeItem toDomain() {
    return ChallengeItem(
      id: id,
      discoveryId: discoveryId,
      position: position,
      visitedAt: visitedAt,
      focusType: focusType,
      focusId: focusId,
      title: title,
      subtitle: subtitle,
    );
  }
}

class ChallengeDto {
  const ChallengeDto({
    required this.id,
    required this.name,
    required this.plannedDays,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.createdAt,
    required this.totalCount,
    required this.visitedCount,
    required this.isDue,
    required this.items,
  });

  factory ChallengeDto.fromJson(Map<String, dynamic> json) {
    return ChallengeDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      plannedDays: (json['planned_days'] as num?)?.toInt() ?? 0,
      status: json['status'] == 'ended'
          ? ChallengeStatus.ended
          : ChallengeStatus.active,
      startedAt: _date(json['started_at']) ?? DateTime.now(),
      endedAt: _date(json['ended_at']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      visitedCount: (json['visited_count'] as num?)?.toInt() ?? 0,
      isDue: json['is_due'] == true,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChallengeItemDto.fromJson)
          .toList(),
    );
  }

  final String id;
  final String name;
  final int plannedDays;
  final ChallengeStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final int totalCount;
  final int visitedCount;
  final bool isDue;
  final List<ChallengeItemDto> items;

  Challenge toDomain() {
    return Challenge(
      id: id,
      name: name,
      plannedDays: plannedDays,
      status: status,
      startedAt: startedAt,
      endedAt: endedAt,
      createdAt: createdAt,
      totalCount: totalCount,
      visitedCount: visitedCount,
      isDue: isDue,
      items: items.map((item) => item.toDomain()).toList(),
    );
  }
}

DateTime? _date(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
