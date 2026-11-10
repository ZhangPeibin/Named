import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/talk/data/api/talk_api.dart';
import 'package:named/features/talk/data/dto/talk_dto.dart';
import 'package:named/features/talk/data/repositories/talk_repository.dart';
import 'package:named/features/talk/presentation/talk_page.dart';
import 'package:named/features/talk/providers/talk_providers.dart';
import 'package:named/features/words/data/api/words_api.dart';
import 'package:named/features/words/data/repositories/words_repository.dart';
import 'package:named/features/words/providers/words_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

class _DelayedTalkApi extends MockTalkApi {
  final gate = Completer<void>();

  @override
  Future<TurnDto> sendMessage({
    required String conversationId,
    required String text,
    required String clientMessageId,
  }) async {
    await gate.future;
    return super.sendMessage(
      conversationId: conversationId,
      text: text,
      clientMessageId: clientMessageId,
    );
  }
}

void main() {
  testWidgets('shows the user message and typing before the reply arrives', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _DelayedTalkApi();

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          talkRepositoryProvider.overrideWithValue(TalkRepository(api)),
        ],
        child: const TalkPage(
          conversationId: 'mock-conversation',
          title: 'tree',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.talk.empty), findsOneWidget);
    expect(find.text(t.talk.miloName), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('talk.input')),
      'I saw a tree.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('talk.send')));
    await tester.pump();

    expect(find.text('I saw a tree.'), findsOneWidget);
    expect(find.byKey(const Key('talk.typing')), findsOneWidget);
    expect(find.byKey(const Key('talk.typing.avatar')), findsOneWidget);
    expect(find.byKey(const Key('talk.header.avatar')), findsOneWidget);

    api.gate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('talk.typing')), findsNothing);
    expect(find.byKey(const Key('talk.typing.avatar')), findsNothing);
    expect(
      find.textContaining('That sounds like a small, real moment.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('talk.avatar.mock-message-1')), findsOneWidget);
    expect(find.byKey(const Key('talk.avatar.mock-message-2')), findsOneWidget);
  });

  grammarTest();
}

class _RecordingWordsApi extends MockWordsApi {
  String? savedLabel;

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
  }) async {
    savedLabel = label;
  }
}

class _GrammarTalkApi extends MockTalkApi {
  @override
  Future<ConversationDto> fetch(String conversationId) async {
    return ConversationDto(
      id: conversationId,
      title: 'tree',
      focusType: 'word',
      focusId: 'mock-word',
      status: 'active',
      messages: const [
        TalkMessageDto(
          id: 'grammar-message',
          role: 'assistant',
          text:
              "Drink it plain. So you'll pour some water from the kettle for me.",
          corrections: [],
          annotations: [
            MessageAnnotationDto(
              text: 'plain',
              kind: 'word',
              meaningZh: '不加其他东西地；直接地',
              partOfSpeech: 'adv.',
              ipa: '/pleɪn/',
              syllables: 'plain',
              vowels: ['/eɪ/'],
              consonants: ['/p/', '/l/', '/n/'],
              phonics: 'ai 发 /eɪ/',
            ),
            MessageAnnotationDto(
              text: 'pour',
              kind: 'grammar',
              meaningZh: '从容器里倒出液体',
              grammar: 'pour + 液体 + from + 容器',
            ),
          ],
        ),
      ],
    );
  }
}

void grammarTest() {
  testWidgets('shows inline annotation markers and opens their notes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _GrammarTalkApi();
    final wordsApi = _RecordingWordsApi();
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          talkRepositoryProvider.overrideWithValue(TalkRepository(api)),
          wordsRepositoryProvider.overrideWithValue(WordsRepository(wordsApi)),
        ],
        child: const TalkPage(conversationId: 'grammar', title: 'tree'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('talk.annotation.plain')), findsOneWidget);
    expect(find.byKey(const Key('talk.annotation.pour')), findsOneWidget);
    expect(find.text('plain'), findsOneWidget);
    expect(find.textContaining('plain plain'), findsNothing);

    await tester.tap(find.byKey(const Key('talk.annotation.plain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('talk.annotationSheet')), findsOneWidget);
    expect(find.text('Part of speech: adv.'), findsOneWidget);
    expect(find.text('/pleɪn/'), findsOneWidget);
    expect(find.text(t.talk.vowels), findsOneWidget);
    expect(find.text('/eɪ/'), findsOneWidget);
    expect(find.text('ai 发 /eɪ/'), findsOneWidget);
    expect(find.text('不加其他东西地；直接地'), findsOneWidget);
    expect(find.byKey(const Key('talk.annotationAdd')), findsOneWidget);

    await tester.tap(find.byKey(const Key('talk.annotationAdd')));
    await tester.pumpAndSettle();
    expect(wordsApi.savedLabel, 'plain');
    expect(find.byKey(const Key('talk.annotationSheet')), findsNothing);

    await tester.tap(find.byKey(const Key('talk.annotation.pour')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('talk.annotationSheet')), findsOneWidget);
    expect(find.text('pour + 液体 + from + 容器'), findsOneWidget);
    expect(find.text('从容器里倒出液体'), findsOneWidget);

    await tester.tap(find.byKey(const Key('talk.annotationClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('talk.annotationSheet')), findsNothing);
  });
}
