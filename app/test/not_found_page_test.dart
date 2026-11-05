import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/not_found/presentation/not_found_page.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('renders not found details', (WidgetTester tester) async {
    await pumpWithTranslations(
      tester,
      child: const NotFoundPage(location: '/missing'),
    );

    expect(find.text(t.notFound.title), findsNWidgets(2));
    expect(find.text(t.notFound.noRoute(location: '/missing')), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
