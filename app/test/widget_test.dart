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
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.signedIn;
}
