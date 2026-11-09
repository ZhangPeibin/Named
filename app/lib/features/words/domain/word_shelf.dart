import '../../discover/domain/discover.dart';

enum WordShelfStatus { needsReview, growing, known }

WordShelfStatus wordShelfStatusFromJson(String? value) {
  return switch (value) {
    'known' => WordShelfStatus.known,
    'growing' => WordShelfStatus.growing,
    _ => WordShelfStatus.needsReview,
  };
}

class WordShelfItem {
  const WordShelfItem({
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

  final String id;
  final String label;
  final DiscoveredWord? word;
  final WordAudio? audio;
  final int discoveryCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final WordShelfStatus status;
  final int reviewCount;
  final DateTime? lastReviewedAt;
}

class WordsStats {
  const WordsStats({
    required this.total,
    required this.newThisWeek,
    required this.reviewedThisWeek,
    required this.usedInTalkThisWeek,
  });

  final int total;
  final int newThisWeek;
  final int reviewedThisWeek;
  final int usedInTalkThisWeek;
}

class WordShelf {
  const WordShelf({required this.stats, required this.words});

  final WordsStats stats;
  final List<WordShelfItem> words;
}
