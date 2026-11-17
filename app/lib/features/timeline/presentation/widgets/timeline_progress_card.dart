import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import '../../../progress/domain/progress.dart';
import 'spot_mark.dart';

class TimelineProgressCard extends StatelessWidget {
  const TimelineProgressCard({super.key, required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.timeline;

    return Container(
      key: const Key('timeline.progress'),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s4,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s14,
        AppSpacing.s12,
        AppSpacing.s14,
        AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          _ProgressStat(
            value: progress.words,
            label: t.progressWords,
            icon: Icons.menu_book_outlined,
            color: ContentAccents.words(context),
          ),
          _divider(palette),
          _ProgressStat(
            value: progress.conversations,
            label: t.progressConversations,
            icon: Icons.chat_bubble_outline,
            color: ContentAccents.talks(context),
          ),
          _divider(palette),
          _ProgressStat(
            value: progress.readings,
            label: t.progressReads,
            icon: Icons.headphones_outlined,
            color: ContentAccents.reads(context),
          ),
        ],
      ),
    );
  }

  Widget _divider(AppPalette palette) {
    return Container(
      width: 1,
      height: AppSpacing.s24,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      color: palette.line,
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: textTheme.titleMedium?.copyWith(color: palette.ink),
          ),
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: palette.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
