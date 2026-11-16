import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/question/data/api/question_api.dart';
import 'package:named/features/question/data/repositories/question_repository.dart';
import 'package:named/features/question/presentation/question_page.dart';
import 'package:named/features/question/providers/question_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('asks a question and shows the answer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(
            QuestionRepository(MockQuestionApi()),
          ),
        ],
        child: const MaterialApp(home: QuestionPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.ask.emptyTitle), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('ask.input')),
      'Why do we say would here?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('ask.send')));
    await tester.pumpAndSettle();

    expect(find.text('Why do we say would here?'), findsOneWidget);
    expect(find.text('A simple answer to your question.'), findsOneWidget);
    expect(find.text('这是这个问题的中文解释。'), findsOneWidget);
  });
}
