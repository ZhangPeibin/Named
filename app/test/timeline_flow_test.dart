import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/app.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/providers/app_config_provider.dart';
import 'package:named/features/auth/providers/auth_notifier.dart';
import 'package:named/features/soul/domain/soul.dart';
import 'package:named/features/soul/providers/soul_providers.dart';
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
    expect(find.text('under a tree'), findsOneWidget);
    expect(find.text('plant a tree'), findsNothing);
    expect(find.text('GRAMMAR'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('timeline.moreDetails.mock-discovery')),
    );
    await tester.tap(
      find.byKey(const Key('timeline.moreDetails.mock-discovery')),
    );
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
    await tester.tap(find.byKey(const Key('timeline.talk.mock-discovery')));
    await tester.pumpAndSettle();
    expect(find.text(t.talk.empty), findsOneWidget);
    expect(find.text('tree'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('talk.input')),
      'I saw a tree.',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('talk.send')));
    await tester.pumpAndSettle();

    expect(find.text('I saw a tree.'), findsOneWidget);
    expect(
      find.text(
        'That sounds like a small, real moment. What did you notice first?',
      ),
      findsOneWidget,
    );
    expect(find.text('那听起来像一个真实的小瞬间。你最先注意到了什么？'), findsOneWidget);

    final nativeToggle = find.byKey(
      const Key('talk.native.toggle.mock-message-2'),
    );
    await tester.ensureVisible(nativeToggle);
    await tester.tap(nativeToggle);
    await tester.pumpAndSettle();
    expect(find.text('那听起来像一个真实的小瞬间。你最先注意到了什么？'), findsNothing);

    await tester.tap(nativeToggle);
    await tester.pumpAndSettle();
    expect(find.text('那听起来像一个真实的小瞬间。你最先注意到了什么？'), findsOneWidget);

    final correctionCard = find.byKey(
      const Key('talk.correction.mock-message-1.0'),
    );
    await tester.ensureVisible(correctionCard);
    expect(correctionCard, findsOneWidget);
    expect(find.text(t.talk.naturalWay.toUpperCase()), findsOneWidget);

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
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.signedIn;
}
