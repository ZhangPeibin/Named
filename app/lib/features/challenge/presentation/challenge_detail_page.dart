import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
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
import '../../talk/providers/talk_providers.dart';
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
          onPractice: (item) => _practice(context, ref, challenge, item),
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
    } else {
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
    ref.invalidate(challengeProvider(challenge.id));
    ref.invalidate(challengesProvider);
  }

  Future<void> _practice(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
    ChallengeItem item,
  ) async {
    if (item.visited) {
      return;
    }
    try {
      await ref
          .read(challengeActionsProvider)
          .markVisited(challenge.id, item.id);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    if (item.focusType == 'word') {
      try {
        await ref.read(wordsRepositoryProvider).markReviewed(item.focusId);
      } catch (_) {
        // Best-effort: challenge progress already recorded.
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
    required this.onPractice,
    required this.onEnd,
  });

  final Challenge challenge;
  final ValueChanged<ChallengeItem> onOpen;
  final ValueChanged<ChallengeItem> onPractice;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      children: [
        Text(
          challenge.isActive ? t.active.toUpperCase() : t.ended.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(
            color: challenge.isActive ? palette.accent : palette.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(challenge.name, style: textTheme.displayMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '${challenge.plannedDays} ${t.days} · ${t.visitedOf.replaceFirst('{visited}', '${challenge.visitedCount}').replaceFirst('{total}', '${challenge.totalCount}')}',
          style: textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
        if (challenge.isActive && challenge.isDue) ...[
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
            value: challenge.totalCount == 0
                ? 0
                : challenge.visitedCount / challenge.totalCount,
            minHeight: 8,
            backgroundColor: palette.surfaceMuted,
            color: palette.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text(
          t.content.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s8),
        for (final item in challenge.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: AppCard(
              key: Key('challenge.item.${item.id}'),
              onTap: () => onOpen(item),
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                children: [
                  Semantics(
                    button: !item.visited,
                    label: item.visited ? null : t.markPracticed,
                    child: GestureDetector(
                      key: Key('challenge.practice.${item.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: item.visited ? null : () => onPractice(item),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s8),
                        child: AppLineIcon(
                          item.visited
                              ? AppLineGlyph.checkCircle
                              : AppLineGlyph.circleOutline,
                          color: item.visited ? palette.accent : palette.muted,
                          size: 20,
                        ),
                      ),
                    ),
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
                        if (item.subtitle != null &&
                            item.subtitle!.trim().isNotEmpty)
                          Text(
                            item.subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppLineIcon(AppLineGlyph.chevronRight, color: palette.muted),
                ],
              ),
            ),
          ),
        if (challenge.isActive) ...[
          const SizedBox(height: AppSpacing.s16),
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
