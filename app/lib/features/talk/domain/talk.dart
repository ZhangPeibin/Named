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

  bool get isGrammar => kind == 'grammar';
}

class TalkAudio {
  const TalkAudio({required this.url, required this.status});

  final String? url;
  final String status;

  bool get isReady => status == 'ready' && url != null && url!.isNotEmpty;
}

class TalkMessage {
  const TalkMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.corrections,
    required this.annotations,
    this.nativeText,
    this.audio,
  });

  final String id;
  final String role;
  final String text;
  final String? nativeText;
  final List<MessageCorrection> corrections;
  final List<MessageAnnotation> annotations;
  final TalkAudio? audio;

  bool get isUser => role == 'user';
}

class HelpSuggestion {
  const HelpSuggestion({
    required this.naturalEnglish,
    required this.note,
    required this.alternatives,
    required this.audio,
  });

  final String naturalEnglish;
  final String? note;
  final List<String> alternatives;
  final TalkAudio? audio;
}

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.focusType,
    required this.focusId,
    required this.status,
    required this.messages,
  });

  final String id;
  final String title;
  final String focusType;
  final String focusId;
  final String status;
  final List<TalkMessage> messages;
}
