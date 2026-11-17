import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/timeline_item.dart';

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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.line),
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              color: palette.primary,
              size: 18,
            ),
          ),
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
          Icon(Icons.chevron_right, color: palette.muted, size: 16),
        ],
      ),
    );
  }
}
