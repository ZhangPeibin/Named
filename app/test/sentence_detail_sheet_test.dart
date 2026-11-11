import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/sentence/data/api/sentence_api.dart';
import 'package:named/features/sentence/data/repositories/sentence_repository.dart';
import 'package:named/features/sentence/presentation/sentence_detail_sheet.dart';
import 'package:named/features/sentence/providers/sentence_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

void main() {
  testWidgets('shows English, explanation, chunks, keywords and listen', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          sentenceRepositoryProvider.overrideWithValue(
            SentenceRepository(MockSentenceApi()),
          ),
        ],
        child: const SizedBox(
          height: 700,
          child: SentenceDetailSheet(text: '我今天很开心'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.talk.sentenceDetails), findsOneWidget);
    expect(find.text('I am happy today.'), findsOneWidget);
    expect(find.text('这是一句表达今天心情的话。'), findsOneWidget);
    expect(find.text('be happy'), findsOneWidget);
    expect(find.text('happy  开心的'), findsOneWidget);
    expect(find.byKey(const Key('sentence.audio')), findsOneWidget);
    expect(find.byKey(const Key('sentence.copyEnglish')), findsOneWidget);
  });
}
