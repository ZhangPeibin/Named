import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/app.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/providers/app_config_provider.dart';
import 'package:named/features/auth/providers/auth_notifier.dart';
import 'package:named/features/companion/data/api/companion_api.dart';
import 'package:named/features/companion/data/dto/companion_dto.dart';
import 'package:named/features/companion/data/repositories/companion_repository.dart';
import 'package:named/features/companion/domain/companion_profile.dart';
import 'package:named/features/companion/providers/companion_providers.dart';
import 'package:named/features/soul/domain/soul.dart';
import 'package:named/features/soul/providers/soul_providers.dart';
import 'package:named/features/talk/data/api/talk_api.dart';
import 'package:named/features/talk/data/repositories/talk_repository.dart';
import 'package:named/features/talk/presentation/talk_page.dart';
import 'package:named/features/talk/providers/talk_providers.dart';
import 'package:named/features/timeline/providers/timeline_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.signedIn;
}

class _EmptyTimelineController extends TimelineController {
  @override
  Future<TimelineState> build() async {
    return const TimelineState(items: [], nextCursor: null);
  }
}

class _FakeCompanionApi implements CompanionApi {
  String? name;
  CompanionGender? gender;
  String? hobby;
  bool setupDismissed = false;

  @override
  Future<CompanionProfileDto> fetchCompanion() async {
    return _dto();
  }

  @override
  Future<CompanionProfileDto> updateCompanion(
    Map<String, dynamic> changes,
  ) async {
    if (changes.containsKey('name')) {
      name = changes['name'] as String?;
    }
    if (changes.containsKey('gender')) {
      gender = CompanionGender.fromWire(changes['gender'] as String?);
    }
    if (changes.containsKey('hobby')) {
      hobby = changes['hobby'] as String?;
    }
    if (changes.containsKey('setup_dismissed')) {
      setupDismissed = changes['setup_dismissed'] as bool? ?? false;
    }
    return _dto();
  }

  @override
  Future<String> suggestName() async {
    return 'Momo';
  }

  @override
  Future<CompanionProfileDto> assignRandomName() async {
    name = 'Momo';
    return _dto();
  }

  @override
  Future<CompanionPresenceDto> fetchPresence({required int localHour}) async {
    return const CompanionPresenceDto(key: 'morning', variant: 0);
  }

  CompanionProfileDto _dto() {
    return CompanionProfileDto(
      name: name,
      gender: gender,
      hobby: hobby,
      avatarKey: 'companion_chill',
      voiceKey: 'companion_default',
      setupDismissed: setupDismissed,
    );
  }
}

void main() {
  testWidgets('first-run names the companion', (tester) async {
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
    final api = _FakeCompanionApi();

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          soulProvider.overrideWith(
            (ref) async => const Soul(nativeLanguage: 'en'),
          ),
          timelineControllerProvider.overrideWith(_EmptyTimelineController.new),
          companionRepositoryProvider.overrideWithValue(
            CompanionRepository(api),
          ),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion.firstRun')), findsOneWidget);
    expect(find.text(t.companion.firstRunBody), findsOneWidget);

    await tester.tap(find.byKey(const Key('companion.nameMe')));
    await tester.pumpAndSettle();
    expect(find.text(t.companion.setupTitle), findsOneWidget);

    await tester.enterText(find.byKey(const Key('companion.nameInput')), 'Pip');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('companion.save')));
    await tester.tap(find.byKey(const Key('companion.save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion.saved')), findsOneWidget);
    expect(find.text(t.companion.namedFirstLine(name: 'Pip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('companion.start')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion.firstRun')), findsNothing);
    expect(api.name, 'Pip');
  });

  testWidgets('talk gate assigns a random companion name', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeCompanionApi();

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          talkRepositoryProvider.overrideWithValue(
            TalkRepository(MockTalkApi()),
          ),
          companionRepositoryProvider.overrideWithValue(
            CompanionRepository(api),
          ),
        ],
        child: const TalkPage(
          conversationId: 'mock-conversation',
          title: 'tree',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion.gate')), findsOneWidget);

    await tester.tap(find.byKey(const Key('companion.gate.random')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion.gate')), findsNothing);
    expect(find.text('What do you want to say about this?'), findsOneWidget);
    expect(api.name, 'Momo');
  });
}
