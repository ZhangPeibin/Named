class MessageCorrection {
  const MessageCorrection({
    required this.original,
    required this.suggestion,
    required this.note,
  });

  final String original;
  final String suggestion;
  final String note;
}

class MessageAnnotation {
  const MessageAnnotation({
    required this.text,
    required this.kind,
    required this.meaningZh,
  });

  final String text;
  final String kind;
  final String meaningZh;
}

class TalkMessage {
  const TalkMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.corrections,
    required this.annotations,
  });

  final String id;
  final String role;
  final String text;
  final List<MessageCorrection> corrections;
  final List<MessageAnnotation> annotations;

  bool get isUser => role == 'user';
}

class Conversation {
  const Conversation({
    required this.id,
    required this.focusType,
    required this.focusId,
    required this.status,
    required this.messages,
  });

  final String id;
  final String focusType;
  final String focusId;
  final String status;
  final List<TalkMessage> messages;
}
