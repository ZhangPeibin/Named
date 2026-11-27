import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/sentence/data/api/sentence_api.dart';
import 'package:named/features/sentence/data/dto/sentence_dto.dart';
import 'package:named/features/sentence/providers/sentence_providers.dart';
import 'package:named/features/timeline/presentation/widgets/scene_translation.dart';

import 'support/i18n_test_helpers.dart';

class _FakeSentenceApi implements SentenceApi {
  @override
  Future<SentenceDetailDto> lookup(String text) async {
    return const SentenceDetailDto(
      original: 'I sat under the tree with my daughter yesterday.',
      naturalEnglish: 'I sat under the tree with my daughter yesterday.',
      translationNative: '昨天我和女儿坐在树下。',
      explanationNative: '这句话在讲昨天和女儿在树下度过的时光。',
      grammarNotes: '',
      chunks: [],
      keyWords: [],
    );
  }
}

void main() {
  testWidgets('long scene sentences can reveal a translation', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [sentenceApiProvider.overrideWithValue(_FakeSentenceApi())],
        child: const Scaffold(
          body: SceneTranslation(
            text: 'I sat under the tree with my daughter yesterday.',
          ),
        ),
      ),
    );

    expect(find.text('See translation'), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline.scene.translate')));
    await tester.pumpAndSettle();

    expect(find.text('昨天我和女儿坐在树下。'), findsOneWidget);
    expect(find.text('Hide translation'), findsOneWidget);

    await tester.tap(find.byKey(const Key('timeline.scene.translate')));
    await tester.pumpAndSettle();

    expect(find.text('昨天我和女儿坐在树下。'), findsNothing);
    expect(find.text('See translation'), findsOneWidget);
  });

  testWidgets('short scene sentences do not show a translation toggle', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [sentenceApiProvider.overrideWithValue(_FakeSentenceApi())],
        child: const Scaffold(body: SceneTranslation(text: 'I saw a tree.')),
      ),
    );

    expect(find.byKey(const Key('timeline.scene.translate')), findsNothing);
  });
}
