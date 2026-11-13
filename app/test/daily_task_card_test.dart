import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/timeline/domain/timeline_item.dart';
import 'package:named/features/timeline/presentation/widgets/daily_task_card.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('shows the daily task and opens the reader', (tester) async {
    var tapped = false;
    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: DailyTaskCard(
          item: TimelineDailyItem(
            id: 'daily-1',
            createdAt: DateTime.now(),
            readingDate: DateTime.now(),
            title: null,
            completed: false,
            wordCount: 0,
            streak: 0,
          ),
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text(t.daily.taskToday), findsOneWidget);
    expect(find.text(t.daily.taskUnread), findsOneWidget);
    await tester.tap(find.text(t.daily.read));
    expect(tapped, isTrue);
  });

  testWidgets('shows completion and streak', (tester) async {
    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: DailyTaskCard(
          item: TimelineDailyItem(
            id: 'daily-1',
            createdAt: DateTime.now(),
            readingDate: DateTime.now(),
            title: 'The Little Garden Club',
            completed: true,
            wordCount: 120,
            streak: 3,
          ),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('The Little Garden Club'), findsOneWidget);
    expect(
      find.text(t.daily.taskDone.replaceFirst('{streak}', '3')),
      findsOneWidget,
    );
  });
}
