import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/network/api_exception.dart';
import 'package:named/features/discover/domain/discover.dart';
import 'package:named/features/practice/data/api/practice_api.dart';
import 'package:named/features/practice/data/dto/practice_word_dto.dart';
import 'package:named/features/practice/data/repositories/practice_repository.dart';
import 'package:named/features/practice/domain/practice_word.dart';
import 'package:named/features/practice/presentation/practice_page.dart';
import 'package:named/features/practice/providers/practice_providers.dart';
import 'package:named/features/progress/domain/progress.dart';
import 'package:named/features/progress/providers/progress_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

class _FakePracticeApi implements PracticeApi {
  var completions = 0;
  var replies = 0;
  var failReplies = false;

  @override
  Future<PracticeWordDto> next() {
    throw UnimplementedError();
  }

  @override
  Future<PracticeCompleteDto> complete(String wordId) async {
    completions += 1;
    return PracticeCompleteDto(wordId: wordId, practiceCount: 3);
  }

  @override
  Future<PracticeReplyDto> reply({
    required String wordId,
    required String text,
    required List<PracticeTurn> history,
  }) async {
    replies += 1;
    if (failReplies) {
      throw const ApiException(
        type: ApiExceptionType.server,
        message: 'failed',
      );
    }
    return const PracticeReplyDto(
      reply: 'That sounds nice.',
      recast: 'I saw a tree yesterday.',
      nativeReply: null,
    );
  }
}

PracticeWord _word() {
  return const PracticeWord(
    id: 'word-1',
    label: 'tree',
    word: DiscoveredWord(
      spelling: 'tree',
      ipa: {'us': '/triː/', 'uk': '/triː/'},
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
    context: '公园里的树',
    options: ['river', 'leaf'],
    practiceCount: 0,
  );
}

void main() {
  testWidgets('walks all five nodes and completes once', (tester) async {
    final api = _FakePracticeApi();

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          practiceSessionProvider.overrideWith((ref) async => _word()),
          practiceRepositoryProvider.overrideWithValue(PracticeRepository(api)),
          progressProvider.overrideWith(
            (ref) async => const Progress(
              words: 1,
              conversations: 0,
              readings: 0,
              practices: 0,
            ),
          ),
        ],
        child: const PracticePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.practice.understandTitle), findsOneWidget);

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const Key('practice.next')));
      await tester.pumpAndSettle();
    }

    expect(find.text(t.practice.useTitle), findsOneWidget);
    expect(api.completions, 0);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'I saw a tree in the park.',
    );
    await tester.ensureVisible(find.byKey(const Key('practice.send')));
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();
    expect(api.replies, 1);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'It was tall.',
    );
    await tester.ensureVisible(find.byKey(const Key('practice.send')));
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();
    expect(api.replies, 2);
    expect(find.byKey(const Key('practice.useInput')), findsNothing);

    await tester.tap(find.byKey(const Key('practice.next')));
    await tester.pumpAndSettle();

    expect(api.completions, 1);
    expect(find.text(t.practice.completeTitle), findsOneWidget);
    expect(
      find.text(t.practice.completeCount.replaceFirst('{count}', '3')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the session open when the reply fails', (tester) async {
    final api = _FakePracticeApi()..failReplies = true;

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          practiceSessionProvider.overrideWith((ref) async => _word()),
          practiceRepositoryProvider.overrideWithValue(PracticeRepository(api)),
          progressProvider.overrideWith(
            (ref) async => const Progress(
              words: 1,
              conversations: 0,
              readings: 0,
              practices: 0,
            ),
          ),
        ],
        child: const PracticePage(),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const Key('practice.next')));
      await tester.pumpAndSettle();
    }

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'I saw a tree in the park.',
    );
    await tester.ensureVisible(find.byKey(const Key('practice.send')));
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();

    expect(find.text(t.practice.useError), findsOneWidget);
    expect(find.byKey(const Key('practice.useInput')), findsOneWidget);
    expect(api.completions, 0);
  });

  testWidgets('shows the empty state when there are no saved words', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          practiceSessionProvider.overrideWith(
            (ref) async => throw const ApiException(
              type: ApiExceptionType.notFound,
              message: 'No words',
              code: 'practice_no_words',
            ),
          ),
          practiceRepositoryProvider.overrideWithValue(
            PracticeRepository(_FakePracticeApi()),
          ),
        ],
        child: const PracticePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.practice.emptyTitle), findsOneWidget);
    expect(find.text(t.practice.emptyCopy), findsOneWidget);
  });
}
