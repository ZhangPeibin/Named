import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/discover/domain/discover.dart';
import 'package:named/features/words/domain/word_shelf.dart';
import 'package:named/features/words/presentation/words_page.dart';
import 'package:named/features/words/providers/words_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders the vocabulary notebook with numbered entries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [wordShelfProvider.overrideWith((ref) => _shelf)],
        child: const WordsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.words.notebookEyebrow.toUpperCase()), findsOneWidget);

    expect(find.text(t.words.needsReview.toUpperCase()), findsOneWidget);
    expect(find.text(t.words.attempted.toUpperCase()), findsOneWidget);

    expect(find.textContaining('career'), findsOneWidget);
    expect(find.textContaining('motivation'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);

    expect(find.byKey(const Key('words.talk.career')), findsOneWidget);
    expect(find.textContaining('/kəˈrɪr/'), findsOneWidget);
  });
}

final _shelf = WordShelf(
  stats: const WordsStats(total: 3, newThisWeek: 2, usedInTalkThisWeek: 1),
  words: [
    _item(
      'career',
      'career',
      WordShelfStatus.needsReview,
      definitionZh: '职业；职业生涯',
      ipa: '/kəˈrɪr/',
    ),
    _item(
      'motivation',
      'motivation',
      WordShelfStatus.attempted,
      definitionZh: '做某事的动力、积极性',
      ipa: '/ˌmoʊtɪˈveɪʃən/',
    ),
  ],
);

WordShelfItem _item(
  String id,
  String label,
  WordShelfStatus status, {
  required String definitionZh,
  required String ipa,
}) {
  return WordShelfItem(
    id: id,
    label: label,
    word: DiscoveredWord(
      spelling: label,
      ipa: {'us': ipa},
      pos: const ['noun'],
      senses: [
        WordSense(
          definitionEn: 'a definition',
          definitionZh: definitionZh,
          exampleEn: 'An example.',
          exampleZh: '一个例句。',
        ),
      ],
      grammar: '',
      related: const [],
      chunks: const [],
      varietyNotes: const [],
      sceneExtensions: const [],
    ),
    audio: null,
    discoveryCount: 1,
    firstSeenAt: DateTime(2026, 11, 20),
    lastSeenAt: DateTime(2026, 11, 20),
    status: status,
  );
}
