import 'package:flutter/widgets.dart';

import '../../../i18n/strings.g.dart';
import '../../progress/domain/progress.dart';

String companionGreetingLine(
  BuildContext context,
  Progress progress, {
  bool returning = false,
}) {
  final t = context.t.companion.greeting;
  final lead = returning ? t.welcomeBack : t.hi;
  if (progress.words > 0) {
    return '$lead ${t.words(count: progress.words)}';
  }
  if (progress.conversations > 0) {
    return '$lead ${t.talks(count: progress.conversations)}';
  }
  if (progress.practices > 0) {
    return '$lead ${t.practices(count: progress.practices)}';
  }
  if (progress.readings > 0) {
    return '$lead ${t.reads(count: progress.readings)}';
  }
  return '$lead ${t.empty}';
}
