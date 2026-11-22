import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/content_accent.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../i18n/strings.g.dart';
import '../../../progress/domain/progress.dart';

class TimelineProgressCard extends StatelessWidget {
  const TimelineProgressCard({
    super.key,
    required this.progress,
    this.onWordsTap,
  });

  final Progress progress;
  final VoidCallback? onWordsTap;

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
            statKey: const Key('timeline.progress.words'),
            value: progress.words,
            label: t.progressWords,
            glyph: AppLineGlyph.book,
            color: ContentAccents.words(context),
            onTap: onWordsTap,
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
    this.statKey,
    this.onTap,
  });

  final int value;
  final String label;
  final AppLineGlyph glyph;
  final Color color;
  final Key? statKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: textTheme.titleMedium?.copyWith(color: palette.ink),
        ),
        Row(
          children: [
            AppLineIcon(glyph, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: palette.muted),
            ),
          ],
        ),
      ],
    );

    if (onTap == null) {
      return Expanded(child: content);
    }
    return Expanded(
      child: InkWell(
        key: statKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: content,
      ),
    );
  }
}
