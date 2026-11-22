import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/soul/domain/soul.dart';
import 'package:named/features/soul/presentation/soul_page.dart';
import 'package:named/features/soul/providers/soul_providers.dart';

import 'support/i18n_test_helpers.dart';

const _soul = Soul(nativeLanguage: 'en');

void main() {
  testWidgets('shows a back control when opened from another page', (
    tester,
  ) async {
    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [soulProvider.overrideWith((ref) => _soul)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              key: const Key('openMe'),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const SoulPage())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('openMe')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('me.page')), findsOneWidget);
    expect(find.byKey(const Key('me.back')), findsOneWidget);

    await tester.tap(find.byKey(const Key('me.back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('me.page')), findsNothing);
  });

  testWidgets('has no back control when it is the root page', (tester) async {
    await pumpTemplateApp(
      tester,
      app: ProviderScope(
        overrides: [soulProvider.overrideWith((ref) => _soul)],
        child: const MaterialApp(home: SoulPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('me.back')), findsNothing);
  });
}
