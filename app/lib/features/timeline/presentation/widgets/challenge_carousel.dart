import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../i18n/strings.g.dart';
import '../../../challenge/domain/challenge.dart';
import '../../../challenge/providers/challenge_providers.dart';

/// A horizontally swipeable row of the learner's in-progress challenges, shown
/// in the timeline so they can continue a round on entry.
class ChallengeCarousel extends ConsumerStatefulWidget {
  const ChallengeCarousel({super.key});

  @override
  ConsumerState<ChallengeCarousel> createState() => _ChallengeCarouselState();
}

class _ChallengeCarouselState extends ConsumerState<ChallengeCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: Text(
            t.active.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
          ),
        ),
        SizedBox(
          height: 138,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _index = index),
            itemCount: active.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s12),
              child: _ChallengeMiniCard(
                challenge: active[index],
                onTap: () => unawaited(
                  context.pushNamed(
                    AppRouteNames.challengeDetail,
                    pathParameters: {'challengeId': active[index].id},
                  ),
                ),
              ),
            ),
          ),
        ),
        if (active.length > 1) ...[
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < active.length; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.s6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _index ? palette.primary : palette.line,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ChallengeMiniCard extends StatelessWidget {
  const _ChallengeMiniCard({required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      key: Key('timeline.challenge.${challenge.id}'),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            '${challenge.plannedDays} ${t.days} · '
            '${t.visitedOf.replaceFirst('{visited}', '${challenge.visitedCount}').replaceFirst('{total}', '${challenge.totalCount}')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          if (challenge.isDue) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              t.due,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: palette.accent),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Text(
                t.kContinue,
                style: textTheme.labelLarge?.copyWith(color: palette.primary),
              ),
              const SizedBox(width: AppSpacing.s4),
              AppLineIcon(AppLineGlyph.chevronRight, color: palette.primary),
            ],
          ),
        ],
      ),
    );
  }
}
