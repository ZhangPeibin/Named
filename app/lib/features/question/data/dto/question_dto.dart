import '../../domain/question.dart';

class QuestionDto {
  const QuestionDto({
    required this.id,
    required this.question,
    required this.answer,
    required this.nativeExplanation,
    required this.createdAt,
  });

  factory QuestionDto.fromJson(Map<String, dynamic> json) {
    return QuestionDto(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      nativeExplanation: json['native_explanation'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String question;
  final String answer;
  final String nativeExplanation;
  final DateTime createdAt;

  Question toDomain() {
    return Question(
      id: id,
      question: question,
      answer: answer,
      nativeExplanation: nativeExplanation,
      createdAt: createdAt,
    );
  }
}
