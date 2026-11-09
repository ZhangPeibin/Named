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
  var _index = 0;
  var _revealed = false;
  var _completed = false;

  void _showMeaning() {
    setState(() => _revealed = true);
  }

  void _next(int total, String? wordId) {
    unawaited(_markReviewed(wordId));
    setState(() {
      if (_index + 1 >= total) {
        _completed = true;
        return;
      }
      _index++;
      _revealed = false;
    });
  }

  Future<void> _markReviewed(String? wordId) async {
    if (wordId == null) {
      return;
    }
    try {
      await ref.read(wordsRepositoryProvider).markReviewed(wordId);
    } catch (_) {}
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
          return _ReviewContent(
            t: t,
            item: item,
            index: _index.clamp(0, items.length - 1),
            total: items.length,
            revealed: _revealed,
            onShowMeaning: _showMeaning,
            onNext: () => _next(items.length, item.wordId),
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
    required this.revealed,
    required this.onShowMeaning,
    required this.onNext,
  });

  final Translations$review$en t;
  final TimelineWordItem item;
  final int index;
  final int total;
  final bool revealed;
  final VoidCallback onShowMeaning;
  final VoidCallback onNext;

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
    final metaParts = <String>[if (ipa.isNotEmpty) ipa, ...word.pos];
    final definition = word.primarySense?.definitionZh;
    final chunk = word.chunks.isEmpty ? null : word.chunks.first;
    final isLast = index + 1 >= total;

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
                Text(t.prompt, style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.s20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(word.spelling, style: textTheme.displayMedium),
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            metaParts.join(' · '),
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.muted,
                            ),
                          ),
                        ],
                        if (item.audio?.hasAudio == true) ...[
                          const SizedBox(height: AppSpacing.s12),
                          WordAudioButton(audio: item.audio, compact: true),
                        ],
                        if (revealed) ...[
                          const SizedBox(height: AppSpacing.s20),
                          Divider(height: 1, color: palette.line),
                          const SizedBox(height: AppSpacing.s16),
                          if (definition != null && definition.isNotEmpty) ...[
                            Text(
                              definition,
                              style: textTheme.bodyLarge?.copyWith(
                                color: palette.muted,
                              ),
                            ),
                            if (chunk != null)
                              const SizedBox(height: AppSpacing.s14),
                          ],
                          if (chunk != null) ...[
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
                      ],
                    ),
                  ),
                ),
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
            child: SizedBox(
              width: double.infinity,
              child: AppButton(
                label: revealed ? (isLast ? t.finish : t.next) : t.showMeaning,
                onPressed: revealed ? onNext : onShowMeaning,
              ),
            ),
          ),
        ),
      ],
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
            Icon(Icons.eco_outlined, size: 44, color: palette.primary),
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
            Icon(Icons.check_circle_outline, size: 44, color: palette.primary),
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
