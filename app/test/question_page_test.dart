import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/question/data/api/question_api.dart';
import 'package:named/features/question/data/repositories/question_repository.dart';
import 'package:named/features/question/domain/question.dart';
import 'package:named/features/question/presentation/question_page.dart';
import 'package:named/features/question/providers/question_providers.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('shows a contextual question draft', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(
            QuestionRepository(MockQuestionApi()),
          ),
        ],
        child: const MaterialApp(
          home: QuestionPage(
            context: QuestionContext(
              type: 'sentence',
              quote: 'If I had time, I would read more.',
            ),
            suggestedQuestion: 'Explain this sentence simply.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('If I had time, I would read more.'), findsOneWidget);
    expect(find.text('Explain this sentence simply.'), findsOneWidget);
  });

  testWidgets('shows a saved thread and asks a follow-up', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = MockQuestionApi();
    final thread = await api.ask('Why do we say would here?');

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(QuestionRepository(api)),
        ],
        child: MaterialApp(home: QuestionThreadPage(threadId: thread.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Why do we say would here?'), findsOneWidget);
    expect(find.text('A simple answer to your question.'), findsOneWidget);
    expect(find.text('Here is a short example.'), findsOneWidget);
    expect(find.text('这是这个问题的中文解释。'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('ask.input')),
      'Could I use will?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('ask.send')));
    await tester.pumpAndSettle();

    expect(find.text('Could I use will?'), findsOneWidget);
    expect(find.text('A follow-up answer.'), findsOneWidget);
    expect(find.text('这是追问后的中文解释。'), findsOneWidget);
  });
}
