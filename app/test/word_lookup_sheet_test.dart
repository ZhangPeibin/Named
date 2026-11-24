import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/discover/domain/discover.dart';
import 'package:named/features/words/data/api/words_api.dart';
import 'package:named/features/words/domain/word_shelf.dart';
import 'package:named/features/words/presentation/word_lookup_sheet.dart';
import 'package:named/features/words/providers/words_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('lookup loading stays compact instead of full screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final pending = Completer<WordShelfItem>();
    await _pumpLookupHost(
      tester,
      overrides: [
        wordLookupProvider('tree').overrideWith((ref) => pending.future),
      ],
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final loading = find.byKey(const Key('wordLookup.loading'));
    expect(loading, findsOneWidget);
    expect(tester.getSize(loading).height, lessThan(420));

    pending.complete(_wordShelfItem());
    await tester.pumpAndSettle();
  });

  testWidgets('looked-up word can be added to Words', (tester) async {
    final api = _RecordingWordsApi();
    await _pumpLookupHost(
      tester,
      overrides: [
        wordsApiProvider.overrideWithValue(api),
        wordLookupProvider(
          'tree',
        ).overrideWith((ref) async => _wordShelfItem()),
      ],
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wordDetails.add')), findsOneWidget);
    expect(find.text(t.words.addToWords), findsOneWidget);

    await tester.tap(find.byKey(const Key('wordDetails.add')));
    await tester.pumpAndSettle();

    expect(api.savedIds, ['tree']);
    expect(find.byKey(const Key('wordDetails.add')), findsNothing);
    expect(find.text(t.words.addedToWords), findsOneWidget);
  });

  testWidgets('already-saved lookup shows the saved state', (tester) async {
    await _pumpLookupHost(
      tester,
      overrides: [
        wordLookupProvider(
          'tree',
        ).overrideWith((ref) async => _wordShelfItem(saved: true)),
      ],
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wordDetails.add')), findsNothing);
    expect(find.text(t.words.addedToWords), findsOneWidget);
  });
}

Future<void> _pumpLookupHost(
  WidgetTester tester, {
  required List<Override> overrides,
}) {
  return pumpWithTranslations(
    tester,
    child: ProviderScope(
      overrides: overrides,
      child: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showWordLookupSheet(context, 'tree'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

WordShelfItem _wordShelfItem({bool saved = false}) {
  return WordShelfItem(
    id: 'tree',
    label: 'tree',
    word: const DiscoveredWord(
      spelling: 'tree',
      ipa: {'us': '/triː/'},
      pos: ['noun'],
      senses: [
        WordSense(
          definitionEn: 'a tall plant with a trunk and branches',
          definitionZh: '有树干和树枝的高大植物',
          exampleEn: 'There is a tree in the park.',
          exampleZh: '公园里有一棵树。',
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
    firstSeenAt: DateTime(2026, 11, 20),
    lastSeenAt: DateTime(2026, 11, 20),
    status: WordShelfStatus.needsReview,
    saved: saved,
  );
}

class _RecordingWordsApi extends MockWordsApi {
  final savedIds = <String>[];

  @override
  Future<bool> addToShelf(String wordId) async {
    savedIds.add(wordId);
    return true;
  }
}
