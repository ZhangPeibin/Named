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

    expect(find.text('500'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text(t.timeline.progressWords), findsOneWidget);
    expect(find.text(t.timeline.progressConversations), findsOneWidget);
    expect(find.text(t.timeline.progressReads), findsOneWidget);
    expect(find.byKey(const Key('timeline.progress.words')), findsNothing);
  });

  testWidgets('opens Words from the words stat', (tester) async {
    var taps = 0;

    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: TimelineProgressCard(
          progress: const Progress(words: 3, conversations: 2, readings: 1),
          onWordsTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('timeline.progress.words')));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
