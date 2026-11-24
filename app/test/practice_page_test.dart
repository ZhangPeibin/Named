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

Offset _swipeStart(WidgetTester tester) {
  final box = tester.getRect(find.byKey(const Key('practice.pages')));
  return Offset(box.center.dx, box.top + 120);
}

Future<void> _swipeNext(WidgetTester tester) async {
  await tester.dragFrom(_swipeStart(tester), const Offset(-350, 0));
  await tester.pumpAndSettle();
}

Future<void> _swipeBack(WidgetTester tester) async {
  await tester.dragFrom(_swipeStart(tester), const Offset(350, 0));
  await tester.pumpAndSettle();
}

Future<void> _swipeNextAfterCheck(WidgetTester tester) async {
  await tester.dragFrom(_swipeStart(tester), const Offset(-350, 0));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _advanceToUse(WidgetTester tester) async {
  await _swipeNext(tester);
  await _swipeNext(tester);
  await tester.tap(find.byKey(const Key('practice.option.tree')));
  await tester.pumpAndSettle();
  await _swipeNext(tester);
  await tester.enterText(find.byKey(const Key('practice.recallInput')), 'tree');
  await tester.pump();
  await _swipeNextAfterCheck(tester);
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
    expect(find.text(t.practice.swipeHint), findsOneWidget);
    expect(
      find.text('There is a tree in the park.', findRichText: true),
      findsOneWidget,
    );

    await _swipeNext(tester);
    expect(find.text(t.practice.swipeHint), findsNothing);

    await _swipeBack(tester);
    await _swipeNext(tester);
    await _swipeNext(tester);
    await tester.tap(find.byKey(const Key('practice.option.tree')));
    await tester.pumpAndSettle();
    await _swipeNext(tester);
    await tester.enterText(
      find.byKey(const Key('practice.recallInput')),
      'tree',
    );
    await tester.pump();
    await _swipeNextAfterCheck(tester);

    expect(find.text(t.practice.useTitle), findsOneWidget);
    expect(find.byKey(const Key('practice.finish')), findsOneWidget);
    expect(api.completions, 0);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'I saw a tree in the park.',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('practice.send')));
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();
    expect(api.replies, 1);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'It was tall.',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('practice.send')));
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();
    expect(api.replies, 2);

    await tester.tap(find.byKey(const Key('practice.finish')));
    await tester.pumpAndSettle();

    expect(api.completions, 1);
    expect(find.text(t.practice.completeTitle), findsOneWidget);
    expect(
      find.text(t.practice.completeCount.replaceFirst('{count}', '3')),
      findsOneWidget,
    );
  });

  testWidgets('fits a phone viewport through the conversation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await _advanceToUse(tester);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'I saw a tree in the park.',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('practice.send')));
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
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

    await _advanceToUse(tester);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'I saw a tree in the park.',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('practice.send')));
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();

    expect(find.text(t.practice.useError), findsOneWidget);
    expect(find.byKey(const Key('practice.useInput')), findsOneWidget);
    expect(api.completions, 0);
  });

  testWidgets('gates recognise and recall until the learner acts', (
    tester,
  ) async {
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

    await _swipeNext(tester);
    await _swipeNext(tester);
    expect(find.text(t.practice.recogniseTitle), findsOneWidget);
    expect(find.text('There is a ____ in the park.'), findsOneWidget);

    await _swipeNext(tester);
    expect(find.text(t.practice.recogniseTitle), findsOneWidget);
    expect(find.text(t.practice.swipeBlockedHint), findsOneWidget);

    await tester.tap(find.byKey(const Key('practice.option.tree')));
    await tester.pumpAndSettle();
    expect(find.text(t.practice.recogniseCorrect), findsOneWidget);
    await _swipeNext(tester);
    expect(find.text(t.practice.recallTitle), findsOneWidget);

    await _swipeNext(tester);
    expect(find.text(t.practice.recallTitle), findsOneWidget);
    expect(find.text(t.practice.swipeBlockedHint), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('practice.recallInput')),
      'river',
    );
    await tester.pump();
    await _swipeNext(tester);
    expect(find.text(t.practice.recallTitle), findsOneWidget);
    expect(
      find.text(t.practice.recallWrong.replaceFirst('{word}', 'tree')),
      findsOneWidget,
    );

    await _swipeNext(tester);
    expect(find.text(t.practice.useTitle), findsOneWidget);
  });

  testWidgets('reveals recall hints one step at a time', (tester) async {
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

    await _swipeNext(tester);
    await _swipeNext(tester);
    await tester.tap(find.byKey(const Key('practice.option.tree')));
    await tester.pumpAndSettle();
    await _swipeNext(tester);

    expect(find.byKey(const Key('practice.hint.firstLetter')), findsOneWidget);
    expect(find.byKey(const Key('practice.hint.answer')), findsNothing);

    await tester.tap(find.byKey(const Key('practice.hint.firstLetter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practice.hint.ipa')), findsOneWidget);

    await tester.tap(find.byKey(const Key('practice.hint.ipa')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practice.hint.audio')), findsOneWidget);

    await tester.tap(find.byKey(const Key('practice.hint.audio')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practice.hint.answer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('practice.hint.answer')));
    await tester.pumpAndSettle();
    await _swipeNext(tester);
    expect(find.text(t.practice.useTitle), findsOneWidget);
  });

  testWidgets('keeps finish disabled until two replies and starts another', (
    tester,
  ) async {
    var loads = 0;
    final api = _FakePracticeApi();
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          practiceSessionProvider.overrideWith((ref) async {
            loads += 1;
            return _word();
          }),
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

    await _advanceToUse(tester);
    await tester.tap(find.byKey(const Key('practice.finish')));
    await tester.pumpAndSettle();
    expect(api.completions, 0);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'I saw a tree in the park.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice.finish')));
    await tester.pumpAndSettle();
    expect(api.completions, 0);

    await tester.enterText(
      find.byKey(const Key('practice.useInput')),
      'It was tall.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('practice.send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice.finish')));
    await tester.pumpAndSettle();
    expect(api.completions, 1);

    expect(find.text(t.practice.completeTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('practice.another')));
    await tester.pumpAndSettle();
    expect(find.text(t.practice.understandTitle), findsOneWidget);
    expect(loads, 2);
  });

  testWidgets('allows swiping back to review previous steps', (tester) async {
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
    await _advanceToUse(tester);
    expect(find.text(t.practice.useTitle), findsOneWidget);

    await _swipeBack(tester);
    expect(find.text(t.practice.recallTitle), findsOneWidget);
    await _swipeBack(tester);
    expect(find.text(t.practice.recogniseTitle), findsOneWidget);

    await _swipeNext(tester);
    expect(find.text(t.practice.recallTitle), findsOneWidget);
    await _swipeNext(tester);
    expect(find.text(t.practice.useTitle), findsOneWidget);
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
