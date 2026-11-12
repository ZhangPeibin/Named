import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../i18n/strings.g.dart';
import '../../../challenge/domain/challenge.dart';
import '../../../challenge/providers/challenge_providers.dart';
import '../../../words/domain/word_shelf.dart';
import '../../../words/providers/words_providers.dart';

Future<void> showQuickDeck(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showAppBottomSheet<void>(
    context: context,
    builder: (context) => UncontrolledProviderScope(
      container: container,
      child: const _QuickDeck(),
    ),
  );
}

class _QuickDeck extends ConsumerWidget {
  const _QuickDeck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.timeline;
    final challenges = ref.watch(challengesProvider);
    final shelf = ref.watch(wordShelfProvider);
    Challenge? active;
    for (final challenge in challenges.value ?? const <Challenge>[]) {
      if (challenge.status == ChallengeStatus.active) {
        active = challenge;
        break;
      }
    }
    final reviewCount =
        shelf.value?.words
            .where((word) => word.status == WordShelfStatus.needsReview)
            .length ??
        0;
    final wordCount = shelf.value?.stats.total ?? 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 560),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.quickDeckEyebrow.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(
                color: context.appPalette.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - AppSpacing.s12) / 2;
                return Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s12,
                  children: [
                    SizedBox(
                      width: width,
                      child: _QuickCard(
                        key: const Key('quickDeck.challenge'),
                        icon: Icons.flag_outlined,
                        label: t.quickChallenge,
                        value: active?.name ?? t.quickChallengeStart,
                        detail: t.quickOpen,
                        color: context.appPalette.warm,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (active != null) {
                            unawaited(
                              context.pushNamed(
                                AppRouteNames.challengeDetail,
                                pathParameters: {'challengeId': active.id},
                              ),
                            );
                          } else {
                            unawaited(
                              context.pushNamed(AppRouteNames.challengeNew),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _QuickCard(
                        key: const Key('quickDeck.review'),
                        icon: Icons.refresh,
                        label: t.quickReview,
                        value: reviewCount > 0
                            ? t.quickReviewDue.replaceFirst(
                                '{count}',
                                '$reviewCount',
                              )
                            : t.quickReviewHint,
                        detail: t.quickOpen,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(context.pushNamed(AppRouteNames.review));
                        },
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _QuickCard(
                        key: const Key('quickDeck.words'),
                        icon: Icons.menu_book_outlined,
                        label: t.quickWords,
                        value: wordCount > 0
                            ? t.quickWordsCount.replaceFirst(
                                '{count}',
                                '$wordCount',
                              )
                            : t.quickWordsHint,
                        detail: t.quickOpen,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(context.pushNamed(AppRouteNames.words));
                        },
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _QuickCard(
                        key: const Key('quickDeck.history'),
                        icon: Icons.auto_stories_outlined,
                        label: t.quickHistory,
                        value: t.quickHistoryHint,
                        detail: t.quickOpen,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(context.pushNamed(AppRouteNames.history));
                        },
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _QuickCard(
                        key: const Key('quickDeck.me'),
                        icon: Icons.person_outline,
                        label: t.quickMe,
                        value: t.quickMeHint,
                        detail: t.quickOpen,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(context.pushNamed(AppRouteNames.me));
                        },
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _QuickCard(
                        key: const Key('quickDeck.settings'),
                        icon: Icons.tune,
                        label: t.quickSettings,
                        value: t.quickSettingsHint,
                        detail: t.quickOpen,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(context.pushNamed(AppRouteNames.settings));
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      color: color,
      padding: const EdgeInsets.all(AppSpacing.s14),
      child: SizedBox(
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.primary, size: 20),
            const SizedBox(height: AppSpacing.s10),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
