import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_line_icon.dart';
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
            glyph: AppLineGlyph.book,
            color: ContentAccents.words(context),
          ),
          _divider(palette),
          _ProgressStat(
            value: progress.conversations,
            label: t.progressConversations,
            glyph: AppLineGlyph.chat,
            color: ContentAccents.talks(context),
          ),
          _divider(palette),
          _ProgressStat(
            value: progress.readings,
            label: t.progressReads,
            glyph: AppLineGlyph.headphones,
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
    required this.glyph,
    required this.color,
  });

  final int value;
  final String label;
  final AppLineGlyph glyph;
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
              AppLineIcon(glyph, size: 13, color: color),
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
