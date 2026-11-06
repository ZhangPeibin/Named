import '../../../discover/data/dto/discover_dto.dart';
import '../../domain/timeline_item.dart';

sealed class TimelineItemDto {
  const TimelineItemDto();

  TimelineItem toDomain();
}

class TimelineWordItemDto extends TimelineItemDto {
  const TimelineWordItemDto({
    required this.id,
    required this.createdAt,
    required this.inputText,
    required this.wordId,
    required this.word,
    required this.audio,
    required this.conversationId,
  });

  factory TimelineWordItemDto.fromJson(Map<String, dynamic> json) {
    final rawWord = json['word'];
    final rawAudio = json['audio'];
    return TimelineWordItemDto(
      id: json['id'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      inputText: json['input_text'] as String?,
      wordId: json['word_id'] as String?,
      word: rawWord is Map<String, dynamic>
          ? DiscoveredWordDto.fromJson(rawWord)
          : null,
      audio: rawAudio is Map<String, dynamic>
          ? WordAudioDto.fromJson(rawAudio)
          : null,
      conversationId: json['conversation_id'] as String?,
    );
  }

  final String id;
  final DateTime createdAt;
  final String? inputText;
  final String? wordId;
  final DiscoveredWordDto? word;
  final WordAudioDto? audio;
  final String? conversationId;

  @override
  TimelineItem toDomain() {
    return TimelineWordItem(
      id: id,
      createdAt: createdAt,
      inputText: inputText,
      wordId: wordId,
      word: word?.toDomain(),
      audio: audio?.toDomain(),
      conversationId: conversationId,
    );
  }
}

class TimelineTalkItemDto extends TimelineItemDto {
  const TimelineTalkItemDto({
    required this.id,
    required this.createdAt,
    required this.conversationId,
    required this.title,
    required this.lastMessageRole,
    required this.lastMessageText,
    required this.messageCount,
  });

  factory TimelineTalkItemDto.fromJson(Map<String, dynamic> json) {
    final lastMessage =
        json['last_message'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return TimelineTalkItemDto(
      id: json['id'] as String? ?? '',
      createdAt: _parseDate(json['created_at']),
      conversationId: json['conversation_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Talk',
      lastMessageRole: lastMessage['role'] as String? ?? 'assistant',
      lastMessageText: lastMessage['text'] as String? ?? '',
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final DateTime createdAt;
  final String conversationId;
  final String title;
  final String lastMessageRole;
  final String lastMessageText;
  final int messageCount;

  @override
  TimelineItem toDomain() {
    return TimelineTalkItem(
      id: id,
      createdAt: createdAt,
      conversationId: conversationId,
      title: title,
      lastMessageRole: lastMessageRole,
      lastMessageText: lastMessageText,
      messageCount: messageCount,
    );
  }
}

class TimelineResponseDto {
  const TimelineResponseDto({required this.items, required this.nextCursor});

  factory TimelineResponseDto.fromJson(Map<String, dynamic> json) {
    final items = <TimelineItemDto>[];
    for (final raw in json['items'] as List<dynamic>? ?? const []) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final type = raw['type'];
      if (type == 'word') {
        items.add(TimelineWordItemDto.fromJson(raw));
      } else if (type == 'talk') {
        items.add(TimelineTalkItemDto.fromJson(raw));
      }
    }
    return TimelineResponseDto(
      items: items,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  final List<TimelineItemDto> items;
  final String? nextCursor;

  TimelinePage toDomain() {
    return TimelinePage(
      items: items.map((item) => item.toDomain()).toList(),
      nextCursor: nextCursor,
    );
  }
}

DateTime _parseDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
