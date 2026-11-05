import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../timeline/domain/timeline_item.dart';
import '../../timeline/providers/timeline_providers.dart';

class WordsPage extends ConsumerWidget {
  const WordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.words;
    final timeline = ref.watch(timelineControllerProvider);

    return AppScaffold(
      title: t.title,
      centerBody: false,
      body: timeline.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.title,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(timelineControllerProvider),
          ),
        ),
        data: (state) {
          final words = state.items.whereType<TimelineWordItem>().toList();
          if (words.isEmpty) {
            return Center(child: AppEmptyView(title: t.empty));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(top: AppSpacing.s16),
            itemCount: words.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, index) {
              final item = words[index];
              return _WordRow(
                item: item,
                onTap: () => _openTalk(context, ref, item),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openTalk(
    BuildContext context,
    WidgetRef ref,
    TimelineWordItem item,
  ) async {
    final controller = ref.read(timelineControllerProvider.notifier);
    try {
      final conversationId = await controller.ensureConversation(item);
      if (!context.mounted) {
        return;
      }
      await context.pushNamed(
        AppRouteNames.talk,
        pathParameters: {'conversationId': conversationId},
      );
      if (!context.mounted) {
        return;
      }
      await controller.afterTalk(
        conversationId: conversationId,
        title: item.word?.spelling ?? item.inputText ?? 'Talk',
      );
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.item, required this.onTap});

  final TimelineWordItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final word = item.word;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word?.spelling ?? item.inputText ?? '',
                  style: textTheme.headlineMedium,
                ),
                if (word?.primarySense?.definitionZh.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    word!.primarySense!.definitionZh,
                    style: textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.muted),
        ],
      ),
    );
  }
}
