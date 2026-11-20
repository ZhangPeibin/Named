import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../progress/providers/progress_providers.dart';
import '../../talk/providers/talk_providers.dart';
import '../../timeline/domain/timeline_item.dart';
import '../../timeline/presentation/widgets/word_details_sheet.dart';
import '../../timeline/providers/timeline_providers.dart';
import '../../words/domain/word_shelf.dart';
import '../../words/presentation/word_lookup_sheet.dart';
import '../../words/providers/words_providers.dart';
import '../domain/challenge.dart';
import '../providers/challenge_providers.dart';

class ChallengeDetailPage extends ConsumerWidget {
  const ChallengeDetailPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.challenge;
    final async = ref.watch(challengeProvider(challengeId));

    return AppScaffold(
      title: t.title,
      centerBody: false,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.detailFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(challengeProvider(challengeId)),
          ),
        ),
        data: (challenge) => _ChallengeDetail(
          challenge: challenge,
          onOpen: (item) => _openItem(context, ref, challenge, item),
          onStartPractice: () => unawaited(
            context.pushNamed(
              AppRouteNames.challengePractice,
              pathParameters: {'challengeId': challenge.id},
            ),
          ),
          onPracticeItem: (item) => unawaited(
            context.pushNamed(
              AppRouteNames.challengePractice,
              pathParameters: {'challengeId': challenge.id},
              queryParameters: {'item': item.id},
            ),
          ),
          onEnd: () => _end(context, ref, challenge),
        ),
      ),
    );
  }

  Future<void> _openItem(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
    ChallengeItem item,
  ) async {
    final timeline = ref.read(timelineControllerProvider).value;
    TimelineItem? source;
    if (timeline != null) {
      for (final candidate in timeline.items) {
        final id = switch (candidate) {
          TimelineWordItem(:final id) => id,
          TimelineSceneItem(:final id) => id,
          _ => null,
        };
        if (id == item.discoveryId) {
          source = candidate;
          break;
        }
      }
    }

    switch (source) {
      case final TimelineWordItem wordItem:
        await showAppBottomSheet<void>(
          context: context,
          builder: (context) => WordDetailsSheet(item: wordItem),
        );
      case final TimelineSceneItem sceneItem:
        await _openSceneConversation(context, ref, sceneItem);
      default:
        await _openItemFallback(context, ref, item);
    }
    ref.invalidate(challengeProvider(challenge.id));
    ref.invalidate(challengesProvider);
  }

  Future<void> _openSceneConversation(
    BuildContext context,
    WidgetRef ref,
    TimelineSceneItem scene,
  ) async {
    try {
      final controller = ref.read(timelineControllerProvider.notifier);
      final conversationId = await controller.ensureSceneConversation(scene);
      if (!context.mounted) {
        return;
      }
      await context.pushNamed(
        AppRouteNames.talk,
        pathParameters: {'conversationId': conversationId},
        queryParameters: {
          if (scene.scene.naturalEnglish.trim().isNotEmpty)
            'title': scene.scene.naturalEnglish,
        },
      );
      if (!context.mounted) {
        return;
      }
      await controller.afterTalk(
        conversationId: conversationId,
        title: scene.scene.naturalEnglish,
      );
      ref.invalidate(progressProvider);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openItemFallback(
    BuildContext context,
    WidgetRef ref,
    ChallengeItem item,
  ) async {
    if (item.focusType == 'word') {
      WordShelfItem? saved;
      try {
        final shelf = await ref.read(wordShelfProvider.future);
        for (final word in shelf.words) {
          if (word.id == item.focusId) {
            saved = word;
            break;
          }
        }
      } catch (_) {
        saved = null;
      }
      if (!context.mounted) {
        return;
      }
      if (saved != null) {
        await showSavedWordSheet(context, saved);
      } else {
        await showWordLookupSheet(context, item.title);
      }
      return;
    }
    try {
      final conversation = await ref
          .read(talkRepositoryProvider)
          .createConversation(focusType: 'scene', focusId: item.focusId);
      if (!context.mounted) {
        return;
      }
      await context.pushNamed(
        AppRouteNames.talk,
        pathParameters: {'conversationId': conversation.id},
        queryParameters: {
          if (item.title.trim().isNotEmpty) 'title': item.title,
        },
      );
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _end(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final t = context.t.challenge;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.end),
        content: Text(t.endConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.complete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(challengeActionsProvider).end(challenge.id);
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(t.finishRound),
          content: Text(
            t.roundRecap
                .replaceFirst('{visited}', '${challenge.visitedCount}')
                .replaceFirst('{total}', '${challenge.totalCount}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.practiceDone),
            ),
          ],
        ),
      );
      if (context.mounted) {
        context.pop();
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _ChallengeDetail extends StatelessWidget {
  const _ChallengeDetail({
    required this.challenge,
    required this.onOpen,
    required this.onStartPractice,
    required this.onPracticeItem,
    required this.onEnd,
  });

  final Challenge challenge;
  final ValueChanged<ChallengeItem> onOpen;
  final VoidCallback onStartPractice;
  final ValueChanged<ChallengeItem> onPracticeItem;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final focus = challenge.todayFocus;
    final active = challenge.isActive;
    final journey = t.journey
        .replaceFirst('{day}', '${challenge.dayIndex}')
        .replaceFirst('{total}', '${challenge.plannedDays}');
    final visited = t.visitedOf
        .replaceFirst('{visited}', '${challenge.visitedCount}')
        .replaceFirst('{total}', '${challenge.totalCount}');

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      children: [
        Text(
          (challenge.theme?.trim().isNotEmpty ?? false)
              ? challenge.theme!.trim().toUpperCase()
              : active
              ? t.active.toUpperCase()
              : t.ended.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(
            color: active ? palette.accent : palette.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(challenge.name, style: textTheme.displayMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '$journey · $visited',
          style: textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
        if (active && challenge.isDue) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            t.due,
            style: textTheme.bodySmall?.copyWith(color: palette.accent),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: challenge.progress,
            minHeight: 8,
            backgroundColor: palette.surfaceMuted,
            color: palette.primary,
          ),
        ),
        if (active) ...[
          const SizedBox(height: AppSpacing.s20),
          _SectionLabel(label: t.today),
          const SizedBox(height: AppSpacing.s8),
          if (challenge.isComplete)
            Text(
              t.allPracticed,
              style: textTheme.bodyLarge?.copyWith(
                color: palette.accent,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (focus.isEmpty)
            Text(
              t.todayDone,
              style: textTheme.bodyLarge?.copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            for (final item in focus)
              _TodayRow(
                key: Key('challenge.today.${item.id}'),
                item: item,
                onTap: () => onPracticeItem(item),
              ),
            const SizedBox(height: AppSpacing.s12),
            AppButton(
              key: const Key('challenge.practiceStart'),
              label: t.practiceToday,
              onPressed: onStartPractice,
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.s24),
        _SectionLabel(label: t.content),
        const SizedBox(height: AppSpacing.s8),
        for (final item in challenge.items)
          KeyedSubtree(
            key: Key('challenge.item.${item.id}'),
            child: _ItemRow(
              key: Key('challenge.practice.${item.id}'),
              item: item,
              onPractice: () => onPracticeItem(item),
              onDetails: () => onOpen(item),
            ),
          ),
        if (active) ...[
          const SizedBox(height: AppSpacing.s16),
          if (challenge.isComplete)
            AppButton(
              key: const Key('challenge.end'),
              label: t.finishRound,
              onPressed: onEnd,
            )
          else
            AppButton(
              key: const Key('challenge.end'),
              label: t.end,
              variant: AppButtonVariant.text,
              onPressed: onEnd,
            ),
        ],
      ],
    );
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

class _TodayRow extends StatelessWidget {
  const _TodayRow({super.key, required this.item, required this.onTap});

  final ChallengeItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.s12),
        semanticLabel: item.title,
        child: Row(
          children: [
            AppLineIcon(
              item.focusType == 'word' ? AppLineGlyph.book : AppLineGlyph.chat,
              color: palette.primary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AppLineIcon(AppLineGlyph.chevronRight, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.onPractice,
    required this.onDetails,
  });

  final ChallengeItem item;
  final VoidCallback onPractice;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: AppCard(
        onTap: onPractice,
        padding: const EdgeInsets.all(AppSpacing.s12),
        semanticLabel: item.title,
        child: Row(
          children: [
            AppLineIcon(
              item.visited
                  ? AppLineGlyph.checkCircle
                  : AppLineGlyph.circleOutline,
              color: item.visited ? palette.accent : palette.muted,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.subtitle != null && item.subtitle!.trim().isNotEmpty)
                    Text(
                      item.subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              key: Key('challenge.details.${item.id}'),
              tooltip: t.details,
              onPressed: onDetails,
              icon: AppLineIcon(
                AppLineGlyph.chevronRight,
                color: palette.muted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
