import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/providers/app_config_provider.dart';
import 'package:named/core/providers/key_value_storage_provider.dart';
import 'package:named/features/daily/presentation/daily_read_page.dart';
import 'package:named/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders the daily reading', (tester) async {
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

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: DailyReadPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A Quiet Morning'), findsOneWidget);
    expect(
      find.textContaining('Today I noticed a small thing'),
      findsOneWidget,
    );
    expect(find.text('notice'), findsOneWidget);
    expect(find.text(t.daily.question.toUpperCase()), findsNothing);

    await tester.tap(find.byKey(const Key('daily.translate')));
    await tester.pumpAndSettle();

    expect(find.text('今天我注意到窗边有一件小事。'), findsOneWidget);
    expect(find.text('光线慢慢在地板上移动。'), findsOneWidget);

    expect(find.byKey(const Key('daily.finish')), findsNothing);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily.completion')), findsOneWidget);
  });
}
