import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:named/features/auth/presentation/sign_in_page.dart';
import 'package:named/features/home/presentation/home_page.dart';
import 'package:named/main.dart' as app;

/// Integration test entry point.
///
/// Run with:
///   flutter test integration_test/ --dart-define-from-file=config/dev.json
///
/// Add test files alongside this one, e.g.:
///   integration_test/auth_flow_test.dart
///   integration_test/home_page_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app starts and completes the dev sign-in smoke flow', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byType(SignInPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('signIn.devButton')));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(const Key('home.page')), findsOneWidget);
  });
}
