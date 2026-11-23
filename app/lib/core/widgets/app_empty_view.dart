import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import 'app_line_icon.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = AppLineGlyph.inbox,
    this.iconColor,
    this.action,
  });

  final String title;
  final String? message;
  final AppLineGlyph icon;
  final Color? iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: palette.line),
          ),
          child: Center(
            child: AppLineIcon(
              icon,
              size: 24,
              color: iconColor ?? palette.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              Text(
                title,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  message!,
                  style: textTheme.bodyLarge?.copyWith(color: palette.muted),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: AppSpacing.s20),
          action!,
        ],
      ],
    );
  }
}
