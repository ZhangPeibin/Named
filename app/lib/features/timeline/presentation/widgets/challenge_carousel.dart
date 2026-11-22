import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/content_accent.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../i18n/strings.g.dart';
import '../../../challenge/domain/challenge.dart';
import '../../../challenge/providers/challenge_providers.dart';

/// A single "today's practice" strip for the learner's current challenge,
/// shown in the timeline. Multiple active challenges stay secondary.
class ChallengeCarousel extends ConsumerWidget {
  const ChallengeCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        (ref.watch(challengesProvider).value ?? const <Challenge>[])
            .where((challenge) => challenge.isActive)
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (active.isEmpty) {
      return const SizedBox.shrink();
    }

    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final focus = active.first;
    final count = focus.todayFocus.length;
    final status = focus.isComplete
        ? t.allPracticed
        : count == 0
        ? t.todayDone
        : t.toPractice.replaceFirst('{count}', '$count');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          key: Key('timeline.challenge.${focus.id}'),
          onTap: () => unawaited(
            focus.isComplete
                ? _openDetail(context, focus.id)
                : _openPractice(context, focus.id),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          semanticLabel: focus.name,
          child: Row(
            children: [
              AppLineIcon(
                AppLineGlyph.flag,
                size: 24,
                color: ContentAccents.challenges(context),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focus.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      status,
                      style: textTheme.bodySmall?.copyWith(
                        color: focus.isComplete
                            ? palette.accent
                            : palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              AppLineIcon(AppLineGlyph.chevronRight, color: palette.muted),
            ],
          ),
        ),
        if (active.length > 1) ...[
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.plansCount.replaceFirst('{count}', '${active.length}'),
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ),
              GestureDetector(
                key: const Key('timeline.challenge.seeAll'),
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    unawaited(context.pushNamed(AppRouteNames.challenges)),
                child: Text(
                  t.seeAll,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openPractice(BuildContext context, String id) {
    return context.pushNamed(
      AppRouteNames.challengePractice,
      pathParameters: {'challengeId': id},
    );
  }

  Future<void> _openDetail(BuildContext context, String id) {
    return context.pushNamed(
      AppRouteNames.challengeDetail,
      pathParameters: {'challengeId': id},
    );
  }
}
