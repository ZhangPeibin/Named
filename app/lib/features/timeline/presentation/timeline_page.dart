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
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../domain/timeline_item.dart';
import '../providers/timeline_providers.dart';
import 'widgets/moment_card.dart';
import 'widgets/named_composer.dart';
import 'widgets/talk_event_card.dart';
import 'widgets/word_naming_card.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _error;
  String? _startingTalkId;
  bool _isSubmitting = false;
  bool _isLoadingEarlier = false;
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(timelineControllerProvider.notifier).createNamed(text);
      if (!mounted) {
        return;
      }
      _textController.clear();
      _scheduleScrollToBottom(animate: true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _loadEarlier() async {
    if (_isLoadingEarlier) {
      return;
    }
    setState(() => _isLoadingEarlier = true);
    try {
      await ref.read(timelineControllerProvider.notifier).loadEarlier();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingEarlier = false);
      }
    }
  }

  Future<void> _openWordTalk(TimelineWordItem item) async {
    if (_startingTalkId != null) {
      return;
    }
    setState(() {
      _error = null;
      _startingTalkId = item.id;
    });
    try {
      final controller = ref.read(timelineControllerProvider.notifier);
      final conversationId = await controller.ensureConversation(item);
      if (!mounted) {
        return;
      }
      final title = item.word?.spelling ?? item.inputText;
      await context.pushNamed(
        AppRouteNames.talk,
        pathParameters: {'conversationId': conversationId},
        queryParameters: {
          if (title != null && title.trim().isNotEmpty) 'title': title,
        },
      );
      if (!mounted) {
        return;
      }
      await controller.afterTalk(
        conversationId: conversationId,
        title: item.word?.spelling ?? item.inputText ?? 'Talk',
      );
      _scheduleScrollToBottom(animate: true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _startingTalkId = null);
      }
    }
  }

  Future<void> _openSceneTalk(TimelineSceneItem item) async {
    if (_startingTalkId != null) {
      return;
    }
    setState(() {
      _error = null;
      _startingTalkId = item.id;
    });
    try {
      final controller = ref.read(timelineControllerProvider.notifier);
      final conversationId = await controller.ensureSceneConversation(item);
      if (!mounted) {
        return;
      }
      await context.pushNamed(
        AppRouteNames.talk,
        pathParameters: {'conversationId': conversationId},
        queryParameters: {
          if (item.scene.naturalEnglish.trim().isNotEmpty)
            'title': item.scene.naturalEnglish,
        },
      );
      if (!mounted) {
        return;
      }
      await controller.afterTalk(
        conversationId: conversationId,
        title: item.scene.naturalEnglish,
      );
      _scheduleScrollToBottom(animate: true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _startingTalkId = null);
      }
    }
  }

  Future<void> _openTalkEvent(TimelineTalkItem item) async {
    await context.pushNamed(
      AppRouteNames.talk,
      pathParameters: {'conversationId': item.conversationId},
      queryParameters: {if (item.title.trim().isNotEmpty) 'title': item.title},
    );
    if (!mounted) {
      return;
    }
    try {
      await ref
          .read(timelineControllerProvider.notifier)
          .afterTalk(conversationId: item.conversationId, title: item.title);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _openMenu() async {
    final destination = await showAppBottomSheet<String>(
      context: context,
      builder: (context) => const _TimelineMenu(),
    );
    if (!mounted || destination == null) {
      return;
    }
    unawaited(context.pushNamed(destination));
  }

  void _scheduleScrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        unawaited(
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.timeline;
    final async = ref.watch(timelineControllerProvider);

    return AppScaffold(
      title: '',
      showAppBar: false,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: AppErrorView(
                  title: t.loadFailed,
                  message: error is ApiException
                      ? error.message
                      : context.t.common.somethingWentWrong,
                  onRetry: () => ref.invalidate(timelineControllerProvider),
                ),
              ),
              data: (state) => _buildTimeline(context, state, t),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s8,
                AppSpacing.s20,
                0,
              ),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appPalette.error,
                ),
              ),
            ),
          NamedComposer(
            controller: _textController,
            hintText: t.composerHint,
            sendTooltip: t.send,
            menuTooltip: t.menuTitle,
            isSubmitting: _isSubmitting,
            onSend: _send,
            onOpenMenu: _openMenu,
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    TimelineState state,
    Translations$timeline$en t,
  ) {
    if (state.items.isEmpty) {
      return _EmptyTimeline(t: t);
    }

    if (!_didInitialScroll) {
      _didInitialScroll = true;
      _scheduleScrollToBottom();
    }

    final widgets = <Widget>[];
    if (state.nextCursor != null) {
      widgets.add(
        Center(
          child: TextButton(
            onPressed: _isLoadingEarlier ? null : _loadEarlier,
            child: _isLoadingEarlier
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.loadEarlier),
          ),
        ),
      );
    }

    DateTime? currentDay;
    for (final item in state.items) {
      final day = DateUtils.dateOnly(item.createdAt.toLocal());
      if (currentDay == null || !DateUtils.isSameDay(day, currentDay)) {
        widgets.add(_DaySeparator(label: _dayLabel(context, day)));
        currentDay = day;
      }
      switch (item) {
        case TimelineWordItem():
          widgets.add(
            WordNamingCard(
              item: item,
              isStartingTalk: _startingTalkId == item.id,
              onTalk: () => _openWordTalk(item),
            ),
          );
        case TimelineSceneItem():
          widgets.add(
            MomentCard(
              item: item,
              isStartingTalk: _startingTalkId == item.id,
              onTalk: () => _openSceneTalk(item),
            ),
          );
        case TimelineTalkItem():
          widgets.add(
            TalkEventCard(item: item, onTap: () => _openTalkEvent(item)),
          );
      }
    }

    return ListView.separated(
      key: const Key('timeline.list'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s24,
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
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.t});

  final Translations$timeline$en t;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(Icons.eco_outlined, color: palette.primary, size: 30),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              t.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: AppSpacing.s10),
            Text(
              t.emptyCopy,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              t.emptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

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

class _TimelineMenu extends StatelessWidget {
  const _TimelineMenu();

  @override
  Widget build(BuildContext context) {
    final t = context.t.timeline;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.menuTitle.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(
            color: context.appPalette.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        _MenuRow(
          icon: Icons.refresh,
          label: t.menuReview,
          routeName: AppRouteNames.review,
        ),
        _MenuRow(
          icon: Icons.menu_book_outlined,
          label: t.menuWords,
          routeName: AppRouteNames.words,
        ),
        _MenuRow(
          icon: Icons.person_outline,
          label: t.menuMe,
          routeName: AppRouteNames.me,
        ),
        _MenuRow(
          icon: Icons.settings_outlined,
          label: t.menuSettings,
          routeName: AppRouteNames.settings,
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.routeName,
  });

  final IconData icon;
  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: AppSize.size34,
        height: AppSize.size34,
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Icon(icon, color: palette.primary, size: AppSize.size18),
      ),
      title: Text(label),
      trailing: Icon(Icons.chevron_right, color: palette.muted),
      onTap: () => Navigator.of(context).pop(routeName),
    );
  }
}
