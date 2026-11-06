import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_tag.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/timeline_item.dart';
import 'word_audio_button.dart';
import 'word_details_sheet.dart';

class WordNamingCard extends StatelessWidget {
  const WordNamingCard({
    super.key,
    required this.item,
    required this.onTalk,
    this.isStartingTalk = false,
  });

  final TimelineWordItem item;
  final VoidCallback onTalk;
  final bool isStartingTalk;

  @override
  Widget build(BuildContext context) {
    final word = item.word;
    if (word == null) {
      return const SizedBox.shrink();
    }

    final t = context.t.timeline;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final ipa = word.ipa.values
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(' · ');
    final sense = word.primarySense;
    final chunks = word.chunks.take(2).toList();

    return AppCard(
      key: Key('timeline.word.${item.id}'),
      borderRadius: AppRadius.r24,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.inputText != null && item.inputText!.trim().isNotEmpty)
            Row(
              children: [
                Text(
                  item.inputText!,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  '→',
                  style: textTheme.bodySmall?.copyWith(color: palette.accent),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(word.spelling, style: textTheme.displayMedium),
              ),
              if (item.audio?.hasAudio == true)
                WordAudioButton(audio: item.audio),
            ],
          ),
          if (ipa.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              ipa,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
          if (word.pos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s6,
              runSpacing: AppSpacing.s6,
              children: [for (final pos in word.pos) AppTag(label: pos)],
            ),
          ],
          if (sense != null && sense.definitionZh.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              sense.definitionZh,
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
          ],
          if (chunks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s14),
            Divider(height: 1, color: palette.line),
            const SizedBox(height: AppSpacing.s10),
            Text(
              t.chunks.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final chunk in chunks) ...[
              Text(
                chunk.phrase,
                style: textTheme.labelLarge?.copyWith(color: palette.ink),
              ),
              if (chunk.meaningZh.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  chunk.meaningZh,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
              const SizedBox(height: AppSpacing.s8),
            ],
          ],
          const SizedBox(height: AppSpacing.s8),
          _CardActions(
            itemId: item.id,
            detailsLabel: t.moreDetails,
            talkLabel: t.talk,
            isStartingTalk: isStartingTalk,
            onDetails: () => _openDetails(context),
            onTalk: onTalk,
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(BuildContext context) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) => WordDetailsSheet(item: item),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.itemId,
    required this.detailsLabel,
    required this.talkLabel,
    required this.isStartingTalk,
    required this.onDetails,
    required this.onTalk,
  });

  final String itemId;
  final String detailsLabel;
  final String talkLabel;
  final bool isStartingTalk;
  final VoidCallback onDetails;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Material(
              color: palette.surfaceMuted,
              child: InkWell(
                key: Key('timeline.moreDetails.$itemId'),
                onTap: onDetails,
                child: Center(
                  child: Text(
                    detailsLabel,
                    style: AppTextStyles.label.copyWith(color: palette.primary),
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 20, color: palette.line),
          Expanded(
            flex: 6,
            child: Material(
              color: palette.primary,
              child: InkWell(
                key: Key('timeline.talk.$itemId'),
                onTap: isStartingTalk ? null : onTalk,
                child: Center(
                  child: isStartingTalk
                      ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                              color: palette.onPrimary,
                            ),
                            const SizedBox(width: AppSpacing.s6),
                            Text(
                              talkLabel,
                              style: AppTextStyles.label.copyWith(
                                color: palette.onPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s6),
                            Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: palette.onPrimary,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
