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
      padding: const EdgeInsets.all(AppSpacing.s14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.warm,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: palette.accent.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.question_answer_rounded,
              color: palette.accent,
              size: 20,
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
                  style: textTheme.labelLarge?.copyWith(color: palette.primary),
                ),
                if (item.lastText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    item.lastText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Icon(Icons.chevron_right, color: palette.muted, size: 18),
        ],
      ),
    );
  }
}
