import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/network/api_exception.dart';
import 'package:named/features/discover/data/dto/discover_dto.dart';
import 'package:named/features/timeline/presentation/widgets/word_details_sheet.dart';
import 'package:named/features/words/data/api/words_api.dart';
import 'package:named/features/words/data/dto/word_shelf_dto.dart';
import 'package:named/features/words/domain/word_shelf.dart';
import 'package:named/features/words/presentation/word_lookup_sheet.dart';
import 'package:named/features/words/providers/words_providers.dart';

import 'support/i18n_test_helpers.dart';

class _FakeWordsApi implements WordsApi {
  _FakeWordsApi({required this.lookupItem, required this.details});

  final WordShelfItemDto lookupItem;
  final Future<WordShelfItemDto> Function() details;
  var lookupCalls = 0;
  var detailCalls = 0;

  @override
  Future<WordShelfItemDto> lookup(String text, {String level = 'full'}) async {
    lookupCalls++;
    return lookupItem;
  }

  @override
  Future<WordShelfItemDto> fetchDetails(String wordId) async {
    detailCalls++;
    return details();
  }

  @override
  Future<WordShelfDto> fetch() async {
    return const WordShelfDto(
      stats: WordsStatsDto(total: 0, newThisWeek: 0, usedInTalkThisWeek: 0),
      words: [],
    );
  }

  @override
  Future<bool> addToShelf(String wordId) async => true;

  @override
  Future<void> setKnown({required String wordId, required bool known}) async {}

  @override
  Future<void> markReviewed(String wordId) async {}

  @override
  Future<void> markAttempt({
    required String wordId,
    required String text,
  }) async {}

  @override
  Future<void> saveFromTalk({
    required String label,
    required String meaningZh,
    String? partOfSpeech,
    String? grammar,
    String? exampleEn,
    String? ipa,
    String? syllables,
    List<String> vowels = const [],
    List<String> consonants = const [],
    String? phonics,
  }) async {}
}

WordShelfItemDto _item({required String level, String grammar = ''}) {
  final now = DateTime.now();
  return WordShelfItemDto(
    id: 'word-1',
    label: 'tree',
    word: DiscoveredWordDto(
      spelling: 'tree',
      ipa: const {'us': '/triː/'},
      pos: const ['n.'],
      senses: const [
        WordSenseDto(
          definitionEn: 'A tall plant.',
          definitionZh: '树',
          exampleEn: 'A tree grows here.',
          exampleZh: '这里长着一棵树。',
        ),
      ],
      grammar: grammar,
      related: const [],
      chunks: const [],
      varietyNotes: const [],
      sceneExtensions: const [],
    ),
    audio: null,
    discoveryCount: 1,
    firstSeenAt: now,
    lastSeenAt: now,
    status: WordShelfStatus.needsReview,
    saved: false,
    contentLevel: level,
  );
}

class _SheetHost extends StatelessWidget {
  const _SheetHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('openLookup'),
            onPressed: () => showWordLookupSheet(context, 'tree'),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

Future<void> _openSheet(WidgetTester tester, _FakeWordsApi api) async {
  await pumpWithTranslations(
    tester,
    child: ProviderScope(
      overrides: [wordsApiProvider.overrideWithValue(api)],
      child: const _SheetHost(),
    ),
  );
  await tester.tap(find.byKey(const Key('openLookup')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('card appears first and full details fill in automatically', (
    tester,
  ) async {
    final gate = Completer<WordShelfItemDto>();
    final api = _FakeWordsApi(
      lookupItem: _item(level: 'card'),
      details: () => gate.future,
    );

    await _openSheet(tester, api);

    expect(find.text('tree'), findsWidgets);
    expect(find.byKey(const Key('wordDetails.loadingMore')), findsOneWidget);
    expect(find.byKey(const Key('wordDetails.skeleton')), findsOneWidget);
    expect(find.text('full grammar'), findsNothing);
    expect(api.detailCalls, 1);
    final heightBefore = tester.getSize(find.byType(WordDetailsSheet)).height;

    gate.complete(_item(level: 'full', grammar: 'full grammar'));
    await tester.pumpAndSettle();

    expect(find.text('full grammar'), findsOneWidget);
    expect(find.byKey(const Key('wordDetails.loadingMore')), findsNothing);
    expect(find.byKey(const Key('wordDetails.skeleton')), findsNothing);
    final heightAfter = tester.getSize(find.byType(WordDetailsSheet)).height;
    expect(heightAfter, heightBefore);
  });

  testWidgets('failed details keep the card and retry loads full content', (
    tester,
  ) async {
    var calls = 0;
    final api = _FakeWordsApi(
      lookupItem: _item(level: 'card'),
      details: () async {
        calls++;
        if (calls == 1) {
          throw const ApiException(
            type: ApiExceptionType.badResponse,
            message: 'details failed',
          );
        }
        return _item(level: 'full', grammar: 'full grammar');
      },
    );

    await _openSheet(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('tree'), findsWidgets);
    expect(find.text('details failed'), findsOneWidget);
    expect(find.byKey(const Key('wordDetails.retryDetails')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('wordDetails.retryDetails')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wordDetails.retryDetails')));
    await tester.pumpAndSettle();

    expect(find.text('full grammar'), findsOneWidget);
    expect(find.text('details failed'), findsNothing);
  });

  testWidgets('full-only responses do not request details', (tester) async {
    final api = _FakeWordsApi(
      lookupItem: _item(level: 'full', grammar: 'full grammar'),
      details: () async => _item(level: 'full', grammar: 'full grammar'),
    );

    await _openSheet(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('full grammar'), findsOneWidget);
    expect(api.detailCalls, 0);
  });

  testWidgets('closing the sheet before details complete is safe', (
    tester,
  ) async {
    final gate = Completer<WordShelfItemDto>();
    final api = _FakeWordsApi(
      lookupItem: _item(level: 'card'),
      details: () => gate.future,
    );

    await _openSheet(tester, api);
    await tester.tap(find.byKey(const Key('wordDetails.close')));
    await tester.pumpAndSettle();

    gate.complete(_item(level: 'full', grammar: 'full grammar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('reopening the same word uses the lookup cache', (tester) async {
    final api = _FakeWordsApi(
      lookupItem: _item(level: 'card'),
      details: () async => _item(level: 'full', grammar: 'full grammar'),
    );

    await _openSheet(tester, api);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wordDetails.close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openLookup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(api.lookupCalls, 1);
    expect(api.detailCalls, 1);
    expect(find.text('full grammar'), findsOneWidget);
  });
}
