import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/challenge/domain/challenge.dart';
import 'package:named/features/challenge/providers/challenge_providers.dart';
import 'package:named/features/timeline/presentation/widgets/challenge_carousel.dart';

import 'support/i18n_test_helpers.dart';

Challenge _challenge(String id, String name) {
  return Challenge(
    id: id,
    name: name,
    plannedDays: 2,
    status: ChallengeStatus.active,
    startedAt: DateTime(2026, 11, 12),
    endedAt: null,
    createdAt: DateTime(2026, 11, 12),
    totalCount: 2,
    visitedCount: 1,
    isDue: false,
    items: const [],
  );
}

void main() {
  testWidgets('shows active challenges and swipes between them', (
    tester,
  ) async {
    await pumpWithTranslations(
      tester,
      child: ProviderScope(
        overrides: [
          challengesProvider.overrideWith(
            (ref) async => [_challenge('a', 'Alpha'), _challenge('b', 'Beta')],
          ),
        ],
        child: const ChallengeCarousel(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline.challenge.a')), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline.challenge.b')), findsOneWidget);
  });
}
