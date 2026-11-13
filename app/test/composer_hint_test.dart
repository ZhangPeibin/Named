import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/timeline/presentation/composer_hint.dart';
import 'package:named/i18n/strings_zh.g.dart';

const _options = [
  ComposerHintOption(
    category: ComposerHintCategory.discovery,
    text: 'What did you see?',
  ),
  ComposerHintOption(
    category: ComposerHintCategory.openWords,
    text: 'Try my words',
  ),
  ComposerHintOption(
    category: ComposerHintCategory.review,
    text: 'Try review words',
  ),
  ComposerHintOption(
    category: ComposerHintCategory.startChallenge,
    text: 'Try start a challenge',
  ),
  ComposerHintOption(
    category: ComposerHintCategory.viewChallenges,
    text: 'Try show my challenge',
  ),
];

void main() {
  test('weights review and challenge hints by current state', () {
    final idle = composerHintWeights(hasActiveChallenge: null, reviewCount: 0);
    expect(idle[ComposerHintCategory.discovery], 3);
    expect(idle[ComposerHintCategory.openWords], 3);
    expect(idle[ComposerHintCategory.review], 1);
    expect(idle[ComposerHintCategory.startChallenge], 3.5);
    expect(idle[ComposerHintCategory.viewChallenges], 3.5);

    final review = composerHintWeights(
      hasActiveChallenge: false,
      reviewCount: 3,
    );
    expect(review[ComposerHintCategory.review], 6);
    expect(
      review[ComposerHintCategory.startChallenge]!,
      greaterThan(review[ComposerHintCategory.viewChallenges]!),
    );

    final active = composerHintWeights(
      hasActiveChallenge: true,
      reviewCount: 0,
    );
    expect(
      active[ComposerHintCategory.viewChallenges]!,
      greaterThan(active[ComposerHintCategory.startChallenge]!),
    );
  });

  test('never repeats the previous hint when another option exists', () {
    final selector = ComposerHintSelector(Random(7));
    var previous = ComposerHintCategory.discovery;

    for (var index = 0; index < 50; index++) {
      final next = selector.next(
        options: _options,
        weights: composerHintWeights(hasActiveChallenge: false, reviewCount: 0),
        previous: previous,
      );
      expect(next.category, isNot(previous));
      previous = next.category;
    }
  });

  test('provides localized Chinese command hints', () {
    final zh = TranslationsZh();
    expect(zh.timeline.composerHintWords, contains('单词'));
    expect(zh.timeline.composerHintReview, contains('复习'));
    expect(zh.timeline.composerHintStartChallenge, contains('挑战'));
    expect(zh.timeline.composerHintViewChallenges, contains('挑战'));
  });

  test('honors a dominant state weight', () {
    final selector = ComposerHintSelector(Random(3));
    final next = selector.next(
      options: _options,
      weights: {
        ComposerHintCategory.discovery: 0,
        ComposerHintCategory.review: 100,
        ComposerHintCategory.startChallenge: 0,
        ComposerHintCategory.viewChallenges: 0,
      },
    );

    expect(next.category, ComposerHintCategory.review);
  });
}
