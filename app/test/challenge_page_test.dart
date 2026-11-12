import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/challenge/data/api/challenge_api.dart';
import 'package:named/features/challenge/data/dto/challenge_dto.dart';
import 'package:named/features/challenge/data/repositories/challenge_repository.dart';
import 'package:named/features/challenge/domain/challenge.dart';
import 'package:named/features/challenge/presentation/challenge_detail_page.dart';
import 'package:named/features/challenge/presentation/challenges_page.dart';
import 'package:named/features/challenge/providers/challenge_providers.dart';
import 'package:named/i18n/strings.g.dart';

import 'support/i18n_test_helpers.dart';

class _FakeChallengeApi implements ChallengeApi {
  _FakeChallengeApi({this.empty = false});

  final bool empty;

  ChallengeDto get _challenge => ChallengeDto(
    id: 'challenge-1',
    name: '身边的小发现',
    plannedDays: 2,
    status: ChallengeStatus.active,
    startedAt: DateTime(2026, 11, 12, 9),
    endedAt: null,
    createdAt: DateTime(2026, 11, 12, 9),
    totalCount: 2,
    visitedCount: 1,
    isDue: false,
    items: [
      ChallengeItemDto(
        id: 'item-1',
        discoveryId: 'discovery-1',
        position: 0,
        visitedAt: DateTime(2026, 11, 12, 10),
        focusType: 'word',
        focusId: 'word-1',
        title: 'tree',
      ),
      const ChallengeItemDto(
        id: 'item-2',
        discoveryId: 'discovery-2',
        position: 1,
        visitedAt: null,
        focusType: 'scene',
        focusId: 'scene-1',
        title: 'A moment in the park',
      ),
    ],
  );

  @override
  Future<List<ChallengeDto>> fetch() async => empty ? [] : [_challenge];

  @override
  Future<ChallengeDto> fetchById(String id) async => _challenge;

  @override
  Future<ChallengeDto> create({
    required String name,
    required int plannedDays,
    required List<String> discoveryIds,
  }) async => _challenge;

  @override
  Future<ChallengeDto> markVisited(String challengeId, String itemId) async =>
      _challenge;

  @override
  Future<ChallengeDto> end(String id) async => _challenge;
}

void main() {
  testWidgets('shows active challenge and progress', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(
            ChallengeRepository(_FakeChallengeApi()),
          ),
        ],
        child: const ChallengesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('身边的小发现'), findsOneWidget);
    expect(find.text(t.challenge.active), findsOneWidget);
    expect(
      find.text(
        t.challenge.visitedOf
            .replaceFirst('{visited}', '1')
            .replaceFirst('{total}', '2'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('challenges.start')), findsOneWidget);
  });

  testWidgets('shows challenge detail and items', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(
            ChallengeRepository(_FakeChallengeApi()),
          ),
        ],
        child: const ChallengeDetailPage(challengeId: 'challenge-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('tree'), findsOneWidget);
    expect(find.text('A moment in the park'), findsOneWidget);
    expect(find.byKey(const Key('challenge.item.item-1')), findsOneWidget);
    expect(find.byKey(const Key('challenge.end')), findsOneWidget);
  });

  testWidgets('shows empty challenges state', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(
            ChallengeRepository(_FakeChallengeApi(empty: true)),
          ),
        ],
        child: const ChallengesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.challenge.empty), findsOneWidget);
    expect(find.byKey(const Key('challenges.startEmpty')), findsOneWidget);
  });
}
