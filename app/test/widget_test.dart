import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/app.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/providers/app_config_provider.dart';
import 'package:named/features/assistant/data/api/assistant_api.dart';
import 'package:named/features/assistant/data/repositories/assistant_repository.dart';
import 'package:named/features/assistant/domain/assistant_intent.dart';
import 'package:named/features/assistant/providers/assistant_providers.dart';
import 'package:named/features/auth/providers/auth_notifier.dart';
import 'package:named/features/challenge/presentation/challenge_create_page.dart';
import 'package:named/features/challenge/presentation/challenges_page.dart';
import 'package:named/features/soul/domain/soul.dart';
import 'package:named/features/soul/providers/soul_providers.dart';
import 'package:named/features/words/presentation/words_page.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders the timeline and opens Me from the header', (
    tester,
  ) async {
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

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text(t.timeline.emptyTitle), findsOneWidget);
    expect(find.byKey(const Key('timeline.composer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline.me')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('me.page')), findsOneWidget);
  });

  testWidgets('rotates command hints while empty and pauses while typing', (
    tester,
  ) async {
    await _pumpTimeline(tester);

    final hints = {
      t.timeline.composerHint,
      t.timeline.composerHintWords,
      t.timeline.composerHintReview,
      t.timeline.composerHintStartChallenge,
      t.timeline.composerHintViewChallenges,
    };
    final first = _composerHint(tester);
    expect(hints, contains(first));

    await tester.pump(const Duration(seconds: 7));
    final second = _composerHint(tester);
    expect(hints, contains(second));
    expect(second, isNot(first));

    await tester.enterText(find.byKey(const Key('timeline.composer')), 'hello');
    await tester.pump();
    final paused = _composerHint(tester);
    await tester.pump(const Duration(seconds: 7));
    expect(_composerHint(tester), paused);

    await tester.enterText(find.byKey(const Key('timeline.composer')), '');
    await tester.pump();
    expect(_composerHint(tester), isNot(paused));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  _navigationTests();
}

Future<void> _pumpTimeline(
  WidgetTester tester, {
  AppLocale locale = AppLocale.en,
}) async {
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
    locale: locale,
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
}

String _composerHint(WidgetTester tester) {
  final field = tester.widget<TextField>(
    find.byKey(const Key('timeline.composer')),
  );
  return field.decoration?.hintText ?? '';
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.signedIn;
}

class _FakeAssistantRepository extends AssistantRepository {
  _FakeAssistantRepository(this.intent) : super(const MockAssistantApi());

  final AssistantIntent intent;
  final calls = <String>[];

  @override
  Future<AssistantIntentResult> route(String text) async {
    calls.add(text);
    return AssistantIntentResult(intent: intent, confidence: 0.95);
  }
}

Future<_FakeAssistantRepository> _pumpTimelineWithIntent(
  WidgetTester tester,
  AssistantIntent intent,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final assistant = _FakeAssistantRepository(intent);
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
        assistantRepositoryProvider.overrideWithValue(assistant),
        authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
        soulProvider.overrideWith(
          (ref) async => const Soul(nativeLanguage: 'en'),
        ),
      ],
      child: const TemplateApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('timeline.composer')),
    'review words',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('timeline.send')));
  await tester.pumpAndSettle();
  return assistant;
}

void _navigationTests() {
  testWidgets('open words command opens Words', (tester) async {
    await _pumpTimelineWithIntent(tester, AssistantIntent.openWords);

    expect(find.byType(WordsPage), findsOneWidget);
  });

  testWidgets('review command opens Review', (tester) async {
    final assistant = await _pumpTimelineWithIntent(
      tester,
      AssistantIntent.reviewWords,
    );

    expect(assistant.calls, ['review words']);
    expect(find.text(t.review.title), findsOneWidget);
  });

  testWidgets('start challenge command opens challenge creation', (
    tester,
  ) async {
    await _pumpTimelineWithIntent(tester, AssistantIntent.startChallenge);

    expect(find.byType(ChallengeCreatePage), findsOneWidget);
  });

  testWidgets('view challenges command opens challenge list', (tester) async {
    await _pumpTimelineWithIntent(tester, AssistantIntent.viewChallenges);

    expect(find.byType(ChallengesPage), findsOneWidget);
  });
}
