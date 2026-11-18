import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/providers/key_value_storage_provider.dart';
import 'package:named/features/auth/presentation/sign_in_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  Future<void> pumpSignIn(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SignInPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cannot reach the email step before finishing the language step',
    (tester) async {
      await pumpSignIn(tester);

      expect(find.byKey(const Key('signIn.nativeLanguage')), findsOneWidget);
      expect(find.byKey(const Key('signIn.email')), findsNothing);

      // A horizontal swipe must not advance the pager yet.
      await tester.drag(find.byType(PageView), const Offset(-360, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('signIn.email')), findsNothing);

      // Completing the first step reveals the email step.
      await tester.enterText(
        find.byKey(const Key('signIn.nativeLanguage')),
        '中文',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('signIn.continue')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('signIn.email')), findsOneWidget);
    },
  );
}
