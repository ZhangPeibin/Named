import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/timeline/presentation/widgets/review_reminder_card.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('shows the number of words to see and opens review', (
    tester,
  ) async {
    var opened = 0;

    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: ReviewReminderCard(count: 3, onTap: () => opened++),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.timeline.reviewReminderTitle), findsOneWidget);
    expect(
      find.text(t.timeline.reviewReminderCount.replaceFirst('{count}', '3')),
      findsOneWidget,
    );
    expect(find.text(t.timeline.reviewReminderAction), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline.reviewReminder')));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });
}
