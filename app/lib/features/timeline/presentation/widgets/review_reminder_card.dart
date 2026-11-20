import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../i18n/strings.g.dart';

/// The single entry point for today's words. It replaces the scattered review
/// nudges in the composer, the daily card and the progress trail.
class ReviewReminderCard extends StatelessWidget {
  const ReviewReminderCard({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.timeline;

    return AppCard(
      key: const Key('timeline.reviewReminder'),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          AppLineIcon(AppLineGlyph.book, size: 22, color: palette.primary),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.reviewReminderTitle,
                  style: textTheme.labelLarge?.copyWith(color: palette.ink),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  t.reviewReminderCount.replaceFirst('{count}', '$count'),
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          Text(
            t.reviewReminderAction,
            style: AppTextStyles.eyebrow.copyWith(color: palette.primary),
          ),
        ],
      ),
    );
  }
}
