import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/progress/domain/progress.dart';
import 'package:named/features/timeline/presentation/widgets/timeline_progress_card.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('shows cumulative words, conversations, and readings', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: const Scaffold(
        body: TimelineProgressCard(
          progress: Progress(words: 500, conversations: 300, readings: 100),
        ),
      ),
    );

    expect(find.text(t.timeline.progressTitle.toUpperCase()), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text(t.timeline.progressWords), findsOneWidget);
    expect(find.text(t.timeline.progressConversations), findsOneWidget);
    expect(find.text(t.timeline.progressReads), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline.progress.toggle')));
    await tester.pumpAndSettle();
    expect(find.text('500'), findsNothing);

    await tester.tap(find.byKey(const Key('timeline.progress.toggle')));
    await tester.pumpAndSettle();
    expect(find.text('500'), findsOneWidget);
  });
}
