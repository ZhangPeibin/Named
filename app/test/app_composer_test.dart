import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/widgets/app_composer.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('enables send only after text and calls onSend', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var sends = 0;

    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: AppComposer(
          controller: controller,
          hintText: 'Type your sentence',
          sendTooltip: 'Send',
          onSend: () => sends++,
          inputKey: const Key('composer.input'),
          sendKey: const Key('composer.send'),
        ),
      ),
    );

    final send = find.byKey(const Key('composer.send'));
    expect(tester.widget<IconButton>(send).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('composer.input')), 'Hello');
    await tester.pump();
    expect(tester.widget<IconButton>(send).onPressed, isNotNull);

    await tester.tap(send);
    expect(sends, 1);
  });

  testWidgets('blocks send while sending', (tester) async {
    final controller = TextEditingController(text: 'Hello');
    addTearDown(controller.dispose);

    await pumpWithTranslations(
      tester,
      child: Scaffold(
        body: AppComposer(
          controller: controller,
          hintText: 'Type your sentence',
          sendTooltip: 'Send',
          onSend: () {},
          isSending: true,
          sendKey: const Key('composer.send'),
        ),
      ),
    );

    final send = find.byKey(const Key('composer.send'));
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
