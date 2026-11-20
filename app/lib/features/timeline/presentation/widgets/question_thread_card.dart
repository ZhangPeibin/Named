import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../domain/timeline_item.dart';
import 'spot_mark.dart';

class QuestionThreadCard extends StatelessWidget {
  const QuestionThreadCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final TimelineQuestionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      key: Key('timeline.question.${item.id}'),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      child: Row(
        children: [
          const AskMark(),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(color: palette.ink),
                ),
                if (item.lastText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    item.lastText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          AppLineIcon(
            AppLineGlyph.chevronRight,
            color: palette.muted,
            size: 22,
          ),
        ],
      ),
    );
  }
}
