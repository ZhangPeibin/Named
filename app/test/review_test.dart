import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/discover/domain/discover.dart';
import 'package:named/features/review/presentation/review_page.dart';
import 'package:named/features/review/providers/review_providers.dart';
import 'package:named/features/timeline/domain/timeline_item.dart';
import 'package:named/features/words/data/api/words_api.dart';
import 'package:named/features/words/data/dto/word_shelf_dto.dart';
import 'package:named/features/words/domain/word_shelf.dart';
import 'package:named/features/words/providers/words_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  test('selects at most three words and stays deterministic', () {
    final words = [
      _shelfItem('word-0'),
      _shelfItem('word-1'),
      _shelfItem('word-2'),
      _shelfItem('word-3'),
      _shelfItem('word-4'),
    ];

    final selected = selectReviewItems(words);

    expect(selected, hasLength(3));
    expect(selected.map((item) => item.id), ['word-0', 'word-1', 'word-2']);
    expect(selectReviewItems(words.take(2).toList()), hasLength(2));
    expect(
      selectReviewItems(words).map((item) => item.id),
      selected.map((item) => item.id),
    );
  });

  test('never-reviewed words come before reviewed words', () {
    final words = [
      _shelfItem('reviewed', lastReviewedAt: DateTime(2026, 1, 2)),
      _shelfItem('unseen-a'),
      _shelfItem('unseen-b'),
      _shelfItem('known', status: WordShelfStatus.known),
    ];

    final selected = selectReviewItems(words);

    expect(selected.map((item) => item.id), [
      'unseen-a',
      'unseen-b',
      'reviewed',
    ]);
  });

  test('known words are excluded', () {
    final words = [
      _shelfItem('known', status: WordShelfStatus.known),
      _shelfItem('due'),
    ];

    expect(selectReviewItems(words).map((item) => item.id), ['due']);
  });

  test('due review words cap at three and skip missing word content', () {
    final words = [
      for (var index = 0; index < 5; index++) _shelfItem('word-$index'),
      WordShelfItem(
        id: 'empty',
        label: 'empty',
        word: null,
        audio: null,
        discoveryCount: 1,
        firstSeenAt: DateTime(2026, 1, 1),
        lastSeenAt: DateTime(2026, 1, 1),
        status: WordShelfStatus.needsReview,
        reviewCount: 0,
        lastReviewedAt: null,
      ),
    ];

    final due = dueReviewWords(words);
    expect(due, hasLength(3));
    expect(due.map((item) => item.id), isNot(contains('empty')));
  });

  test('parses the attempted status', () {
    expect(wordShelfStatusFromJson('attempted'), WordShelfStatus.attempted);
  });

  testWidgets('hides the answer until the learner attempts it', (tester) async {
    final api = _RecordingWordsApi();
    final item = _wordItem('framework');

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          reviewWordsProvider.overrideWith((ref) => [item]),
          wordsApiProvider.overrideWithValue(api),
        ],
        child: const ReviewPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('体系、框架'), findsOneWidget);
    expect(find.text('framework'), findsNothing);

    await tester.enterText(find.byType(TextField), 'framework');
    await tester.tap(find.text(t.review.checkAttempt));
    await tester.pumpAndSettle();

    expect(api.attempts, ['framework']);
    expect(find.text(t.review.answerLabel), findsNothing);
    expect(find.text('a legal framework'), findsNothing);

    await tester.tap(find.text(t.review.showHint));
    await tester.pumpAndSettle();
    expect(find.textContaining('f·'), findsOneWidget);

    await tester.tap(find.text(t.review.showAnswer));
    await tester.pumpAndSettle();
    expect(find.text(t.review.answerLabel), findsOneWidget);
    expect(find.text('framework'), findsNWidgets(2));
    expect(find.text('a legal framework'), findsOneWidget);

    await tester.tap(find.text(t.review.saidIt));
    await tester.pumpAndSettle();

    expect(api.reviewed, ['word-framework']);
    expect(find.text(t.review.completeTitle), findsOneWidget);
  });

  testWidgets('does not submit an empty attempt', (tester) async {
    final api = _RecordingWordsApi();

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          reviewWordsProvider.overrideWith((ref) => [_wordItem('framework')]),
          wordsApiProvider.overrideWithValue(api),
        ],
        child: const ReviewPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.review.checkAttempt));
    await tester.pumpAndSettle();

    expect(api.attempts, isEmpty);
    expect(find.text(t.review.attemptPlaceholder), findsOneWidget);
  });
}

class _RecordingWordsApi implements WordsApi {
  final List<String> attempts = [];
  final List<String> reviewed = [];

  @override
  Future<void> markAttempt({
    required String wordId,
    required String text,
  }) async {
    attempts.add(text);
  }

  @override
  Future<void> markReviewed(String wordId) async {
    reviewed.add(wordId);
  }

  @override
  Future<WordShelfDto> fetch() async {
    return const WordShelfDto(
      stats: WordsStatsDto(
        total: 0,
        newThisWeek: 0,
        reviewedThisWeek: 0,
        usedInTalkThisWeek: 0,
      ),
      words: [],
    );
  }

  @override
  Future<WordShelfItemDto> lookup(String text) {
    throw UnimplementedError();
  }

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

  @override
  Future<void> setKnown({required String wordId, required bool known}) async {}
}

WordShelfItem _shelfItem(
  String id, {
  WordShelfStatus status = WordShelfStatus.needsReview,
  DateTime? lastReviewedAt,
}) {
  return WordShelfItem(
    id: id,
    label: 'framework',
    word: _word(),
    audio: null,
    discoveryCount: 1,
    firstSeenAt: DateTime(2026, 1, 1),
    lastSeenAt: DateTime(2026, 1, 1),
    status: status,
    reviewCount: lastReviewedAt == null ? 0 : 1,
    lastReviewedAt: lastReviewedAt,
  );
}

TimelineWordItem _wordItem(String id) {
  return TimelineWordItem(
    id: id,
    createdAt: DateTime(2026, 1, 1),
    inputText: '框架。',
    wordId: 'word-$id',
    word: _word(),
    audio: null,
    conversationId: null,
  );
}

DiscoveredWord _word() {
  return const DiscoveredWord(
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
  );
}
