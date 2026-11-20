import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/challenge/domain/challenge.dart';
import 'package:named/features/challenge/providers/challenge_providers.dart';
import 'package:named/features/timeline/presentation/widgets/challenge_carousel.dart';

import 'support/i18n_test_helpers.dart';

Challenge _challenge(String id, String name, DateTime startedAt) {
  return Challenge(
    id: id,
    name: name,
    plannedDays: 2,
    status: ChallengeStatus.active,
    startedAt: startedAt,
    endedAt: null,
    createdAt: startedAt,
    totalCount: 2,
    visitedCount: 1,
    isDue: false,
    items: const [],
  );
}

void main() {
  testWidgets('shows the current challenge and a see-all link for others', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengesProvider.overrideWith(
            (ref) async => [
              _challenge('a', 'Alpha', DateTime(2026, 11, 12)),
              _challenge('b', 'Beta', DateTime(2026, 11, 13)),
            ],
          ),
        ],
        child: const ChallengeCarousel(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline.challenge.b')), findsOneWidget);
    expect(find.byKey(const Key('timeline.challenge.a')), findsNothing);
    expect(find.byKey(const Key('timeline.challenge.seeAll')), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('hides when there is no active challenge', (tester) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengesProvider.overrideWith((ref) async => const <Challenge>[]),
        ],
        child: const ChallengeCarousel(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline.challenge.seeAll')), findsNothing);
  });
}
