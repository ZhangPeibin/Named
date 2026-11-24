import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../progress/providers/progress_providers.dart';
import '../domain/timeline_item.dart';
import '../providers/timeline_feed_providers.dart';
import '../providers/timeline_providers.dart';
import 'widgets/daily_task_card.dart';
import 'widgets/talk_event_card.dart';

enum TimelineFeedKind { talks, reads }

extension TimelineFeedKindX on TimelineFeedKind {
  String get type => switch (this) {
    TimelineFeedKind.talks => 'talk',
    TimelineFeedKind.reads => 'daily',
  };
}

class TimelineFeedPage extends ConsumerStatefulWidget {
  const TimelineFeedPage({super.key, required this.kind});

  final TimelineFeedKind kind;

  @override
  ConsumerState<TimelineFeedPage> createState() => _TimelineFeedPageState();
}

class _TimelineFeedPageState extends ConsumerState<TimelineFeedPage> {
  final _scrollController = ScrollController();
  var _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_loadingMore ||
        !_scrollController.hasClients ||
        _scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    final state = ref
        .read(timelineFeedControllerProvider(widget.kind.type))
        .value;
    if (state?.nextCursor == null) {
      return;
    }
    unawaited(_loadMore());
  }

  Future<void> _loadMore() async {
    if (_loadingMore) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      await ref
          .read(timelineFeedControllerProvider(widget.kind.type).notifier)
          .loadMore();
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    await ref
        .read(timelineFeedControllerProvider(widget.kind.type).notifier)
        .refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isTalks = widget.kind == TimelineFeedKind.talks;
    final title = isTalks ? context.t.talks.title : context.t.reads.title;
    final loadFailed = isTalks
        ? context.t.talks.loadFailed
        : context.t.reads.loadFailed;
    final empty = isTalks ? context.t.talks.empty : context.t.reads.empty;
    final emptyHint = isTalks
        ? context.t.talks.emptyHint
        : context.t.reads.emptyHint;
    final provider = timelineFeedControllerProvider(widget.kind.type);
    final async = ref.watch(provider);

    return AppScaffold(
      title: title,
      centerBody: false,
      body: async.when(
        loading: () => const Center(child: AppLoadingView()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(provider),
          ),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return Center(
              child: AppEmptyView(
                title: empty,
                message: emptyHint,
                icon: isTalks ? AppLineGlyph.chat : AppLineGlyph.headphones,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _buildList(context, state),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, TimelineFeedState state) {
    final widgets = <Widget>[];
    DateTime? currentDay;

    for (final item in state.items) {
      final day = switch (item) {
        TimelineDailyItem() => DateUtils.dateOnly(item.readingDate.toLocal()),
        _ => DateUtils.dateOnly(item.createdAt.toLocal()),
      };
      if (currentDay == null || !DateUtils.isSameDay(day, currentDay)) {
        widgets.add(_FeedDayHeader(label: _dayLabel(context, day)));
        currentDay = day;
      }
      switch (item) {
        case TimelineTalkItem():
          widgets.add(
            TalkEventCard(item: item, onTap: () => unawaited(_openTalk(item))),
          );
        case TimelineDailyItem():
          widgets.add(
            DailyTaskCard(item: item, onTap: () => unawaited(_openDaily(item))),
          );
        case TimelineWordItem():
        case TimelineSceneItem():
        case TimelineQuestionItem():
          break;
      }
    }

    if (_loadingMore) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
          child: Center(
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.s12,
        bottom: AppSpacing.s24,
      ),
      itemCount: widgets.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) => widgets[index],
    );
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final t = context.t.timeline;
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(day, today)) {
      return t.today;
    }
    if (DateUtils.isSameDay(day, today.subtract(const Duration(days: 1)))) {
      return t.yesterday;
    }
    return MaterialLocalizations.of(context).formatMediumDate(day);
  }

  Future<void> _openTalk(TimelineTalkItem item) async {
    await context.pushNamed(
      AppRouteNames.talk,
      pathParameters: {'conversationId': item.conversationId},
      queryParameters: {if (item.title.trim().isNotEmpty) 'title': item.title},
    );
    if (!mounted) {
      return;
    }
    ref.invalidate(progressProvider);
    ref.invalidate(timelineFeedControllerProvider(widget.kind.type));
    ref.invalidate(timelineControllerProvider);
  }

  Future<void> _openDaily(TimelineDailyItem item) async {
    final date = item.readingDate.toIso8601String().split('T').first;
    await context.pushNamed(
      AppRouteNames.daily,
      queryParameters: {'date': date},
    );
    if (!mounted) {
      return;
    }
    ref.invalidate(progressProvider);
    ref.invalidate(timelineFeedControllerProvider(widget.kind.type));
    ref.invalidate(timelineControllerProvider);
  }
}

class _FeedDayHeader extends StatelessWidget {
  const _FeedDayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(width: AppSpacing.s10),
        Expanded(child: Container(height: 1, color: palette.line)),
      ],
    );
  }
}
