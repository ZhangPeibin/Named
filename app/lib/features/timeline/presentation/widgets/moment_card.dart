import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/timeline_item.dart';
import 'scene_audio_button.dart';
import 'talk_action.dart';

class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.item,
    required this.onTalk,
    this.isStartingTalk = false,
  });

  final TimelineSceneItem item;
  final VoidCallback onTalk;
  final bool isStartingTalk;

  @override
  Widget build(BuildContext context) {
    final t = context.t.timeline;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final scene = item.scene;
    final chunk = scene.keyChunks.isEmpty ? null : scene.keyChunks.first;
    final source = item.inputText?.trim();
    final showSource =
        source != null &&
        source.isNotEmpty &&
        source != scene.naturalEnglish.trim();

    return AppCard(
      key: Key('timeline.scene.${item.id}'),
      borderRadius: AppRadius.r18,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSource) ...[
            Text(
              source,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s2),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  scene.naturalEnglish,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineMedium,
                ),
              ),
              if (item.audio?.isReady == true) ...[
                const SizedBox(width: AppSpacing.s8),
                SceneAudioButton(
                  key: Key('timeline.scene.listen.${item.id}'),
                  audio: item.audio,
                ),
              ],
            ],
          ),
          if (chunk != null) ...[
            const SizedBox(height: AppSpacing.s10),
            Text(
              chunk.phrase,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelLarge?.copyWith(color: palette.ink),
            ),
            if (chunk.meaningNative.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                chunk.meaningNative,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.s10),
          Row(
            children: [
              const Spacer(),
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
}
