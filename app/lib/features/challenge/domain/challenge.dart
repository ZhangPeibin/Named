enum ChallengeStatus { active, ended }

class ChallengeItem {
  const ChallengeItem({
    required this.id,
    required this.discoveryId,
    required this.position,
    required this.visitedAt,
    required this.focusType,
    required this.focusId,
    required this.title,
    this.subtitle,
  });

  final String id;
  final String discoveryId;
  final int position;
  final DateTime? visitedAt;
  final String focusType;
  final String focusId;
  final String title;
  final String? subtitle;

  bool get visited => visitedAt != null;
}

class Challenge {
  const Challenge({
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
  final List<ChallengeItem> items;

  bool get isActive => status == ChallengeStatus.active;
}
