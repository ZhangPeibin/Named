import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/widgets/app_message_bubble.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders a recast under an outgoing message', (tester) async {
    await pumpWithTranslations(
      tester,
      child: const Scaffold(
        body: AppMessageBubble(
          text: 'I saw a tree in the park.',
          side: AppMessageSide.outgoing,
          secondaryLabel: 'More natural',
          secondaryText: 'I saw a tree in the park yesterday.',
        ),
      ),
    );

    expect(find.text('I saw a tree in the park.'), findsOneWidget);
    expect(find.text('MORE NATURAL'), findsOneWidget);
    expect(find.text('I saw a tree in the park yesterday.'), findsOneWidget);
  });

  testWidgets('renders an incoming message without a secondary line', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: const Scaffold(
        body: AppMessageBubble(
          text: 'How often do you go there?',
          side: AppMessageSide.incoming,
        ),
      ),
    );

    expect(find.text('How often do you go there?'), findsOneWidget);
  });
}
