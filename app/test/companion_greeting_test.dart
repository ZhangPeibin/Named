import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/companion/presentation/companion_greeting_line.dart';
import 'package:named/features/progress/domain/progress.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('greeting leads with the strongest progress number', (
    tester,
  ) async {
    late String line;
    await pumpWithTranslations(
      tester,
      child: Builder(
        builder: (context) {
          line = companionGreetingLine(
            context,
            const Progress(
              words: 12,
              conversations: 3,
              readings: 1,
              practices: 2,
            ),
          );
          return const SizedBox.shrink();
        },
      ),
    );
    expect(
      line,
      "Hi, I'm glad you're here. You've kept 12 words. Each one is a little piece of your world.",
    );
  });

  testWidgets('greeting welcomes back a returning learner', (tester) async {
    late String line;
    await pumpWithTranslations(
      tester,
      child: Builder(
        builder: (context) {
          line = companionGreetingLine(
            context,
            const Progress(
              words: 4,
              conversations: 0,
              readings: 0,
              practices: 0,
            ),
            returning: true,
          );
          return const SizedBox.shrink();
        },
      ),
    );
    expect(
      line,
      "Welcome back. It's good to see you. You've kept 4 words. Each one is a little piece of your world.",
    );
  });

  testWidgets('greeting is friendly with no progress', (tester) async {
    late String line;
    await pumpWithTranslations(
      tester,
      child: Builder(
        builder: (context) {
          line = companionGreetingLine(
            context,
            const Progress(
              words: 0,
              conversations: 0,
              readings: 0,
              practices: 0,
            ),
          );
          return const SizedBox.shrink();
        },
      ),
    );
    expect(
      line,
      "Hi, I'm glad you're here. What caught your eye today? I'd love to hear about it.",
    );
  });
}
