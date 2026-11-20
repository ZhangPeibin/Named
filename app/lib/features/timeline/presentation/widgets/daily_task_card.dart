import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/timeline_item.dart';
import 'spot_mark.dart';

class DailyTaskCard extends StatelessWidget {
  const DailyTaskCard({super.key, required this.item, required this.onTap});

  final TimelineDailyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.daily;
    final isToday = DateUtils.isSameDay(
      item.readingDate.toLocal(),
      DateTime.now(),
    );
    final title = item.title?.trim();
    final displayTitle = title != null && title.isNotEmpty
        ? title
        : isToday
        ? t.taskToday
        : t.taskPast;
    final subtitle = item.completed
        ? t.taskDone.replaceFirst('{streak}', '${item.streak}')
        : t.taskUnread;

    return AppCard(
      key: Key('timeline.daily.${item.id}'),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      child: Row(
        children: [
          DailyMark(completed: item.completed),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(color: palette.ink),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Text(
            item.completed ? t.readAgain : t.read,
            style: AppTextStyles.caption.copyWith(color: palette.ink),
          ),
          const SizedBox(width: AppSpacing.s4),
          AppLineIcon(
            AppLineGlyph.chevronRight,
            color: palette.muted,
            size: AppSize.size22,
          ),
        ],
      ),
    );
  }
}
