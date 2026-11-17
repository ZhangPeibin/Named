import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../assistant/domain/assistant_intent.dart';
import '../../assistant/providers/assistant_providers.dart';
import '../../challenge/providers/challenge_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../words/domain/word_shelf.dart';
import '../../words/providers/words_providers.dart';
import '../domain/timeline_item.dart';
import '../providers/timeline_providers.dart';
import 'composer_hint.dart';
import 'widgets/daily_task_card.dart';
import 'widgets/moment_card.dart';
import 'widgets/named_composer.dart';
import 'widgets/question_thread_card.dart';
import 'widgets/talk_event_card.dart';
import 'widgets/timeline_progress_card.dart';
import 'widgets/word_naming_card.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _error;
  String? _startingTalkId;
  bool _isSubmitting = false;
  bool _isLoadingEarlier = false;
  bool _didInitialScroll = false;
  late final ComposerHintSelector _hintSelector;
  Timer? _hintTimer;
  Timer? _dayTimer;
  DateTime _currentDay = DateUtils.dateOnly(DateTime.now());
  ComposerHintCategory _hintCategory = ComposerHintCategory.discovery;
  bool _hintPaused = false;

  static const _hintInterval = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _hintSelector = ref.read(composerHintSelectorProvider);
    _textController.addListener(_handleComposerTextChanged);
    _scrollController.addListener(_handleTimelineScroll);
    _hintTimer = Timer.periodic(_hintInterval, (_) => _advanceHint());
    _dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshIfDayChanged(),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfDayChanged();
    }
  }

  void _refreshIfDayChanged() {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(today, _currentDay)) {
      return;
    }
    _currentDay = today;
    ref.invalidate(timelineControllerProvider);
    ref.invalidate(progressProvider);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _textController
      ..removeListener(_handleComposerTextChanged)
      ..dispose();
    _scrollController
      ..removeListener(_handleTimelineScroll)
      ..dispose();
    super.dispose();
  }

  void _handleComposerTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText) {
      _hintPaused = true;
      return;
    }
    if (_hintPaused) {
      _hintPaused = false;
      _advanceHint();
    }
  }

  void _advanceHint() {
    if (!mounted || _isSubmitting || _textController.text.trim().isNotEmpty) {
      return;
    }
    final challenges = ref.read(challengesProvider);
    final shelf = ref.read(wordShelfProvider);
    final hasActiveChallenge = challenges.hasValue
        ? challenges.value!.any((challenge) => challenge.isActive)
        : null;
    final reviewCount =
        shelf.value?.words
            .where((word) => word.status == WordShelfStatus.needsReview)
            .length ??
        0;
    final next = _hintSelector.next(
      options: _composerHintOptions(context.t.timeline),
      weights: composerHintWeights(
        hasActiveChallenge: hasActiveChallenge,
        reviewCount: reviewCount,
      ),
      previous: _hintCategory,
    );
    if (next.category != _hintCategory) {
      setState(() => _hintCategory = next.category);
    }
  }

  void _handleTimelineScroll() {
    if (!_didInitialScroll ||
        _isLoadingEarlier ||
        !_scrollController.hasClients ||
        _scrollController.position.pixels > 160) {
      return;
    }
    final state = ref.read(timelineControllerProvider).value;
    if (state?.nextCursor == null) {
      return;
    }
    unawaited(_loadEarlier());
  }

  Future<void> _loadEarlier() async {
    if (_isLoadingEarlier) {
      return;
    }
    final state = ref.read(timelineControllerProvider).value;
    if (state?.nextCursor == null) {
      return;
    }
    final beforeMax = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final beforeOffset = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;
    setState(() => _isLoadingEarlier = true);
    try {
      await ref.read(timelineControllerProvider.notifier).loadEarlier();
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) {
          return;
        }
        final position = _scrollController.position;
        final target = beforeOffset + position.maxScrollExtent - beforeMax;
        position.jumpTo(target.clamp(0.0, position.maxScrollExtent));
      });
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

  List<ComposerHintOption> _composerHintOptions(Translations$timeline$en t) {
    return [
      ComposerHintOption(
        category: ComposerHintCategory.discovery,
        text: t.composerHint,
      ),
      ComposerHintOption(
        category: ComposerHintCategory.openWords,
        text: t.composerHintWords,
      ),
      ComposerHintOption(
        category: ComposerHintCategory.review,
        text: t.composerHintReview,
      ),
      ComposerHintOption(
        category: ComposerHintCategory.startChallenge,
        text: t.composerHintStartChallenge,
      ),
      ComposerHintOption(
        category: ComposerHintCategory.viewChallenges,
        text: t.composerHintViewChallenges,
      ),
    ];
  }

  String _hintText(Translations$timeline$en t) {
    return switch (_hintCategory) {
      ComposerHintCategory.discovery => t.composerHint,
      ComposerHintCategory.openWords => t.composerHintWords,
      ComposerHintCategory.review => t.composerHintReview,
      ComposerHintCategory.startChallenge => t.composerHintStartChallenge,
      ComposerHintCategory.viewChallenges => t.composerHintViewChallenges,
    };
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
      final intent = await ref.read(assistantRepositoryProvider).route(text);
      if (!mounted) {
        return;
      }
      if (intent.hasAction) {
        _textController.clear();
        FocusScope.of(context).unfocus();
        switch (intent.intent) {
          case AssistantIntent.openWords:
            unawaited(context.pushNamed(AppRouteNames.words));
            break;
          case AssistantIntent.reviewWords:
            unawaited(context.pushNamed(AppRouteNames.review));
            break;
          case AssistantIntent.viewChallenges:
            unawaited(context.pushNamed(AppRouteNames.challenges));
            break;
          case AssistantIntent.startChallenge:
            final challenges = await ref.read(challengesProvider.future);
            if (!mounted) {
              break;
            }
            final active = challenges
                .where((challenge) => challenge.isActive)
                .firstOrNull;
            if (active == null) {
              unawaited(context.pushNamed(AppRouteNames.challengeNew));
            } else {
              unawaited(
                context.pushNamed(
                  AppRouteNames.challengeDetail,
                  pathParameters: {'challengeId': active.id},
                ),
              );
            }
            break;
          case AssistantIntent.none:
            break;
        }
        return;
      }
      await ref.read(timelineControllerProvider.notifier).createNamed(text);
      if (!mounted) {
        return;
      }
      ref.invalidate(wordShelfProvider);
      ref.invalidate(progressProvider);
      _textController.clear();
      _scheduleScrollToBottom(animate: true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (_textController.text.trim().isEmpty) {
          _advanceHint();
        }
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
      ref.invalidate(progressProvider);
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
      ref.invalidate(progressProvider);
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

  void _settleScrollToBottom([int remaining = 4]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      if (remaining > 0) {
        _settleScrollToBottom(remaining - 1);
      }
    });
  }

  void _handleProgressExpansion(bool expanded) {
    if (!expanded) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scheduleScrollToBottom(animate: true);
      }
    });
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
    final progress = ref.watch(progressProvider);
    ref
      ..listen(challengesProvider, (previous, next) {
        if (next.hasValue) {
          _advanceHint();
        }
      })
      ..listen(wordShelfProvider, (previous, next) {
        if (next.hasValue) {
          _advanceHint();
        }
      });

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
          if (progress.hasValue)
            TimelineProgressCard(
              progress: progress.value!,
              onExpansionChanged: _handleProgressExpansion,
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
            hintText: _hintText(t),
            sendTooltip: t.send,
            meTooltip: context.t.navigation.me,
            askTooltip: context.t.ask.entryTooltip,
            isSubmitting: _isSubmitting,
            onSend: _send,
            onOpenMe: () => unawaited(context.pushNamed(AppRouteNames.me)),
            onOpenAsk: () => unawaited(_openAsk()),
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  Future<void> _openAsk({String? threadId}) async {
    final queryParameters = <String, String>{};
    if (threadId != null) {
      queryParameters['threadId'] = threadId;
    }
    await context.pushNamed(
      AppRouteNames.ask,
      queryParameters: queryParameters,
    );
    if (mounted) {
      ref.invalidate(timelineControllerProvider);
      ref.invalidate(progressProvider);
    }
  }

  Future<void> _openDaily(TimelineDailyItem item) async {
    final date = item.readingDate.toIso8601String().split('T').first;
    await context.pushNamed(
      AppRouteNames.daily,
      queryParameters: {'date': date},
    );
    if (mounted) {
      ref.invalidate(progressProvider);
      ref.invalidate(timelineControllerProvider);
    }
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
      _settleScrollToBottom();
    }

    final widgets = <Widget>[
      if (_isLoadingEarlier)
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s8),
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
    ];
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
        case TimelineDailyItem():
          widgets.add(
            DailyTaskCard(item: item, onTap: () => unawaited(_openDaily(item))),
          );
        case TimelineQuestionItem():
          widgets.add(
            QuestionThreadCard(
              item: item,
              onTap: () => unawaited(_openAsk(threadId: item.id)),
            ),
          );
      }
    }
    return ListView.separated(
      key: const Key('timeline.list'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
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
            const SizedBox(height: AppSpacing.s16),
            Text(
              t.commandHint,
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
