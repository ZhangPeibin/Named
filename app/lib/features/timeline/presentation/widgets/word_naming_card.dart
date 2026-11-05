import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_tag.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';
import '../../domain/timeline_item.dart';

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

    return AppCard(
      key: Key('timeline.word.${item.id}'),
      borderRadius: AppRadius.r24,
      padding: const EdgeInsets.all(AppSpacing.s20),
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
          Text(word.spelling, style: textTheme.displayMedium),
          if (ipa.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              ipa,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
          if (word.pos.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s6,
              runSpacing: AppSpacing.s6,
              children: [for (final pos in word.pos) AppTag(label: pos)],
            ),
          ],
          if (sense != null && sense.definitionZh.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              sense.definitionZh,
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
          ],
          if (word.chunks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s20),
            Divider(height: 1, color: palette.line),
            const SizedBox(height: AppSpacing.s14),
            Text(
              t.chunks.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final chunk in word.chunks) ...[
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
              if (chunk.exampleEn.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  chunk.exampleEn,
                  style: AppTextStyles.caption.copyWith(color: palette.muted),
                ),
              ],
              const SizedBox(height: AppSpacing.s12),
            ],
          ],
          if (word.grammar.isNotEmpty) ...[
            Divider(height: 1, color: palette.line),
            const SizedBox(height: AppSpacing.s14),
            Text(
              t.grammar.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(word.grammar, style: textTheme.bodySmall),
          ],
          if (word.varietyNotes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s18),
            Divider(height: 1, color: palette.line),
            const SizedBox(height: AppSpacing.s14),
            Text(
              t.usUk.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final note in word.varietyNotes) ...[
              Text(
                note.kind.toUpperCase(),
                style: AppTextStyles.caption.copyWith(color: palette.primary),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(note.descriptionZh, style: textTheme.bodySmall),
              if ((note.us ?? '').isNotEmpty || (note.uk ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  [
                    if ((note.us ?? '').isNotEmpty) 'US: ${note.us}',
                    if ((note.uk ?? '').isNotEmpty) 'UK: ${note.uk}',
                  ].join(' · '),
                  style: AppTextStyles.caption.copyWith(color: palette.muted),
                ),
              ],
              if ((note.exampleEn ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  note.exampleEn!,
                  style: AppTextStyles.caption.copyWith(color: palette.muted),
                ),
              ],
              const SizedBox(height: AppSpacing.s10),
            ],
          ],
          if (sense != null) ...[
            const SizedBox(height: AppSpacing.s20),
            Divider(height: 1, color: palette.line),
            const SizedBox(height: AppSpacing.s14),
            Text(
              t.example.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(sense.exampleEn, style: textTheme.bodyMedium),
            if (sense.exampleZh.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                sense.exampleZh,
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
          ],
          if (word.sceneExtensions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s20),
            Divider(height: 1, color: palette.line),
            _SceneExtensions(extensions: word.sceneExtensions),
          ],
          const SizedBox(height: AppSpacing.s20),
          AppButton(
            key: Key('timeline.talk.${item.id}'),
            label: t.talk,
            icon: const Icon(Icons.chat_bubble_outline),
            variant: AppButtonVariant.secondary,
            isLoading: isStartingTalk,
            onPressed: isStartingTalk ? null : onTalk,
          ),
        ],
      ),
    );
  }
}

class _SceneExtensions extends StatefulWidget {
  const _SceneExtensions({required this.extensions});

  final List<SceneExtension> extensions;

  @override
  State<_SceneExtensions> createState() => _SceneExtensionsState();
}

class _SceneExtensionsState extends State<_SceneExtensions> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t.timeline;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadius.r8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Row(
              children: [
                Expanded(
                  child: Text(t.sceneExtensions, style: textTheme.labelMedium),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: palette.muted,
                    size: AppSize.size18,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final extension in widget.extensions) ...[
                  Text(extension.labelEn, style: textTheme.labelMedium),
                  if (extension.labelZh.isNotEmpty ||
                      extension.relationship.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      [
                        if (extension.labelZh.isNotEmpty) extension.labelZh,
                        if (extension.relationship.isNotEmpty)
                          extension.relationship,
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s8),
                ],
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}
