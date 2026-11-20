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
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../domain/challenge.dart';
import '../providers/challenge_providers.dart';

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.challenge;
    final async = ref.watch(challengesProvider);

    return AppScaffold(
      title: t.title,
      centerBody: false,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(challengesProvider),
          ),
        ),
        data: (challenges) {
          final active = challenges.where((c) => c.isActive).toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          final ended = challenges.where((c) => !c.isActive).toList();
          if (challenges.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppEmptyView(title: t.empty),
                  const SizedBox(height: AppSpacing.s20),
                  AppButton(
                    key: const Key('challenges.startEmpty'),
                    label: t.start,
                    onPressed: () => _openCreate(context),
                  ),
                ],
              ),
            );
          }

          final focus = active.isNotEmpty ? active.first : null;
          final others = active.skip(1).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s24),
            children: [
              if (focus != null)
                KeyedSubtree(
                  key: const Key('challenges.focus'),
                  child: _FocusCard(
                    key: Key('challenges.card.${focus.id}'),
                    challenge: focus,
                    onOpen: () => _openDetail(context, focus.id),
                    onPractice: () => _openPractice(context, focus.id),
                  ),
                ),
              if (others.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                _SectionLabel(label: t.otherPlans),
                for (final challenge in others)
                  _CompactRow(
                    key: Key('challenges.card.${challenge.id}'),
                    challenge: challenge,
                    onTap: () => _openDetail(context, challenge.id),
                  ),
              ],
              if (ended.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                _SectionLabel(label: t.ended),
                for (final challenge in ended)
                  _CompactRow(
                    key: Key('challenges.card.${challenge.id}'),
                    challenge: challenge,
                    onTap: () => _openDetail(context, challenge.id),
                  ),
              ],
              const SizedBox(height: AppSpacing.s20),
              AppButton(
                key: const Key('challenges.start'),
                label: t.start,
                onPressed: () => _openCreate(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openCreate(BuildContext context) {
    unawaited(context.pushNamed(AppRouteNames.challengeNew));
  }

  void _openDetail(BuildContext context, String id) {
    unawaited(
      context.pushNamed(
        AppRouteNames.challengeDetail,
        pathParameters: {'challengeId': id},
      ),
    );
  }

  void _openPractice(BuildContext context, String id) {
    unawaited(
      context.pushNamed(
        AppRouteNames.challengePractice,
        pathParameters: {'challengeId': id},
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    super.key,
    required this.challenge,
    required this.onOpen,
    required this.onPractice,
  });

  final Challenge challenge;
  final VoidCallback onOpen;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final focus = challenge.todayFocus;

    return AppCard(
      onTap: onOpen,
      semanticLabel: challenge.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (challenge.theme?.trim().isNotEmpty ?? false)
                ? challenge.theme!.trim().toUpperCase()
                : t.active.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(color: palette.accent),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(challenge.name, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '${t.journey.replaceFirst('{day}', '${challenge.dayIndex}').replaceFirst('{total}', '${challenge.plannedDays}')} · '
            '${t.visitedOf.replaceFirst('{visited}', '${challenge.visitedCount}').replaceFirst('{total}', '${challenge.totalCount}')}',
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 8,
              backgroundColor: palette.surfaceMuted,
              color: palette.primary,
            ),
          ),
          if (challenge.isActive && challenge.isDue) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              t.due,
              style: textTheme.bodySmall?.copyWith(color: palette.accent),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          Text(
            challenge.isComplete
                ? t.allPracticed
                : focus.isEmpty
                ? t.todayDone
                : t.toPractice.replaceFirst('{count}', '${focus.length}'),
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: challenge.isComplete ? palette.accent : palette.ink,
            ),
          ),
          if (challenge.isActive &&
              !challenge.isComplete &&
              focus.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            AppButton(
              key: const Key('challenges.practiceToday'),
              label: t.practiceToday,
              onPressed: onPractice,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({super.key, required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final journey = t.journey
        .replaceFirst('{day}', '${challenge.dayIndex}')
        .replaceFirst('{total}', '${challenge.plannedDays}');
    final visited = t.visitedOf
        .replaceFirst('{visited}', '${challenge.visitedCount}')
        .replaceFirst('{total}', '${challenge.totalCount}');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.s12),
        semanticLabel: challenge.name,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    '$journey · $visited',
                    style: textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
            AppLineIcon(AppLineGlyph.chevronRight, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8, bottom: AppSpacing.s8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.eyebrow.copyWith(color: context.appPalette.muted),
      ),
    );
  }
}
