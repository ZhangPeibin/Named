import '../../domain/assistant_intent.dart';

class AssistantIntentDto {
  const AssistantIntentDto({required this.intent, required this.confidence});

  factory AssistantIntentDto.fromJson(Map<String, dynamic> json) {
    return AssistantIntentDto(
      intent: json['intent'] as String? ?? 'none',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  final String intent;
  final double confidence;

  AssistantIntentResult toDomain() {
    return AssistantIntentResult(
      intent: switch (intent) {
        'review_words' => AssistantIntent.reviewWords,
        'start_challenge' => AssistantIntent.startChallenge,
        'view_challenges' => AssistantIntent.viewChallenges,
        _ => AssistantIntent.none,
      },
      confidence: confidence,
    );
  }
}
