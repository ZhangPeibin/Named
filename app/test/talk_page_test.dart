import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets('shows an English hint under a Chinese user message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          talkRepositoryProvider.overrideWithValue(
            TalkRepository(_ChineseTalkApi()),
          ),
        ],
        child: const TalkPage(conversationId: 'chinese', title: 'tree'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我看到一棵树。'), findsOneWidget);
    expect(find.text('I saw a tree.'), findsOneWidget);
    expect(
      find.byKey(const Key('talk.english.chinese-message')),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows accurate English for an English message only when needed',
    (tester) async {
      await pumpWithTranslations(
        tester,
        child: ProviderScope(
          overrides: [
            talkRepositoryProvider.overrideWithValue(
              TalkRepository(_EnglishHintTalkApi()),
            ),
          ],
          child: const TalkPage(conversationId: 'english-hint', title: 'tree'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('She go to school.'), findsOneWidget);
      expect(find.text('She goes to school.'), findsOneWidget);
      expect(find.text('I saw a tree.'), findsOneWidget);
      expect(find.text('I saw a tree.\nI saw a tree.'), findsNothing);
    },
  );

  testWidgets('long press opens copy and word details actions', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          talkRepositoryProvider.overrideWithValue(
            TalkRepository(_GrammarTalkApi()),
          ),
          wordsRepositoryProvider.overrideWithValue(
            WordsRepository(MockWordsApi()),
          ),
        ],
        child: const TalkPage(conversationId: 'word-details', title: 'tree'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('Drink it plain'));
    await tester.pumpAndSettle();
    expect(find.text(t.timeline.wordDetails), findsOneWidget);
    expect(find.text(t.talk.copy), findsOneWidget);
    expect(find.text(t.talk.sentenceDetails), findsNothing);
    await tester.tap(find.text(t.timeline.wordDetails));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wordDetails.close')), findsOneWidget);
  });

  testWidgets('tapping an annotation word opens its notes', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          talkRepositoryProvider.overrideWithValue(
            TalkRepository(_GrammarTalkApi()),
          ),
          wordsRepositoryProvider.overrideWithValue(
            WordsRepository(_RecordingWordsApi()),
          ),
        ],
        child: const TalkPage(conversationId: 'grammar-tap', title: 'tree'),
      ),
    );
    await tester.pumpAndSettle();

    final richText = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('Drink it plain'),
    );
    final render = tester.renderObject<RenderParagraph>(richText);
    final plain = (tester.widget<RichText>(richText).text as TextSpan)
        .toPlainText();
    final start = plain.indexOf('plain');
    final boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + 'plain'.length),
    );
    expect(boxes, isNotEmpty);
    final box = boxes.first;
    final topLeft = tester.getTopLeft(richText);
    await tester.tapAt(
      topLeft + Offset((box.left + box.right) / 2, (box.top + box.bottom) / 2),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('talk.annotationSheet')), findsOneWidget);
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

class _ChineseTalkApi extends MockTalkApi {
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
          id: 'chinese-message',
          role: 'user',
          text: '我看到一棵树。',
          englishText: 'I saw a tree.',
          corrections: [],
          annotations: [],
        ),
      ],
    );
  }
}

class _EnglishHintTalkApi extends MockTalkApi {
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
          id: 'english-hint-message',
          role: 'user',
          text: 'She go to school.',
          englishText: 'She goes to school.',
          corrections: [],
          annotations: [],
        ),
        TalkMessageDto(
          id: 'natural-english-message',
          role: 'user',
          text: 'I saw a tree.',
          corrections: [],
          annotations: [],
        ),
      ],
    );
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
              text: 'pour',
              kind: 'grammar',
              meaningZh: '从容器里倒出液体',
              grammar: 'pour + 液体 + from + 容器',
            ),
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
          ],
        ),
      ],
    );
  }
}

TextSpan? _findSpan(TextSpan span, String text) {
  if (span.text == text) {
    return span;
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) {
      final found = _findSpan(child, text);
      if (found != null) {
        return found;
      }
    }
  }
  return null;
}

Future<void> _tapAnnotation(WidgetTester tester, String text) async {
  final richText = tester
      .widgetList<RichText>(find.byType(RichText))
      .firstWhere((widget) => widget.text.toPlainText().contains(text));
  final span = _findSpan(richText.text as TextSpan, text);
  expect(span, isNotNull);
  final recognizer = span!.recognizer;
  expect(recognizer, isA<TapGestureRecognizer>());
  (recognizer! as TapGestureRecognizer).onTap!();
  await tester.pumpAndSettle();
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

    expect(find.textContaining('Drink it plain'), findsOneWidget);
    expect(find.textContaining('plain plain'), findsNothing);

    await _tapAnnotation(tester, 'plain');
    expect(find.byKey(const Key('talk.annotationSheet')), findsOneWidget);
    expect(find.byKey(const Key('talk.annotationAudio.speed')), findsOneWidget);
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

    await _tapAnnotation(tester, 'pour');

    expect(find.byKey(const Key('talk.annotationSheet')), findsOneWidget);
    expect(find.text('pour + 液体 + from + 容器'), findsOneWidget);
    expect(find.text('从容器里倒出液体'), findsOneWidget);
    expect(find.byKey(const Key('talk.annotationAdd')), findsNothing);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('talk.annotationSheet')), findsNothing);
  });
}
