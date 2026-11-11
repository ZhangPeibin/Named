import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_view.dart';
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

class _WordLookupSheet extends ConsumerWidget {
  const _WordLookupSheet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.words;
    final async = ref.watch(wordLookupProvider(text));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s12,
          AppSpacing.s20,
          AppSpacing.s20,
        ),
        child: async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => AppErrorView(
            title: t.loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(wordLookupProvider(text)),
          ),
          data: (item) {
            final word = item.word;
            if (word == null) {
              return AppErrorView(
                title: t.loadFailed,
                message: context.t.common.somethingWentWrong,
                onRetry: () => ref.invalidate(wordLookupProvider(text)),
              );
            }
            return WordDetailsSheet(item: _asTimelineItem(item));
          },
        ),
      ),
    );
  }

  TimelineWordItem _asTimelineItem(WordShelfItem item) {
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
}
