enum AssistantIntent { reviewWords, startChallenge, viewChallenges, none }

class AssistantIntentResult {
  const AssistantIntentResult({required this.intent, required this.confidence});

  final AssistantIntent intent;
  final double confidence;

  bool get hasAction => intent != AssistantIntent.none;
}
