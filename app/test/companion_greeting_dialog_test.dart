import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/companion/presentation/widgets/companion_greeting_dialog.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('greeting dialog shows the companion line and dismisses', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => const CompanionGreetingDialog(
              name: 'Momo',
              text: "Hi, I'm glad you're here. What caught your eye today?",
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion.greeting')), findsOneWidget);
    expect(find.text('Momo'), findsOneWidget);
    expect(
      find.text("Hi, I'm glad you're here. What caught your eye today?"),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('companion.greeting.dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion.greeting')), findsNothing);
  });
}
