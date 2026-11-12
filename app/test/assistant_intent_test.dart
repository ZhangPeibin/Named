import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/assistant/data/dto/assistant_intent_dto.dart';
import 'package:named/features/assistant/domain/assistant_intent.dart';

void main() {
  test('maps review intent', () {
    final result = const AssistantIntentDto(
      intent: 'review_words',
      confidence: 0.9,
    ).toDomain();

    expect(result.intent, AssistantIntent.reviewWords);
    expect(result.hasAction, isTrue);
  });

  test('maps both challenge intents separately', () {
    expect(
      const AssistantIntentDto(
        intent: 'start_challenge',
        confidence: 0.8,
      ).toDomain().intent,
      AssistantIntent.startChallenge,
    );
    expect(
      const AssistantIntentDto(
        intent: 'view_challenges',
        confidence: 0.8,
      ).toDomain().intent,
      AssistantIntent.viewChallenges,
    );
  });

  test('unknown intents are normal content', () {
    final result = const AssistantIntentDto(
      intent: 'unknown',
      confidence: 0.2,
    ).toDomain();

    expect(result.intent, AssistantIntent.none);
    expect(result.hasAction, isFalse);
  });
}
