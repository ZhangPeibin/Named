import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/history/data/api/history_api.dart';
import 'package:named/features/history/data/dto/history_dto.dart';
import 'package:named/features/history/data/repositories/history_repository.dart';
import 'package:named/features/history/domain/history_experience.dart';
import 'package:named/features/history/presentation/experience_detail_page.dart';
import 'package:named/features/history/presentation/history_page.dart';
import 'package:named/features/history/providers/history_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

class _FakeHistoryApi implements HistoryApi {
  _FakeHistoryApi({this.empty = false});

  final bool empty;

  @override
  Future<HistoryPageDto> fetch({String? before}) async {
    if (empty) {
      return const HistoryPageDto(items: [], nextCursor: null);
    }
    final now = DateTime(2026, 11, 11, 10);
    return HistoryPageDto(
      items: [
        HistoryExperienceDto(
          id: 'life-1',
          kind: ExperienceKind.life,
          summary: '和女儿在公园的树荫下休息。',
          confidence: 0.9,
          createdAt: now,
          focusType: 'word',
          focusId: 'word-1',
          focusTitle: 'tree',
          conversationId: 'conversation-1',
        ),
        HistoryExperienceDto(
          id: 'learning-1',
          kind: ExperienceKind.learning,
          summary: '练习了 under the tree。',
          confidence: 0.8,
          createdAt: now,
          focusType: 'word',
          focusId: 'word-1',
          focusTitle: 'tree',
          conversationId: 'conversation-1',
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<HistoryExperienceDto> fetchExperience(String id) async {
    return HistoryExperienceDto(
      id: id,
      kind: ExperienceKind.life,
      summary: '和女儿在公园的树荫下休息。',
      confidence: 0.9,
      createdAt: DateTime(2026, 11, 11, 10),
      focusType: 'word',
      focusId: 'word-1',
      focusTitle: 'tree',
      conversationId: 'conversation-1',
      sources: const [
        ExperienceSourceDto(
          type: 'message',
          id: 'message-1',
          quote: '今天在公园看到一棵树。',
        ),
        ExperienceSourceDto(type: 'expression', id: 'under the tree'),
      ],
    );
  }
}

void main() {
  testWidgets('shows life and learning experiences in History', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(
            HistoryRepository(_FakeHistoryApi()),
          ),
        ],
        child: const HistoryPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('和女儿在公园的树荫下休息。'), findsOneWidget);
    expect(find.text('练习了 under the tree。'), findsOneWidget);
    expect(find.text(t.history.life), findsOneWidget);
    expect(find.text(t.history.learning), findsOneWidget);
    expect(find.byKey(const Key('history.experience.life-1')), findsOneWidget);
    expect(
      find.byKey(const Key('history.experience.learning-1')),
      findsOneWidget,
    );
  });

  testWidgets('shows empty History state', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(
            HistoryRepository(_FakeHistoryApi(empty: true)),
          ),
        ],
        child: const HistoryPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.history.empty), findsOneWidget);
    expect(find.text(t.history.emptyHint), findsOneWidget);
  });

  testWidgets('shows experience evidence and source action', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          historyRepositoryProvider.overrideWithValue(
            HistoryRepository(_FakeHistoryApi()),
          ),
        ],
        child: const ExperienceDetailPage(experienceId: 'life-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.history.evidence.toUpperCase()), findsOneWidget);
    expect(find.text('今天在公园看到一棵树。'), findsOneWidget);
    expect(find.text('under the tree'), findsOneWidget);
    expect(find.byKey(const Key('history.openConversation')), findsOneWidget);
  });
}
