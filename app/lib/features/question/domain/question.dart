class QuestionContext {
  const QuestionContext({required this.type, this.ref, this.quote});

  final String type;
  final String? ref;
  final String? quote;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (ref != null) 'ref': ref,
      if (quote != null) 'quote': quote,
    };
  }
}

class QuestionMessage {
  const QuestionMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.example,
    required this.nativeExplanation,
    required this.confidence,
    required this.followUpSuggestions,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String text;
  final String? example;
  final String? nativeExplanation;
  final String? confidence;
  final List<String> followUpSuggestions;
  final DateTime createdAt;

  bool get isUser => role == 'user';
}

class QuestionThread {
  const QuestionThread({
    required this.id,
    required this.title,
    required this.contextType,
    required this.contextRef,
    required this.contextQuote,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? contextType;
  final String? contextRef;
  final String? contextQuote;
  final List<QuestionMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class QuestionThreadSummary {
  const QuestionThreadSummary({
    required this.id,
    required this.title,
    required this.contextType,
    required this.contextQuote,
    required this.lastText,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? contextType;
  final String? contextQuote;
  final String lastText;
  final DateTime updatedAt;
}
