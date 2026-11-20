import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../domain/timeline_item.dart';
import 'spot_mark.dart';

class TalkEventCard extends StatelessWidget {
  const TalkEventCard({super.key, required this.item, required this.onTap});

  final TimelineTalkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(item.createdAt.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return AppCard(
      key: Key('timeline.talkEvent.${item.conversationId}'),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      child: Row(
        children: [
          const MiloMark(),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: textTheme.labelLarge?.copyWith(color: palette.ink),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  item.lastMessageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(color: palette.muted),
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
