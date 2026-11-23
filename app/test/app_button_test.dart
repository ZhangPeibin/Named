import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/widgets/app_button.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders each variant with the expected Material button', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: Column(
          children: [
            AppButton(label: 'Primary', onPressed: () {}),
            AppButton(
              label: 'Secondary',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
            AppButton(
              label: 'Text',
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'Primary'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Secondary'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Text'), findsOneWidget);
  });

  testWidgets('disables the button and shows a spinner while loading', (
    tester,
  ) async {
    var taps = 0;

    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: AppButton(
          label: 'Save',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });
}
