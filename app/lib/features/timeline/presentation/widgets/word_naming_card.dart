import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/timeline_item.dart';
import 'talk_action.dart';
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
    final chunk = word.chunks.isEmpty ? null : word.chunks.first;
    final metaParts = <String>[if (ipa.isNotEmpty) ipa, ...word.pos];

    return AppCard(
      key: Key('timeline.word.${item.id}'),
      borderRadius: AppRadius.r18,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s14,
      ),
      onTap: () => _openDetails(context),
      semanticLabel: t.moreDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    item.inputText != null && item.inputText!.trim().isNotEmpty
                    ? Text(
                        item.inputText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.muted,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Icon(Icons.chevron_right, size: 18, color: palette.muted),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  word.spelling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.displayMedium,
                ),
              ),
              if (item.audio?.hasAudio == true) ...[
                const SizedBox(width: AppSpacing.s8),
                WordAudioButton(audio: item.audio, compact: true),
              ],
            ],
          ),
          if (metaParts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              metaParts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
          if (sense != null && sense.definitionZh.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s6),
            Text(
              sense.definitionZh,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.s10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: chunk == null
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chunk.phrase,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: palette.ink,
                            ),
                          ),
                          if (chunk.meaningZh.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s2),
                            Text(
                              chunk.meaningZh,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(width: AppSpacing.s12),
              TalkAction(
                itemId: item.id,
                label: t.talkAboutIt,
                isStartingTalk: isStartingTalk,
                onTap: onTalk,
              ),
            ],
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
