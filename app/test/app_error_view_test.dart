import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/widgets/app_error_view.dart';

void main() {
  testWidgets('renders retry as a text button', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorView(
            message: 'Something failed.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
}
