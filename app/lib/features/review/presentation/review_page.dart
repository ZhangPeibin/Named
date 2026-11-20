import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../timeline/domain/timeline_item.dart';
import '../../timeline/presentation/widgets/word_audio_button.dart';
import '../../words/providers/words_providers.dart';
import '../providers/review_providers.dart';

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  final _attemptController = TextEditingController();

  var _index = 0;
  var _completed = false;
  var _attempted = false;
  var _hintLevel = 0;
  var _revealed = false;
  var _saving = false;
  var _attemptSaveFailed = false;

  @override
  void dispose() {
    _attemptController.dispose();
    super.dispose();
  }

  Future<void> _submitAttempt(String? wordId) async {
    final text = _attemptController.text.trim();
    if (text.isEmpty || wordId == null) {
      return;
    }
    setState(() {
      _saving = true;
      _attemptSaveFailed = false;
    });
    try {
      await ref
          .read(wordsRepositoryProvider)
          .markAttempt(wordId: wordId, text: text);
    } catch (_) {
      _attemptSaveFailed = true;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _attempted = true;
    });
  }

  void _showHint() {
    setState(() => _hintLevel = (_hintLevel + 1).clamp(0, 2));
  }

  void _showAnswer() {
    setState(() => _revealed = true);
  }

  Future<void> _next(int total, String? wordId, {required bool saidIt}) async {
    if (saidIt && wordId != null) {
      try {
        await ref.read(wordsRepositoryProvider).markReviewed(wordId);
      } catch (_) {}
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (_index + 1 >= total) {
        _completed = true;
        return;
      }
      _index++;
      _attempted = false;
      _hintLevel = 0;
      _revealed = false;
      _attemptSaveFailed = false;
      _attemptController.clear();
    });
  }

  void _back() {
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.review;
    final async = ref.watch(reviewWordsProvider);

    return AppScaffold(
      title: t.title,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(reviewWordsProvider),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyReview(t: t, onBack: _back);
          }
          if (_completed) {
            return _CompleteReview(t: t, onBack: _back);
          }

          final item = items[_index.clamp(0, items.length - 1)];
          final index = _index.clamp(0, items.length - 1);
          return _ReviewContent(
            t: t,
            item: item,
            index: index,
            total: items.length,
            attemptController: _attemptController,
            attempted: _attempted,
            hintLevel: _hintLevel,
            revealed: _revealed,
            saving: _saving,
            attemptSaveFailed: _attemptSaveFailed,
            onSubmit: () => _submitAttempt(item.wordId),
            onShowHint: _showHint,
            onShowAnswer: _showAnswer,
            onSaidIt: () => _next(items.length, item.wordId, saidIt: true),
            onNotYet: () => _next(items.length, item.wordId, saidIt: false),
          );
        },
      ),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.t,
    required this.item,
    required this.index,
    required this.total,
    required this.attemptController,
    required this.attempted,
    required this.hintLevel,
    required this.revealed,
    required this.saving,
    required this.attemptSaveFailed,
    required this.onSubmit,
    required this.onShowHint,
    required this.onShowAnswer,
    required this.onSaidIt,
    required this.onNotYet,
  });

  final Translations$review$en t;
  final TimelineWordItem item;
  final int index;
  final int total;
  final TextEditingController attemptController;
  final bool attempted;
  final int hintLevel;
  final bool revealed;
  final bool saving;
  final bool attemptSaveFailed;
  final VoidCallback onSubmit;
  final VoidCallback onShowHint;
  final VoidCallback onShowAnswer;
  final VoidCallback onSaidIt;
  final VoidCallback onNotYet;

  @override
  Widget build(BuildContext context) {
    final word = item.word;
    if (word == null) {
      return const SizedBox.shrink();
    }

    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final ipa = word.ipa.values
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(' · ');
    final definition = word.primarySense?.definitionZh;
    final chunk = word.chunks.isEmpty ? null : word.chunks.first;
    final cue = (definition != null && definition.isNotEmpty)
        ? definition
        : (chunk != null && chunk.meaningZh.isNotEmpty)
        ? chunk.meaningZh
        : t.cueMissing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontalPadding,
              AppSpacing.s16,
              AppSpacing.pageHorizontalPadding,
              AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1} / $total',
                  style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(t.attemptPrompt, style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  cue,
                  style: textTheme.bodyLarge?.copyWith(color: palette.muted),
                ),
                if (!attempted) ...[
                  const SizedBox(height: AppSpacing.s20),
                  TextField(
                    controller: attemptController,
                    autofocus: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                    decoration: InputDecoration(
                      hintText: t.attemptPlaceholder,
                      helperText: t.attemptHint,
                    ),
                  ),
                ],
                if (attempted) ...[
                  const SizedBox(height: AppSpacing.s20),
                  _AttemptSummary(
                    label: t.yourAttempt,
                    text: attemptController.text.trim(),
                  ),
                  if (attemptSaveFailed) ...[
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      t.attemptFailed,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),
                  if (!revealed) ...[
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        if (hintLevel < 2)
                          AppButton(
                            label: t.showHint,
                            variant: AppButtonVariant.secondary,
                            onPressed: onShowHint,
                          ),
                        if (hintLevel > 0)
                          _WordHint(
                            label: t.hintFirst,
                            value: _firstLetter(word.spelling),
                          ),
                        if (hintLevel > 1 && ipa.isNotEmpty)
                          _WordHint(label: t.hintIpa, value: ipa),
                        if (item.audio?.hasAudio == true && hintLevel > 1)
                          WordAudioButton(audio: item.audio),
                        AppButton(
                          label: t.showAnswer,
                          variant: AppButtonVariant.secondary,
                          onPressed: onShowAnswer,
                        ),
                      ],
                    ),
                  ],
                  if (revealed) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.answerLabel,
                            style: AppTextStyles.eyebrow.copyWith(
                              color: palette.muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(word.spelling, style: textTheme.displayMedium),
                          if (ipa.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              ipa,
                              style: textTheme.bodySmall?.copyWith(
                                color: palette.muted,
                              ),
                            ),
                          ],
                          if (item.audio?.hasAudio == true) ...[
                            const SizedBox(height: AppSpacing.s12),
                            WordAudioButton(audio: item.audio),
                          ],
                          if (definition != null && definition.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s16),
                            Divider(height: 1, color: palette.line),
                            const SizedBox(height: AppSpacing.s16),
                            Text(
                              definition,
                              style: textTheme.bodyLarge?.copyWith(
                                color: palette.muted,
                              ),
                            ),
                          ],
                          if (chunk != null) ...[
                            const SizedBox(height: AppSpacing.s14),
                            Text(
                              chunk.phrase,
                              style: textTheme.labelLarge?.copyWith(
                                color: palette.ink,
                              ),
                            ),
                            if (chunk.meaningZh.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                chunk.meaningZh,
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontalPadding,
              AppSpacing.s8,
              AppSpacing.pageHorizontalPadding,
              AppSpacing.s16,
            ),
            child: _BottomActions(
              attempted: attempted,
              saving: saving,
              revealed: revealed,
              t: t,
              onSubmit: onSubmit,
              onSaidIt: onSaidIt,
              onNotYet: onNotYet,
            ),
          ),
        ),
      ],
    );
  }

  String _firstLetter(String spelling) {
    if (spelling.isEmpty) {
      return spelling;
    }
    return '${spelling[0]}${'·' * (spelling.length - 1)}';
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.attempted,
    required this.saving,
    required this.revealed,
    required this.t,
    required this.onSubmit,
    required this.onSaidIt,
    required this.onNotYet,
  });

  final bool attempted;
  final bool saving;
  final bool revealed;
  final Translations$review$en t;
  final VoidCallback onSubmit;
  final VoidCallback onSaidIt;
  final VoidCallback onNotYet;

  @override
  Widget build(BuildContext context) {
    if (!attempted) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          label: t.checkAttempt,
          isLoading: saving,
          onPressed: onSubmit,
        ),
      );
    }
    if (!revealed) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: t.notYet,
            variant: AppButtonVariant.secondary,
            onPressed: onNotYet,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: AppButton(label: t.saidIt, onPressed: onSaidIt),
        ),
      ],
    );
  }
}

class _AttemptSummary extends StatelessWidget {
  const _AttemptSummary({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(text, style: textTheme.bodyLarge),
      ],
    );
  }
}

class _WordHint extends StatelessWidget {
  const _WordHint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.t, required this.onBack});

  final Translations$review$en t;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLineIcon(AppLineGlyph.leaf, size: 44, color: palette.primary),
            const SizedBox(height: AppSpacing.s16),
            Text(t.emptyTitle, style: textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.s8),
            Text(
              t.emptyCopy,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s24),
            SizedBox(
              width: double.infinity,
              child: AppButton(label: t.backToTimeline, onPressed: onBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteReview extends StatelessWidget {
  const _CompleteReview({required this.t, required this.onBack});

  final Translations$review$en t;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLineIcon(
              AppLineGlyph.checkCircle,
              size: 44,
              color: palette.primary,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(t.completeTitle, style: textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.s8),
            Text(
              t.completeCopy,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s24),
            SizedBox(
              width: double.infinity,
              child: AppButton(label: t.backToTimeline, onPressed: onBack),
            ),
          ],
        ),
      ),
    );
  }
}
