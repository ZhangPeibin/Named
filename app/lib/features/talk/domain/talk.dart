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
    this.partOfSpeech,
    this.grammar,
    this.ipa,
    this.syllables,
    this.vowels = const [],
    this.consonants = const [],
    this.phonics,
  });

  final String text;
  final String kind;
  final String meaningZh;
  final String? partOfSpeech;
  final String? grammar;
  final String? ipa;
  final String? syllables;
  final List<String> vowels;
  final List<String> consonants;
  final String? phonics;

  bool get isWord => kind == 'word';
  bool get isExpression => kind == 'expression';
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

enum PronunciationAccent { us, uk }

class PronunciationAudio {
  const PronunciationAudio({required this.usUrl, required this.ukUrl});

  final String? usUrl;
  final String? ukUrl;

  String? urlFor(PronunciationAccent accent) {
    return switch (accent) {
      PronunciationAccent.us => usUrl ?? ukUrl,
      PronunciationAccent.uk => ukUrl ?? usUrl,
    };
  }

  bool get hasAudio => urlFor(PronunciationAccent.us) != null;
}
