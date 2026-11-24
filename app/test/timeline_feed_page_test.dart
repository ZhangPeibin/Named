import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/timeline/data/api/timeline_api.dart';
import 'package:named/features/timeline/data/dto/timeline_dto.dart';
import 'package:named/features/timeline/presentation/timeline_feed_page.dart';
import 'package:named/features/timeline/providers/timeline_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

class _FakeTimelineApi implements TimelineApi {
  _FakeTimelineApi(this.items);

  final List<TimelineItemDto> items;

  @override
  Future<TimelineResponseDto> fetch({
    int limit = 30,
    String? before,
    String? type,
  }) async {
    return TimelineResponseDto(items: items, nextCursor: null);
  }
}

TimelineTalkItemDto _talk() {
  return TimelineTalkItemDto(
    id: 'talk-1',
    createdAt: DateTime(2026, 11, 22, 13, 45),
    conversationId: 'conversation-1',
    title: 'relevant',
    lastMessageRole: 'assistant',
    lastMessageText: 'Okay, so the two projects are separate.',
    messageCount: 2,
  );
}

TimelineDailyItemDto _daily() {
  return TimelineDailyItemDto(
    id: 'daily-1',
    createdAt: DateTime(2026, 11, 22, 9),
    readingDate: DateTime(2026, 11, 22),
    title: 'The Sound Under the Floor',
    completed: false,
    wordCount: 3,
    streak: 0,
  );
}

void main() {
  testWidgets('lists talks', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          timelineApiProvider.overrideWithValue(_FakeTimelineApi([_talk()])),
        ],
        child: const TimelineFeedPage(kind: TimelineFeedKind.talks),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.talks.title), findsOneWidget);
    expect(find.text('relevant'), findsOneWidget);
    expect(
      find.text('Okay, so the two projects are separate.'),
      findsOneWidget,
    );
  });

  testWidgets('lists readings', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          timelineApiProvider.overrideWithValue(_FakeTimelineApi([_daily()])),
        ],
        child: const TimelineFeedPage(kind: TimelineFeedKind.reads),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.reads.title), findsOneWidget);
    expect(find.text('The Sound Under the Floor'), findsOneWidget);
  });

  testWidgets('shows the empty state for an empty feed', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          timelineApiProvider.overrideWithValue(_FakeTimelineApi(const [])),
        ],
        child: const TimelineFeedPage(kind: TimelineFeedKind.talks),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.talks.empty), findsOneWidget);
    expect(find.text(t.talks.emptyHint), findsOneWidget);
  });
}
