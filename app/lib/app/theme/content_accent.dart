import 'package:flutter/material.dart';

/// Content icons follow Material's role system instead of per-feature hues:
/// one secondary accent for content, `onSurfaceVariant` for completed or
/// inactive states, and the palette error colour for errors. Navigation glyphs
/// (chevrons, back, close) stay neutral.
class ContentAccents {
  const ContentAccents._();

  static Color words(BuildContext context) => _accent(context);

  static Color talks(BuildContext context) => _accent(context);

  static Color reads(BuildContext context) => _accent(context);

  static Color challenges(BuildContext context) => _accent(context);

  static Color ask(BuildContext context) => _accent(context);

  static Color history(BuildContext context) => _accent(context);

  static Color soul(BuildContext context) => _accent(context);

  static Color _accent(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }
}
