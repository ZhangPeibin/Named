import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/widgets/app_button.dart';
import 'package:named/core/widgets/app_empty_view.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('shows the copy and runs the action', (tester) async {
    var taps = 0;

    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: AppEmptyView(
          title: 'No words yet',
          message: 'Save a word first.',
          action: AppButton(
            label: 'Open Words',
            variant: AppButtonVariant.secondary,
            expand: false,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('No words yet'), findsOneWidget);
    expect(find.text('Save a word first.'), findsOneWidget);

    await tester.tap(find.text('Open Words'));
    expect(taps, 1);
  });
}
