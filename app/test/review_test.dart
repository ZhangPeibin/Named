import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/discover/domain/discover.dart';
import 'package:named/features/review/presentation/review_page.dart';
import 'package:named/features/review/providers/review_providers.dart';
import 'package:named/features/timeline/domain/timeline_item.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  test('selects at most three unique review words', () {
    final words = [
      for (var index = 0; index < 5; index++) _wordItem('word-$index'),
    ];

    final selected = selectReviewItems(words, random: Random(7));

    expect(selected, hasLength(3));
    expect(selected.map((item) => item.id).toSet(), hasLength(3));
    expect(selectReviewItems(words.take(2).toList()), hasLength(2));
  });

  testWidgets('reveals meaning and finishes a review', (tester) async {
    final item = _wordItem('framework');

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          reviewWordsProvider.overrideWith((ref) => [item]),
        ],
        child: const ReviewPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('framework'), findsOneWidget);
    expect(find.text('体系、框架'), findsNothing);

    await tester.tap(find.text(t.review.showMeaning));
    await tester.pumpAndSettle();

    expect(find.text('体系、框架'), findsOneWidget);
    expect(find.text('a legal framework'), findsOneWidget);

    await tester.tap(find.text(t.review.finish));
    await tester.pumpAndSettle();

    expect(find.text(t.review.completeTitle), findsOneWidget);
  });
}

TimelineWordItem _wordItem(String id) {
  return TimelineWordItem(
    id: id,
    createdAt: DateTime(2026, 1, 1),
    inputText: '框架。',
    wordId: 'word-$id',
    word: const DiscoveredWord(
      spelling: 'framework',
      ipa: {'us': '/ˈfreɪmwɜːk/'},
      pos: ['noun'],
      senses: [
        WordSense(
          definitionEn: 'a set of ideas or rules',
          definitionZh: '体系、框架',
          exampleEn: 'It is a legal framework.',
          exampleZh: '这是一个法律框架。',
        ),
      ],
      grammar: '',
      related: [],
      chunks: [
        WordChunk(
          phrase: 'a legal framework',
          meaningZh: '法律框架',
          exampleEn: 'It is a legal framework.',
        ),
      ],
      varietyNotes: [],
      sceneExtensions: [],
    ),
    audio: null,
    conversationId: null,
  );
}
