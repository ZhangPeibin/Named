import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/audio_control.dart';
import '../../../i18n/strings.g.dart';
import '../../question/presentation/ask_launcher.dart';
import '../../talk/providers/talk_providers.dart';
import '../domain/sentence_detail.dart';
import '../providers/sentence_providers.dart';

Future<void> showSentenceDetailSheet(BuildContext context, String text) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appPalette.canvas,
    builder: (context) => UncontrolledProviderScope(
      container: container,
      child: SentenceDetailSheet(text: text),
    ),
  );
}

class SentenceDetailSheet extends ConsumerWidget {
  const SentenceDetailSheet({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.talk;
    final async = ref.watch(sentenceDetailProvider(text));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s16,
            AppSpacing.s20,
            AppSpacing.s20,
          ),
          child: async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.s20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => AppErrorView(
              title: t.sentenceLoadFailed,
              message: error is ApiException
                  ? error.message
                  : context.t.common.somethingWentWrong,
              onRetry: () => ref.invalidate(sentenceDetailProvider(text)),
            ),
            data: (detail) => _SentenceDetailView(detail: detail),
          ),
        ),
      ),
    );
  }
}

class _SentenceDetailView extends StatelessWidget {
  const _SentenceDetailView({required this.detail});

  final SentenceDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.t.talk;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.sentenceDetails, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s16),
        Text(
          detail.original,
          style: textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(detail.naturalEnglish, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s8),
        _SentenceAudioButton(text: detail.naturalEnglish),
        const SizedBox(height: AppSpacing.s20),
        _SectionLabel(label: t.explanation),
        const SizedBox(height: AppSpacing.s6),
        Text(detail.explanationNative, style: textTheme.bodyMedium),
        if (detail.grammarNotes.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionLabel(label: t.grammarNotes),
          const SizedBox(height: AppSpacing.s6),
          Text(detail.grammarNotes, style: textTheme.bodySmall),
        ],
        if (detail.chunks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionLabel(label: t.chunks),
          const SizedBox(height: AppSpacing.s8),
          for (final chunk in detail.chunks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: _ChunkRow(chunk: chunk),
            ),
        ],
        if (detail.keyWords.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionLabel(label: t.keyWords),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s6,
            children: [
              for (final word in detail.keyWords)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${word.word}  ${word.meaningNative}',
                    style: AppTextStyles.caption.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        TextButton.icon(
          key: const Key('sentence.ask'),
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            unawaited(
              openAsk(
                navigator.context,
                type: 'sentence',
                quote: detail.original,
                suggestedQuestion: 'Explain this sentence simply.',
              ),
            );
          },
          icon: const AppLineIcon(AppLineGlyph.chat, size: 18),
          label: Text(context.t.ask.title),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton(
          key: const Key('sentence.copyEnglish'),
          label: t.copyEnglish,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: detail.naturalEnglish));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t.copied)));
            }
          },
        ),
      ],
    );
  }
}

class _ChunkRow extends StatelessWidget {
  const _ChunkRow({required this.chunk});

  final SentenceChunk chunk;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            chunk.phrase,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            chunk.meaningNative,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ),
      ],
    );
  }
}

final _sentenceAudioUrlCache = <String, String>{};

class _SentenceAudioButton extends ConsumerWidget {
  const _SentenceAudioButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.talk;
    return AudioControl(
      sourceId: 'sentence.$text',
      resolveUrl: () => _resolveUrl(ref),
      playTooltip: t.playReply,
      pauseTooltip: t.pauseReply,
      speedTooltip: t.speed,
      errorText: t.audioUnavailable,
      playKey: const Key('sentence.audio'),
      speedKey: const Key('sentence.audio.speed'),
    );
  }

  Future<String?> _resolveUrl(WidgetRef ref) async {
    final cached = _sentenceAudioUrlCache[text];
    if (cached != null) {
      return cached;
    }
    final audio = await ref.read(talkRepositoryProvider).synthesizeSpeech(text);
    if (!audio.isReady || audio.url == null) {
      return null;
    }
    _sentenceAudioUrlCache[text] = audio.url!;
    return audio.url;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.eyebrow.copyWith(color: context.appPalette.muted),
    );
  }
}
