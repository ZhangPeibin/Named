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
  testWidgets('renders the timeline with dock and opens the page menu', (
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

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text(t.navigation.explore), findsOneWidget);
    expect(find.text(t.navigation.words), findsOneWidget);
    expect(find.text(t.navigation.history), findsOneWidget);
    expect(find.text(t.navigation.challenge), findsOneWidget);
    expect(find.text(t.navigation.me), findsOneWidget);
    expect(find.text(t.timeline.emptyTitle), findsOneWidget);
    expect(find.byKey(const Key('timeline.composer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline.menu')));
    await tester.pumpAndSettle();

    expect(find.text(t.timeline.menuWords), findsNWidgets(2));
    expect(find.text(t.timeline.menuSettings), findsOneWidget);

    await tester.tap(find.text(t.timeline.menuWords).last);
    await tester.pumpAndSettle();
    expect(find.text(t.words.empty), findsOneWidget);
  });
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.signedIn;
}
