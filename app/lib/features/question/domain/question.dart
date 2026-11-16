class Question {
  const Question({
    required this.id,
    required this.question,
    required this.answer,
    required this.nativeExplanation,
    required this.createdAt,
  });

  final String id;
  final String question;
  final String answer;
  final String nativeExplanation;
  final DateTime createdAt;
}
