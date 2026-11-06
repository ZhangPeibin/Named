import '../../discover/domain/discover.dart';

sealed class TimelineItem {
  const TimelineItem({required this.createdAt});

  final DateTime createdAt;
}

class TimelineWordItem extends TimelineItem {
  const TimelineWordItem({
    required this.id,
    required super.createdAt,
    required this.inputText,
    required this.wordId,
    required this.word,
    required this.audio,
    required this.conversationId,
  });

  final String id;
  final String? inputText;
  final String? wordId;
  final DiscoveredWord? word;
  final WordAudio? audio;
  final String? conversationId;

  TimelineWordItem copyWith({String? conversationId}) {
    return TimelineWordItem(
      id: id,
      createdAt: createdAt,
      inputText: inputText,
      wordId: wordId,
      word: word,
      audio: audio,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}

class TimelineTalkItem extends TimelineItem {
  const TimelineTalkItem({
    required this.id,
    required super.createdAt,
    required this.conversationId,
    required this.title,
    required this.lastMessageRole,
    required this.lastMessageText,
    required this.messageCount,
  });

  final String id;
  final String conversationId;
  final String title;
  final String lastMessageRole;
  final String lastMessageText;
  final int messageCount;

  TimelineTalkItem copyWith({
    String? lastMessageRole,
    String? lastMessageText,
    int? messageCount,
  }) {
    return TimelineTalkItem(
      id: id,
      createdAt: createdAt,
      conversationId: conversationId,
      title: title,
      lastMessageRole: lastMessageRole ?? this.lastMessageRole,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}

class TimelinePage {
  const TimelinePage({required this.items, required this.nextCursor});

  final List<TimelineItem> items;
  final String? nextCursor;
}
