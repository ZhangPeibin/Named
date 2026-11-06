import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_tag.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';
import '../../domain/timeline_item.dart';
import 'word_audio_button.dart';

class WordDetailsSheet extends StatefulWidget {
  const WordDetailsSheet({super.key, required this.item});

  final TimelineWordItem item;

  @override
  State<WordDetailsSheet> createState() => _WordDetailsSheetState();
}

class _WordDetailsSheetState extends State<WordDetailsSheet> {
  var _accent = WordAudioAccent.us;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.wordDetails, style: textTheme.headlineMedium),
                ),
                IconButton(
                  key: const Key('wordDetails.close'),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
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
            Text(word.spelling, style: textTheme.displayMedium),
            if (ipa.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                ipa,
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
            if (item.audio?.hasAudio == true) ...[
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  _AccentToggle(
                    accent: _accent,
                    onChanged: (accent) => setState(() => _accent = accent),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  WordAudioButton(audio: item.audio, accent: _accent),
                ],
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
              _SectionDivider(color: palette.line),
              _SectionLabel(label: t.chunks, color: palette.muted),
              const SizedBox(height: AppSpacing.s8),
              for (final chunk in word.chunks)
                _ChunkDetail(chunk: chunk, palette: palette),
            ],
            if (word.grammar.isNotEmpty) ...[
              _SectionDivider(color: palette.line),
              _SectionLabel(label: t.grammar, color: palette.muted),
              const SizedBox(height: AppSpacing.s6),
              Text(word.grammar, style: textTheme.bodySmall),
            ],
            if (word.varietyNotes.isNotEmpty) ...[
              _SectionDivider(color: palette.line),
              _SectionLabel(label: t.usUk, color: palette.muted),
              const SizedBox(height: AppSpacing.s8),
              for (final note in word.varietyNotes)
                _VarietyNoteDetail(note: note, palette: palette),
            ],
            if (sense != null) ...[
              _SectionDivider(color: palette.line),
              _SectionLabel(label: t.example, color: palette.muted),
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
              _SectionDivider(color: palette.line),
              _SectionLabel(label: t.sceneExtensions, color: palette.muted),
              const SizedBox(height: AppSpacing.s8),
              for (final extension in word.sceneExtensions)
                _SceneExtensionDetail(extension: extension, palette: palette),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccentToggle extends StatelessWidget {
  const _AccentToggle({required this.accent, required this.onChanged});

  final WordAudioAccent accent;
  final ValueChanged<WordAudioAccent> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(AppSpacing.s2),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AccentOption(
            key: const Key('wordDetails.accent.us'),
            label: 'US',
            selected: accent == WordAudioAccent.us,
            onTap: () => onChanged(WordAudioAccent.us),
          ),
          _AccentOption(
            key: const Key('wordDetails.accent.uk'),
            label: 'UK',
            selected: accent == WordAudioAccent.uk,
            onTap: () => onChanged(WordAudioAccent.uk),
          ),
        ],
      ),
    );
  }
}

class _AccentOption extends StatelessWidget {
  const _AccentOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: selected ? palette.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          width: 34,
          height: 30,
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? palette.onPrimary : palette.primary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s20),
      child: Divider(height: 1, color: color),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s14),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.eyebrow.copyWith(color: color),
      ),
    );
  }
}

class _ChunkDetail extends StatelessWidget {
  const _ChunkDetail({required this.chunk, required this.palette});

  final WordChunk chunk;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chunk.phrase, style: textTheme.labelLarge),
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
        ],
      ),
    );
  }
}

class _VarietyNoteDetail extends StatelessWidget {
  const _VarietyNoteDetail({required this.note, required this.palette});

  final VarietyNote note;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }
}

class _SceneExtensionDetail extends StatelessWidget {
  const _SceneExtensionDetail({required this.extension, required this.palette});

  final SceneExtension extension;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(extension.labelEn, style: textTheme.labelMedium),
          if (extension.labelZh.isNotEmpty ||
              extension.relationship.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              [
                if (extension.labelZh.isNotEmpty) extension.labelZh,
                if (extension.relationship.isNotEmpty) extension.relationship,
              ].join(' · '),
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
        ],
      ),
    );
  }
}
