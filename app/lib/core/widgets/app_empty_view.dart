import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'app_line_icon.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = AppLineGlyph.inbox,
  });

  final String title;
  final String? message;
  final AppLineGlyph icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLineIcon(icon, size: 56, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.s16),
        Text(
          title,
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            message!,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
