import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/app/app.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/providers/app_config_provider.dart';
import 'package:named/features/auth/providers/auth_notifier.dart';
import 'package:named/features/todo_demo/domain/todo.dart';
import 'package:named/features/todo_demo/providers/todo_demo_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders template home page when signed in', (tester) async {
    const config = AppConfig(
      appName: 'Test App',
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.test',
    );

    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          authNotifierProvider.overrideWith(_SignedInAuthNotifier.new),
          demoTodoProvider.overrideWithValue(
            const AsyncValue.data(
              Todo(id: 1, userId: 1, title: 'Test todo', completed: false),
            ),
          ),
        ],
        child: const TemplateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test App'), findsNWidgets(2));
    expect(find.text('Environment: '), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
    expect(find.text('https://api.test'), findsOneWidget);
    expect(find.text(t.app.openApiDemo), findsOneWidget);

    await tester.tap(find.text(t.app.openApiDemo));
    await tester.pumpAndSettle();

    expect(find.text(t.todoDemo.title), findsOneWidget);
  });
}

class _SignedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthStatus> build() async => AuthStatus.signedIn;
}
