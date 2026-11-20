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
    this.theme,
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
  final String? theme;
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

  double get progress =>
      totalCount == 0 ? 0 : (visitedCount / totalCount).clamp(0.0, 1.0);

  bool get isComplete => totalCount > 0 && visitedCount >= totalCount;

  List<ChallengeItem> get todayFocus =>
      items.where((item) => !item.visited).take(3).toList(growable: false);

  DateTime get _startDay {
    final start = startedAt.toLocal();
    return DateTime(start.year, start.month, start.day);
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _startDay.add(Duration(days: plannedDays)).difference(today).inDays;
  }

  int get dayIndex {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = today.difference(_startDay).inDays + 1;
    if (day < 1) {
      return 1;
    }
    if (day > plannedDays) {
      return plannedDays;
    }
    return day;
  }

  int get practicedToday {
    final now = DateTime.now();
    var count = 0;
    for (final item in items) {
      final at = item.visitedAt?.toLocal();
      if (at == null) {
        continue;
      }
      if (at.year == now.year && at.month == now.month && at.day == now.day) {
        count += 1;
      }
    }
    return count;
  }
}
