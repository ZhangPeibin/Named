import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/main_navigation_bar.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../domain/history_experience.dart';
import '../providers/history_providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  var _loadingMore = false;

  Future<void> _loadMore() async {
    if (_loadingMore) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      await ref.read(historyControllerProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    await ref.read(historyControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.history;
    final async = ref.watch(historyControllerProvider);

    return AppScaffold(
      title: t.title,
      centerBody: false,
      bottomNavigationBar: const MainNavigationBar(currentIndex: 3),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(historyControllerProvider),
          ),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return Center(
              child: AppEmptyView(title: t.empty, message: t.emptyHint),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _HistoryList(
              state: state,
              loadingMore: _loadingMore,
              onLoadMore: _loadMore,
              onOpen: (item) {
                unawaited(
                  context.pushNamed(
                    AppRouteNames.experience,
                    pathParameters: {'experienceId': item.id},
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.state,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onOpen,
  });

  final HistoryState state;
  final bool loadingMore;
  final Future<void> Function() onLoadMore;
  final ValueChanged<HistoryExperience> onOpen;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    DateTime? currentDay;
    for (final item in state.items) {
      final day = DateUtils.dateOnly(item.createdAt.toLocal());
      if (currentDay == null || !DateUtils.isSameDay(day, currentDay)) {
        widgets.add(_DayHeader(label: _dayLabel(context, day)));
        currentDay = day;
      }
      widgets.add(_ExperienceCard(item: item, onTap: () => onOpen(item)));
    }
    if (state.nextCursor != null) {
      widgets.add(
        Center(
          child: TextButton(
            key: const Key('history.loadEarlier'),
            onPressed: loadingMore ? null : () => unawaited(onLoadMore()),
            child: loadingMore
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.t.history.loadEarlier),
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('history.list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      itemCount: widgets.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) => widgets[index],
    );
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final timeline = context.t.timeline;
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(day, today)) {
      return timeline.today;
    }
    if (DateUtils.isSameDay(day, today.subtract(const Duration(days: 1)))) {
      return timeline.yesterday;
    }
    return MaterialLocalizations.of(context).formatMediumDate(day);
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8, bottom: AppSpacing.s4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.eyebrow.copyWith(color: context.appPalette.muted),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.item, required this.onTap});

  final HistoryExperience item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t.history;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final isLife = item.isLife;

    return AppCard(
      onTap: onTap,
      key: Key('history.experience.${item.id}'),
      semanticLabel: '${_kindLabel(t, item)}: ${item.summary}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KindBadge(isLife: isLife, label: _kindLabel(t, item)),
          const SizedBox(height: AppSpacing.s8),
          Text(item.summary, style: textTheme.headlineMedium),
          if (item.detail != null && item.detail!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s6),
            Text(
              item.detail!,
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s6,
            children: [
              _MetaChip(icon: Icons.book_outlined, label: item.focusTitle),
              for (final expression in item.expressions.take(2))
                _MetaChip(icon: Icons.translate, label: expression),
            ],
          ),
        ],
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.isLife, required this.label});

  final bool isLife;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = isLife ? palette.accent : palette.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isLife ? palette.warm : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.primary),
          const SizedBox(width: AppSpacing.s4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: palette.primary),
          ),
        ],
      ),
    );
  }
}

String _kindLabel(Translations$history$en t, HistoryExperience item) {
  return item.isLife ? t.life : t.learning;
}
