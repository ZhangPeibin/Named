import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/app.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/providers/app_config_provider.dart';
import 'package:named/core/speech/speech_providers.dart';
import 'package:named/core/speech/voice_input.dart';
import 'package:named/features/auth/providers/auth_notifier.dart';
import 'package:named/features/discover/data/api/discover_api.dart';
import 'package:named/features/discover/data/dto/discover_dto.dart';
import 'package:named/features/discover/providers/discover_providers.dart';
import 'package:named/features/soul/domain/soul.dart';
import 'package:named/features/soul/providers/soul_providers.dart';
import 'package:named/features/timeline/domain/timeline_item.dart';
import 'package:named/features/timeline/providers/timeline_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('name a thing, talk, and return to a talk event', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      appName: 'Test App',
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test',
      useMockApi: true,
    );

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          soulProvider.overrideWith(
            (ref) async => const Soul(nativeLanguage: 'en'),
          ),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('timeline.composer')), 'tree');
    await tester.pump();
    await tester.tap(find.byKey(const Key('timeline.send')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('timeline.word.mock-discovery')),
      findsOneWidget,
    );
    expect(find.text('a tall tree'), findsOneWidget);
    expect(find.text('under a tree'), findsNothing);
    expect(find.text('plant a tree'), findsNothing);
    expect(find.text('GRAMMAR'), findsNothing);

    await tester.tap(find.byKey(const Key('timeline.word.mock-discovery')));
    await tester.pumpAndSettle();

    expect(find.text(t.timeline.wordDetails), findsOneWidget);
    expect(find.text('plant a tree'), findsOneWidget);
    expect(find.text('GRAMMAR'), findsOneWidget);
    expect(find.text(t.timeline.sceneExtensions.toUpperCase()), findsOneWidget);

    await tester.tap(find.byKey(const Key('wordDetails.close')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('timeline.talk.mock-discovery')),
    );
    expect(find.text(t.timeline.talkAboutIt), findsOneWidget);
    await tester.tap(find.byKey(const Key('timeline.talk.mock-discovery')));
    await tester.pumpAndSettle();
    expect(find.text(t.talk.empty), findsOneWidget);
    expect(find.text('tree'), findsOneWidget);

    await tester.tap(find.byKey(const Key('talk.help')));
    await tester.pumpAndSettle();
    expect(find.text(t.talk.helpTitle), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('talk.helpInput')),
      '我想说这棵树很漂亮',
    );
    await tester.tap(find.byKey(const Key('talk.helpAsk')));
    await tester.pumpAndSettle();
    expect(find.text('This tree is beautiful.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('talk.helpUseThis')));
    await tester.pumpAndSettle();
    final helpInput = tester.widget<TextField>(
      find.byKey(const Key('talk.input')),
    );
    expect(helpInput.controller?.text, 'This tree is beautiful.');

    await tester.enterText(
      find.byKey(const Key('talk.input')),
      'I saw a tree.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('talk.send')));
    await tester.pumpAndSettle();

    expect(find.text('I saw a tree.'), findsOneWidget);
    expect(
      find.textContaining('That sounds like a small, real moment.'),
      findsOneWidget,
    );
    expect(find.text('那听起来像一个真实的小瞬间。你最先注意到了什么？'), findsNothing);

    final nativeToggle = find.byKey(
      const Key('talk.native.toggle.mock-message-2'),
    );
    await tester.ensureVisible(nativeToggle);
    await tester.tap(nativeToggle);
    await tester.pumpAndSettle();
    expect(find.text('那听起来像一个真实的小瞬间。你最先注意到了什么？'), findsOneWidget);

    await tester.tap(nativeToggle);
    await tester.pumpAndSettle();
    expect(find.text('那听起来像一个真实的小瞬间。你最先注意到了什么？'), findsNothing);

    final correctionCard = find.byKey(
      const Key('talk.correction.mock-message-1.0'),
    );
    await tester.ensureVisible(correctionCard);
    expect(correctionCard, findsOneWidget);
    expect(find.text(t.talk.naturalWay.toUpperCase()), findsOneWidget);
    expect(
      find.byKey(const ValueKey('audio.talk.correction.mock-message-1.0.play')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('talk.correction.use.mock-message-1.0')),
    );
    await tester.pumpAndSettle();
    final input = tester.widget<TextField>(find.byKey(const Key('talk.input')));
    expect(input.controller?.text, 'I saw a tree today.');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('timeline.talkEvent.mock-conversation-1')),
      findsOneWidget,
    );
  });

  testWidgets('creates a moment card for a Chinese sentence', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      appName: 'Test App',
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test',
      useMockApi: true,
    );

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          soulProvider.overrideWith(
            (ref) async => const Soul(nativeLanguage: 'zh'),
          ),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('timeline.composer')),
      '我在公园看到一棵树。',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('timeline.send')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('timeline.scene.mock-scene-discovery')),
      findsOneWidget,
    );
    expect(find.text('I saw a tree in the park.'), findsOneWidget);
    expect(
      find.byKey(const Key('timeline.talk.mock-scene-discovery')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('timeline.talk.mock-scene-discovery')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('talk.input')), findsOneWidget);
  });

  testWidgets('tapping the timeline dismisses the keyboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      appName: 'Test App',
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test',
      useMockApi: true,
    );

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          soulProvider.overrideWith(
            (ref) async => const Soul(nativeLanguage: 'en'),
          ),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('timeline.composer')), 'tree');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(200, 300));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('scrolls to the newest card when a word lands', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      appName: 'Test App',
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test',
      useMockApi: true,
    );

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          soulProvider.overrideWith(
            (ref) async => const Soul(nativeLanguage: 'en'),
          ),
          timelineControllerProvider.overrideWith(
            _SeededTimelineController.new,
          ),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('timeline.composer')), 'tree');
    await tester.pump();
    await tester.tap(find.byKey(const Key('timeline.send')));
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(
      find.byKey(const Key('timeline.list')),
    );
    final controller = list.controller!;
    expect(controller.hasClients, isTrue);
    expect(
      controller.position.pixels,
      closeTo(controller.position.maxScrollExtent, 1),
    );
  });

  testWidgets('shows a pending card while naming is in flight', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      appName: 'Test App',
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test',
      useMockApi: true,
    );
    final discover = _DelayedDiscoverApi();

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          soulProvider.overrideWith(
            (ref) async => const Soul(nativeLanguage: 'en'),
          ),
          discoverApiProvider.overrideWithValue(discover),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('timeline.composer')), 'tree');
    await tester.pump();
    await tester.tap(find.byKey(const Key('timeline.send')));
    await tester.pump();

    expect(find.text(t.timeline.naming), findsOneWidget);
    expect(find.byKey(const Key('timeline.word.mock-discovery')), findsNothing);

    discover.gate.complete();
    await tester.pumpAndSettle();

    expect(find.text(t.timeline.naming), findsNothing);
    expect(
      find.byKey(const Key('timeline.word.mock-discovery')),
      findsOneWidget,
    );
  });

  testWidgets('dictation sends the transcript directly', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const config = AppConfig(
      appName: 'Test App',
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test',
      useMockApi: true,
    );
    final voice = _FakeVoiceInput();

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          soulProvider.overrideWith(
            (ref) async => const Soul(nativeLanguage: 'en'),
          ),
          voiceInputProvider.overrideWithValue(voice),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('timeline.voice')));
    await tester.pumpAndSettle();
    expect(find.text(t.timeline.listening), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline.voice')));
    await tester.pumpAndSettle();

    expect(voice.stopped, isTrue);
    expect(
      find.byKey(const Key('timeline.word.mock-discovery')),
      findsOneWidget,
    );
  });
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.signedIn;
}

class _FakeVoiceInput implements VoiceInput {
  var _recording = false;
  var stopped = false;

  @override
  bool get isRecording => _recording;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start() async {
    _recording = true;
  }

  @override
  Future<String?> stopAndTranscribe() async {
    _recording = false;
    stopped = true;
    return 'tree';
  }

  @override
  Future<void> dispose() async {}
}

class _DelayedDiscoverApi extends MockDiscoverApi {
  final gate = Completer<void>();

  @override
  Future<DiscoverDto> createText({
    required String text,
    String? context,
  }) async {
    await gate.future;
    return super.createText(text: text, context: context);
  }
}

class _SeededTimelineController extends TimelineController {
  @override
  Future<TimelineState> build() async {
    final now = DateTime.now();
    return TimelineState(
      items: [
        for (var i = 0; i < 20; i++)
          TimelineTalkItem(
            id: 'seed-$i',
            createdAt: now.subtract(Duration(minutes: 20 - i)),
            conversationId: 'c$i',
            title: 'Seed $i',
            lastMessageRole: 'user',
            lastMessageText:
                'A quiet message number $i that wraps across a couple of lines.',
            messageCount: 1,
          ),
      ],
      nextCursor: null,
    );
  }
}
