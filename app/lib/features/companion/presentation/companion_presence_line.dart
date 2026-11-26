import 'package:flutter/widgets.dart';

import '../../../i18n/strings.g.dart';
import '../domain/companion_presence.dart';

String companionPresenceLine(BuildContext context, CompanionPresence presence) {
  final t = context.t.companion.presence;
  final index = _variantIndex(presence.variant);
  final word = presence.word ?? '';

  return switch (presence.key) {
    'morning' => [t.morning0, t.morning1, t.morning2][index],
    'afternoon' => [t.afternoon0, t.afternoon1, t.afternoon2][index],
    'evening' =>
      index == 0
          ? t.evening0(word: word)
          : index == 1
          ? t.evening1
          : t.evening2,
    'night' => [t.night0, t.night1, t.night2][index],
    'word' => t.word(word: word),
    'talk' => t.talk,
    'hobby' => t.hobby,
    'returning' => t.returning,
    _ => t.fallback,
  };
}

int _variantIndex(int variant) {
  if (variant < 0) {
    return 0;
  }
  if (variant > 2) {
    return 2;
  }
  return variant;
}
