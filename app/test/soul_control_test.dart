import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/soul/data/api/soul_api.dart';
import 'package:named/features/soul/data/dto/soul_dto.dart';
import 'package:named/features/soul/domain/soul.dart';
import 'package:named/features/soul/presentation/soul_page.dart';
import 'package:named/features/soul/providers/soul_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

const _soul = Soul(
  nativeLanguage: 'zh',
  items: [
    SoulItem(
      id: 'a',
      kind: 'interest',
      text: 'gardening',
      source: 'onboarding',
    ),
    SoulItem(id: 'b', kind: 'note', text: 'has a balcony', source: 'user_edit'),
    SoulItem(
      id: 'c',
      kind: 'note',
      text: 'likes morning walks',
      source: 'ai_extracted',
    ),
  ],
);

void main() {
  testWidgets('shows sources and deletes an item', (tester) async {
    final api = _FakeSoulApi();

    await _pumpSoulPage(tester, api);
    await tester.pumpAndSettle();

    expect(find.text('gardening'), findsOneWidget);
    expect(find.text(t.soul.sourceOnboarding), findsOneWidget);
    expect(find.text(t.soul.sourceUser), findsOneWidget);
    expect(find.text(t.soul.sourceAi), findsOneWidget);

    await tester.tap(find.byKey(const Key('soul.delete.b')));
    await tester.pumpAndSettle();
    expect(find.text(t.soul.deleteConfirmTitle), findsOneWidget);

    await tester.tap(find.text(t.soul.deleteItem));
    await tester.pumpAndSettle();

    expect(api.deleted, ['b']);
  });

  testWidgets('adds a new item through the sheet', (tester) async {
    final api = _FakeSoulApi();

    await _pumpSoulPage(tester, api);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('soul.addItem')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('soul.itemText')),
      'plays piano',
    );
    await tester.tap(find.byKey(const Key('soul.itemSave')));
    await tester.pumpAndSettle();

    expect(api.created, ['plays piano']);
  });
}

Future<void> _pumpSoulPage(WidgetTester tester, SoulApi api) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpWithTranslations(
    tester,
    child: ProviderScope(
      overrides: [
        soulProvider.overrideWith((ref) => _soul),
        soulApiProvider.overrideWithValue(api),
      ],
      child: const SoulPage(),
    ),
  );
}

class _FakeSoulApi implements SoulApi {
  final List<String> deleted = [];
  final List<String> created = [];

  @override
  Future<SoulDto> fetchSoul() async {
    return SoulDto(
      nativeLanguage: _soul.nativeLanguage,
      items: _soul.items
          .map(
            (item) => SoulItemDto(
              id: item.id,
              kind: item.kind,
              text: item.text,
              source: item.source,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<SoulDto> updateSoul({
    required String nativeLanguage,
    int? age,
    String? gender,
  }) async {
    return fetchSoul();
  }

  @override
  Future<SoulItemDto> createItem({
    required String kind,
    required String text,
  }) async {
    created.add(text);
    return SoulItemDto(
      id: 'new-${created.length}',
      kind: kind,
      text: text,
      source: 'user_edit',
    );
  }

  @override
  Future<SoulItemDto> updateItem({
    required String id,
    required String kind,
    required String text,
  }) async {
    return SoulItemDto(id: id, kind: kind, text: text, source: 'user_edit');
  }

  @override
  Future<void> deleteItem(String id) async {
    deleted.add(id);
  }
}
