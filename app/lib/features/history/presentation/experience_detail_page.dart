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
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../domain/history_experience.dart';
import '../providers/history_providers.dart';

class ExperienceDetailPage extends ConsumerWidget {
  const ExperienceDetailPage({super.key, required this.experienceId});

  final String experienceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.history;
    final async = ref.watch(experienceDetailProvider(experienceId));

    return AppScaffold(
      title: t.detailTitle,
      centerBody: false,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.detailFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () =>
                ref.invalidate(experienceDetailProvider(experienceId)),
          ),
        ),
        data: (experience) => _ExperienceDetail(experience: experience),
      ),
    );
  }
}

class _ExperienceDetail extends StatelessWidget {
  const _ExperienceDetail({required this.experience});

  final HistoryExperience experience;

  @override
  Widget build(BuildContext context) {
    final t = context.t.history;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final evidence = experience.sources
        .where((source) => source.type == 'message')
        .toList();
    final expressions = experience.expressions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s8,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      children: [
        _KindLabel(isLife: experience.isLife, label: _kindLabel(t, experience)),
        const SizedBox(height: AppSpacing.s12),
        Text(experience.summary, style: textTheme.displayMedium),
        if (experience.detail != null &&
            experience.detail!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            experience.detail!,
            style: textTheme.bodyLarge?.copyWith(color: palette.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.s20),
        _SectionLabel(label: t.evidence),
        const SizedBox(height: AppSpacing.s8),
        for (final source in evidence)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(color: palette.line),
              ),
              child: Text(source.quote ?? '', style: textTheme.bodyMedium),
            ),
          ),
        if (expressions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          _SectionLabel(label: t.expressions),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s6,
            children: [
              for (final expression in expressions)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s10,
                    vertical: AppSpacing.s6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.warm,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    expression,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s20),
        TextButton(
          key: const Key('history.openFocus'),
          onPressed: () => _openFocus(context, experience),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          child: Text(
            '${t.openFocus}: ${experience.focusTitle}',
            style: textTheme.bodyLarge?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        AppButton(
          key: const Key('history.openConversation'),
          label: t.openConversation,
          onPressed: () {
            unawaited(
              context.pushNamed(
                AppRouteNames.talk,
                pathParameters: {'conversationId': experience.conversationId},
                queryParameters: {
                  if (experience.focusTitle.trim().isNotEmpty)
                    'title': experience.focusTitle,
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _KindLabel extends StatelessWidget {
  const _KindLabel({required this.isLife, required this.label});

  final bool isLife;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.eyebrow.copyWith(
        color: isLife ? palette.accent : palette.primary,
      ),
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

String _kindLabel(Translations$history$en t, HistoryExperience experience) {
  return experience.isLife ? t.life : t.learning;
}

void _openFocus(BuildContext context, HistoryExperience experience) {
  if (experience.focusType == 'word') {
    unawaited(
      context.pushNamed(
        AppRouteNames.words,
        queryParameters: {'wordId': experience.focusId},
      ),
    );
    return;
  }
  unawaited(
    context.pushNamed(
      AppRouteNames.talk,
      pathParameters: {'conversationId': experience.conversationId},
      queryParameters: {
        if (experience.focusTitle.trim().isNotEmpty)
          'title': experience.focusTitle,
      },
    ),
  );
}
