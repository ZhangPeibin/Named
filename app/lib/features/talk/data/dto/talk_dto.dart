import '../../domain/talk.dart';

class MessageCorrectionDto {
  const MessageCorrectionDto({
    required this.original,
    required this.suggestion,
    required this.note,
  });

  factory MessageCorrectionDto.fromJson(Map<String, dynamic> json) {
    return MessageCorrectionDto(
      original: json['original'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  final String original;
  final String suggestion;
  final String note;

  MessageCorrection toDomain() {
    return MessageCorrection(
      original: original,
      suggestion: suggestion,
      note: note,
    );
  }
}

class MessageAnnotationDto {
  const MessageAnnotationDto({
    required this.text,
    required this.kind,
    required this.meaningZh,
  });

  factory MessageAnnotationDto.fromJson(Map<String, dynamic> json) {
    return MessageAnnotationDto(
      text: json['text'] as String? ?? '',
      kind: json['kind'] as String? ?? 'word',
      meaningZh: json['meaning_zh'] as String? ?? '',
    );
  }

  final String text;
  final String kind;
  final String meaningZh;

  MessageAnnotation toDomain() {
    return MessageAnnotation(text: text, kind: kind, meaningZh: meaningZh);
  }
}

class TalkAudioDto {
  const TalkAudioDto({required this.url, required this.status});

  factory TalkAudioDto.fromJson(Map<String, dynamic> json) {
    return TalkAudioDto(
      url: json['url'] as String?,
      status: json['status'] as String? ?? 'unavailable',
    );
  }

  final String? url;
  final String status;

  TalkAudio toDomain() {
    return TalkAudio(url: url, status: status);
  }
}

class HelpSuggestionDto {
  const HelpSuggestionDto({
    required this.naturalEnglish,
    required this.note,
    required this.alternatives,
    required this.audio,
  });

  factory HelpSuggestionDto.fromJson(Map<String, dynamic> json) {
    final rawAudio = json['audio'];
    return HelpSuggestionDto(
      naturalEnglish: json['natural_english'] as String? ?? '',
      note: json['note'] as String?,
      alternatives: (json['alternatives'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      audio: rawAudio is Map<String, dynamic>
          ? TalkAudioDto.fromJson(rawAudio)
          : null,
    );
  }

  final String naturalEnglish;
  final String? note;
  final List<String> alternatives;
  final TalkAudioDto? audio;

  HelpSuggestion toDomain() {
    return HelpSuggestion(
      naturalEnglish: naturalEnglish,
      note: note,
      alternatives: alternatives,
      audio: audio?.toDomain(),
    );
  }
}

class TalkMessageDto {
  const TalkMessageDto({
    required this.id,
    required this.role,
    required this.text,
    required this.corrections,
    required this.annotations,
    this.nativeText,
    this.audio,
  });

  factory TalkMessageDto.fromJson(Map<String, dynamic> json) {
    final rawAudio = json['audio'];
    return TalkMessageDto(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      text: json['text'] as String? ?? '',
      nativeText: json['native_text'] as String?,
      corrections: (json['corrections'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MessageCorrectionDto.fromJson)
          .toList(),
      annotations: (json['annotations'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MessageAnnotationDto.fromJson)
          .toList(),
      audio: rawAudio is Map<String, dynamic>
          ? TalkAudioDto.fromJson(rawAudio)
          : null,
    );
  }

  final String id;
  final String role;
  final String text;
  final String? nativeText;
  final List<MessageCorrectionDto> corrections;
  final List<MessageAnnotationDto> annotations;
  final TalkAudioDto? audio;

  TalkMessage toDomain() {
    return TalkMessage(
      id: id,
      role: role,
      text: text,
      nativeText: nativeText,
      corrections: corrections
          .map((correction) => correction.toDomain())
          .toList(),
      annotations: annotations
          .map((annotation) => annotation.toDomain())
          .toList(),
      audio: audio?.toDomain(),
    );
  }
}

class ConversationDto {
  const ConversationDto({
    required this.id,
    this.title = 'Conversation',
    required this.focusType,
    required this.focusId,
    required this.status,
    required this.messages,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Conversation',
      focusType: json['focus_type'] as String? ?? 'word',
      focusId: json['focus_id'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TalkMessageDto.fromJson)
          .toList(),
    );
  }

  final String id;
  final String title;
  final String focusType;
  final String focusId;
  final String status;
  final List<TalkMessageDto> messages;

  Conversation toDomain() {
    return Conversation(
      id: id,
      title: title,
      focusType: focusType,
      focusId: focusId,
      status: status,
      messages: messages.map((message) => message.toDomain()).toList(),
    );
  }
}

class TurnDto {
  const TurnDto({required this.userMessage, required this.assistantMessage});

  factory TurnDto.fromJson(Map<String, dynamic> json) {
    return TurnDto(
      userMessage: TalkMessageDto.fromJson(
        json['user_message'] as Map<String, dynamic>? ?? const {},
      ),
      assistantMessage: TalkMessageDto.fromJson(
        json['assistant_message'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final TalkMessageDto userMessage;
  final TalkMessageDto assistantMessage;

  Turn toDomain() {
    return Turn(
      userMessage: userMessage.toDomain(),
      assistantMessage: assistantMessage.toDomain(),
    );
  }
}

class Turn {
  const Turn({required this.userMessage, required this.assistantMessage});

  final TalkMessage userMessage;
  final TalkMessage assistantMessage;
}
