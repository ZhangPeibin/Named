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
          final active = challenges.where((c) => c.isActive).toList();
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
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s24),
            children: [
              if (active.isNotEmpty) ...[
                _SectionLabel(label: t.active),
                for (final challenge in active)
                  _ChallengeCard(
                    challenge: challenge,
                    onTap: () => _openDetail(context, challenge.id),
                  ),
              ],
              if (ended.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                _SectionLabel(label: t.ended),
                for (final challenge in ended)
                  _ChallengeCard(
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
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      key: Key('challenges.card.${challenge.id}'),
      semanticLabel: challenge.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: challenge.isActive
                      ? palette.warm
                      : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  challenge.isActive ? t.active : t.ended,
                  style: AppTextStyles.caption.copyWith(
                    color: challenge.isActive ? palette.accent : palette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${challenge.plannedDays} ${t.days}',
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(challenge.name, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.s6),
          Text(
            t.visitedOf
                .replaceFirst('{visited}', '${challenge.visitedCount}')
                .replaceFirst('{total}', '${challenge.totalCount}'),
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          if (challenge.isActive && challenge.isDue) ...[
            const SizedBox(height: AppSpacing.s6),
            Text(
              t.due,
              style: textTheme.bodySmall?.copyWith(color: palette.accent),
            ),
          ],
        ],
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
