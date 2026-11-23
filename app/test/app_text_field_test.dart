import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/widgets/app_text_field.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders a label, description, and error around the field', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: const Scaffold(
        body: AppField(
          label: 'Your answer',
          description: 'Type the word you heard.',
          error: 'This field is required.',
          child: AppTextField(hintText: 'Word'),
        ),
      ),
    );

    expect(find.text('Your answer'), findsOneWidget);
    expect(find.text('Type the word you heard.'), findsOneWidget);
    expect(find.text('This field is required.'), findsOneWidget);
    expect(find.text('Word'), findsOneWidget);
  });
}
