import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../i18n/strings.g.dart';
import '../../timeline/domain/timeline_item.dart';
import '../../timeline/presentation/widgets/word_details_sheet.dart';
import '../domain/word_shelf.dart';
import '../providers/words_providers.dart';

Future<void> showWordLookupSheet(BuildContext context, String text) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appPalette.canvas,
    builder: (context) => UncontrolledProviderScope(
      container: container,
      child: _WordLookupSheet(text: text),
    ),
  );
}

class _WordLookupSheet extends ConsumerStatefulWidget {
  const _WordLookupSheet({required this.text});

  final String text;

  @override
  ConsumerState<_WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends ConsumerState<_WordLookupSheet> {
  Future<void> _addToWords(WordShelfItem item) async {
    await ref.read(wordsRepositoryProvider).addToShelf(item.id);
    if (!mounted) {
      return;
    }
    ref.invalidate(wordShelfProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.words;
    final async = ref.watch(wordLookupProvider(widget.text));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s12,
          AppSpacing.s20,
          AppSpacing.s20,
        ),
        child: async.when(
          loading: () => _WordLookupLoading(word: widget.text),
          error: (error, stack) => AppErrorView(
            title: t.loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(wordLookupProvider(widget.text)),
          ),
          data: (item) {
            final word = item.word;
            if (word == null) {
              return AppErrorView(
                title: t.loadFailed,
                message: context.t.common.somethingWentWrong,
                onRetry: () => ref.invalidate(wordLookupProvider(widget.text)),
              );
            }
            return WordDetailsSheet(
              item: wordShelfToTimelineItem(item),
              saved: item.saved,
              onAddToWords: () => _addToWords(item),
            );
          },
        ),
      ),
    );
  }
}

class _WordLookupLoading extends StatelessWidget {
  const _WordLookupLoading({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return KeyedSubtree(
      key: const Key('wordLookup.loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t.timeline.wordDetails,
                  style: textTheme.headlineMedium,
                ),
              ),
              IconButton(
                key: const Key('wordLookup.loading.close'),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const AppLineIcon(AppLineGlyph.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            word,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.displaySmall?.copyWith(color: palette.ink),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            context.t.words.lookingUp,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: palette.primary,
              backgroundColor: palette.line,
            ),
          ),
        ],
      ),
    );
  }
}

TimelineWordItem wordShelfToTimelineItem(WordShelfItem item) {
  return TimelineWordItem(
    id: item.id,
    createdAt: DateTime.now(),
    inputText: null,
    wordId: item.id,
    word: item.word,
    audio: item.audio,
    conversationId: null,
  );
}

/// Opens the saved word details for an already-loaded [WordShelfItem].
Future<void> showSavedWordSheet(BuildContext context, WordShelfItem item) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (context) => WordDetailsSheet(item: wordShelfToTimelineItem(item)),
  );
}
