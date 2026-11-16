import '../../domain/question.dart';

class QuestionMessageDto {
  const QuestionMessageDto({
    required this.id,
    required this.role,
    required this.text,
    required this.example,
    required this.nativeExplanation,
    required this.confidence,
    required this.followUpSuggestions,
    required this.feedback,
    required this.createdAt,
  });

  factory QuestionMessageDto.fromJson(Map<String, dynamic> json) {
    return QuestionMessageDto(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      text: json['text'] as String? ?? '',
      example: json['example'] as String?,
      nativeExplanation: json['native_explanation'] as String?,
      confidence: json['confidence'] as String?,
      followUpSuggestions:
          (json['follow_up_suggestions'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      feedback: json['feedback'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String role;
  final String text;
  final String? example;
  final String? nativeExplanation;
  final String? confidence;
  final List<String> followUpSuggestions;
  final String? feedback;
  final DateTime createdAt;

  QuestionMessage toDomain() {
    return QuestionMessage(
      id: id,
      role: role,
      text: text,
      example: example,
      nativeExplanation: nativeExplanation,
      confidence: confidence,
      followUpSuggestions: followUpSuggestions,
      feedback: feedback,
      createdAt: createdAt,
    );
  }
}

class QuestionThreadDto {
  const QuestionThreadDto({
    required this.id,
    required this.title,
    required this.contextType,
    required this.contextRef,
    required this.contextQuote,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuestionThreadDto.fromJson(Map<String, dynamic> json) {
    return QuestionThreadDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      contextType: json['context_type'] as String?,
      contextRef: json['context_ref'] as String?,
      contextQuote: json['context_quote'] as String?,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuestionMessageDto.fromJson)
          .toList(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String? contextType;
  final String? contextRef;
  final String? contextQuote;
  final List<QuestionMessageDto> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionThread toDomain() {
    return QuestionThread(
      id: id,
      title: title,
      contextType: contextType,
      contextRef: contextRef,
      contextQuote: contextQuote,
      messages: messages.map((message) => message.toDomain()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class QuestionThreadSummaryDto {
  const QuestionThreadSummaryDto({
    required this.id,
    required this.title,
    required this.contextType,
    required this.contextQuote,
    required this.lastText,
    required this.updatedAt,
  });

  factory QuestionThreadSummaryDto.fromJson(Map<String, dynamic> json) {
    return QuestionThreadSummaryDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      contextType: json['context_type'] as String?,
      contextQuote: json['context_quote'] as String?,
      lastText: json['last_text'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String? contextType;
  final String? contextQuote;
  final String lastText;
  final DateTime updatedAt;

  QuestionThreadSummary toDomain() {
    return QuestionThreadSummary(
      id: id,
      title: title,
      contextType: contextType,
      contextQuote: contextQuote,
      lastText: lastText,
      updatedAt: updatedAt,
    );
  }
}
