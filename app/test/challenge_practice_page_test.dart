import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/theme/app_spacing.dart';
import 'package:named/features/challenge/domain/challenge.dart';
import 'package:named/features/challenge/presentation/challenge_practice_page.dart';
import 'package:named/features/challenge/providers/challenge_providers.dart';
import 'package:named/features/discover/domain/discover.dart';
import 'package:named/features/words/domain/word_shelf.dart';
import 'package:named/features/words/providers/words_providers.dart';

import 'support/i18n_test_helpers.dart';

Challenge _challenge() {
  return Challenge(
    id: 'c1',
    name: 'Round',
    plannedDays: 2,
    status: ChallengeStatus.active,
    startedAt: DateTime(2026, 11, 12),
    endedAt: null,
    createdAt: DateTime(2026, 11, 12),
    totalCount: 1,
    visitedCount: 0,
    isDue: false,
    items: const [
      ChallengeItem(
        id: 'item-1',
        discoveryId: 'discovery-1',
        position: 0,
        visitedAt: null,
        focusType: 'word',
        focusId: 'word-1',
        title: 'tree',
      ),
    ],
  );
}

WordShelfItem _treeShelf() {
  return WordShelfItem(
    id: 'word-1',
    label: 'tree',
    word: const DiscoveredWord(
      spelling: 'tree',
      ipa: {},
      pos: ['noun'],
      senses: [
        WordSense(
          definitionEn: 'a tall plant',
          definitionZh: '树',
          exampleEn: 'The tree is tall.',
          exampleZh: '这棵树很高。',
        ),
      ],
      grammar: '',
      related: [],
      chunks: [],
      varietyNotes: [],
      sceneExtensions: [],
    ),
    audio: null,
    discoveryCount: 1,
    firstSeenAt: DateTime(2026, 11, 12),
    lastSeenAt: DateTime(2026, 11, 12),
    status: WordShelfStatus.growing,
    reviewCount: 0,
    lastReviewedAt: null,
  );
}

void main() {
  testWidgets('renders the listen & say step with content', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengeProvider('c1').overrideWith((ref) async => _challenge()),
          wordShelfProvider.overrideWith(
            (ref) async => const WordShelf(
              stats: WordsStats(
                total: 0,
                newThisWeek: 0,
                reviewedThisWeek: 0,
                usedInTalkThisWeek: 0,
              ),
              words: [],
            ),
          ),
        ],
        child: const ChallengePracticePage(challengeId: 'c1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('tree'), findsWidgets);
    expect(find.byKey(const Key('practice.record')), findsOneWidget);
  });

  testWidgets('keeps the body aligned to the page margin', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengeProvider('c1').overrideWith((ref) async => _challenge()),
          wordShelfProvider.overrideWith(
            (ref) async => const WordShelf(
              stats: WordsStats(
                total: 0,
                newThisWeek: 0,
                reviewedThisWeek: 0,
                usedInTalkThisWeek: 0,
              ),
              words: [],
            ),
          ),
        ],
        child: const ChallengePracticePage(challengeId: 'c1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('tree')).dx,
      AppSpacing.pageHorizontalPadding,
    );
  });

  testWidgets('practices the word inside a short sentence', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengeProvider('c1').overrideWith((ref) async => _challenge()),
          wordShelfProvider.overrideWith(
            (ref) async => WordShelf(
              stats: const WordsStats(
                total: 1,
                newThisWeek: 1,
                reviewedThisWeek: 0,
                usedInTalkThisWeek: 0,
              ),
              words: [_treeShelf()],
            ),
          ),
        ],
        child: const ChallengePracticePage(challengeId: 'c1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The tree is tall.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('practice.next')));
    await tester.pumpAndSettle();
    expect(find.text('The ____ is tall.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('practice.answer')), 'tree');
    await tester.tap(find.byKey(const Key('practice.check')));
    await tester.pumpAndSettle();
    expect(find.text('Correct'), findsOneWidget);
  });
}
