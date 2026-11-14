import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ComposerHintCategory {
  discovery,
  openWords,
  review,
  startChallenge,
  viewChallenges,
}

class ComposerHintOption {
  const ComposerHintOption({required this.category, required this.text});

  final ComposerHintCategory category;
  final String text;
}

Map<ComposerHintCategory, double> composerHintWeights({
  required bool? hasActiveChallenge,
  required int reviewCount,
}) {
  return {
    ComposerHintCategory.discovery: 3,
    ComposerHintCategory.openWords: 3,
    ComposerHintCategory.review: reviewCount > 0 ? 6 : 1,
    ComposerHintCategory.startChallenge: hasActiveChallenge == null
        ? 3.5
        : hasActiveChallenge
        ? 1
        : 6,
    ComposerHintCategory.viewChallenges: hasActiveChallenge == null
        ? 3.5
        : hasActiveChallenge
        ? 6
        : 1,
  };
}

class ComposerHintSelector {
  const ComposerHintSelector(this._random);

  final Random _random;

  ComposerHintOption next({
    required List<ComposerHintOption> options,
    required Map<ComposerHintCategory, double> weights,
    ComposerHintCategory? previous,
  }) {
    if (options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'must not be empty');
    }

    final withoutPrevious = options
        .where((option) => option.category != previous)
        .toList(growable: false);
    final candidates = withoutPrevious.isEmpty ? options : withoutPrevious;
    final total = candidates.fold<double>(
      0,
      (sum, option) => sum + _weight(weights, option.category),
    );
    if (total <= 0) {
      return candidates[_random.nextInt(candidates.length)];
    }

    var roll = _random.nextDouble() * total;
    for (final option in candidates) {
      roll -= _weight(weights, option.category);
      if (roll <= 0) {
        return option;
      }
    }
    return candidates.last;
  }

  double _weight(
    Map<ComposerHintCategory, double> weights,
    ComposerHintCategory category,
  ) {
    return max(0, weights[category] ?? 1).toDouble();
  }
}

final composerHintSelectorProvider = Provider<ComposerHintSelector>((ref) {
  return ComposerHintSelector(Random());
});
