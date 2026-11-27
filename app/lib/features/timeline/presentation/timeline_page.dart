import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/key_value_storage_provider.dart';
import '../../../core/speech/speech_providers.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../assistant/domain/assistant_intent.dart';
import '../../assistant/domain/command_hint.dart';
import '../../assistant/providers/assistant_providers.dart';
import '../../challenge/providers/challenge_providers.dart';
import '../../companion/presentation/companion_greeting_line.dart';
import '../../companion/presentation/widgets/companion_card.dart';
import '../../companion/presentation/widgets/companion_greeting_dialog.dart';
import '../../companion/presentation/widgets/companion_setup_sheet.dart';
import '../../companion/providers/companion_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../words/providers/words_providers.dart';
import '../domain/timeline_item.dart';
import '../providers/timeline_providers.dart';
import 'composer_hint.dart';
import 'trail_visibility.dart';
import 'widgets/challenge_carousel.dart';
import 'widgets/daily_task_card.dart';
import 'widgets/moment_card.dart';
import 'widgets/named_composer.dart';
import 'widgets/pending_naming_card.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin, RouteAware {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _error;
  String? _startingTalkId;
  bool _hideCompanionInvite = false;
  bool _isSubmitting = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isLoadingEarlier = false;
  bool _didInitialScroll = false;
  late final ComposerHintSelector _hintSelector;
  Timer? _hintTimer;
  Timer? _dayTimer;
  DateTime _currentDay = DateUtils.dateOnly(DateTime.now());
  ComposerHintCategory _hintCategory = ComposerHintCategory.discovery;
  bool _hintPaused = false;
  late final AnimationController _trailVisibility;
  Timer? _trailEnableTimer;
  bool _trailVisibilityReady = false;
  bool _trailVisible = true;
  bool _preparingGreeting = false;
  bool _greetingChecked = false;

  static const _hintInterval = Duration(seconds: 6);
  static const _lastVisitKey = 'app.lastVisit';
  static const _lastGreetingDayKey = 'app.lastGreetingDay';

  @override
  void initState() {
    super.initState();
    _hintSelector = ref.read(composerHintSelectorProvider);
    _textController.addListener(_handleComposerTextChanged);
    _scrollController.addListener(_handleTimelineScroll);
    _trailVisibility = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _trailEnableTimer = Timer(const Duration(milliseconds: 500), () {
      _trailVisibilityReady = true;
    });
    _hintTimer = Timer.periodic(_hintInterval, (_) => _advanceHint());
    _dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshIfDayChanged(),
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(_maybeShowDailyGreeting());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfDayChanged();
      unawaited(_maybeShowDailyGreeting());
    }
  }

  @override
  void didPopNext() {
    unawaited(_maybeShowDailyGreeting());
  }

  void _refreshIfDayChanged() {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(today, _currentDay)) {
      return;
    }
    _currentDay = today;
    _greetingChecked = false;
    ref.invalidate(timelineControllerProvider);
    ref.invalidate(progressProvider);
    unawaited(_maybeShowDailyGreeting());
  }

  bool get _isTimelineVisible => ModalRoute.of(context)?.isCurrent ?? false;

  Future<void> _maybeShowDailyGreeting() async {
    if (_greetingChecked || _preparingGreeting) {
      return;
    }
    _preparingGreeting = true;
    try {
      final profile = await ref.read(companionProvider.future);
      if (!mounted || !profile.isNamed) {
        return;
      }
      final storage = ref.read(keyValueStorageProvider);
      final now = DateTime.now();
      final todayKey = DateUtils.dateOnly(now).toIso8601String();
      final lastGreetingDay = await storage.getString(_lastGreetingDayKey);
      if (!mounted) {
        return;
      }
      if (lastGreetingDay == todayKey) {
        _greetingChecked = true;
        return;
      }
      final progress = await ref.read(progressProvider.future);
      if (!mounted) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted || !_isTimelineVisible) {
        return;
      }
      final lastVisitRaw = await storage.getString(_lastVisitKey);
      final lastVisit = lastVisitRaw == null
          ? null
          : DateTime.tryParse(lastVisitRaw);
      final returning =
          lastVisit != null && now.difference(lastVisit).inDays >= 3;
      await storage.setString(_lastVisitKey, now.toIso8601String());
      await storage.setString(_lastGreetingDayKey, todayKey);
      if (!mounted || !_isTimelineVisible) {
        return;
      }
      _greetingChecked = true;
      final line = companionGreetingLine(
        context,
        progress,
        returning: returning,
      );
      await showDialog<void>(
        context: context,
        builder: (context) =>
            CompanionGreetingDialog(name: profile.name ?? '', text: line),
      );
    } catch (_) {
      return;
    } finally {
      _preparingGreeting = false;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _hintTimer?.cancel();
    _dayTimer?.cancel();
    _trailEnableTimer?.cancel();
    _trailVisibility.dispose();
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
    final hasActiveChallenge = challenges.hasValue
        ? challenges.value!.any((challenge) => challenge.isActive)
        : null;
    final next = _hintSelector.next(
      options: _composerHintOptions(context.t.timeline),
      weights: composerHintWeights(hasActiveChallenge: hasActiveChallenge),
      previous: _hintCategory,
    );
    if (next.category != _hintCategory) {
      setState(() => _hintCategory = next.category);
    }
  }

  void _handleTimelineScroll() {
    _updateTrailVisibility();
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

  void _updateTrailVisibility() {
    if (!_trailVisibilityReady || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final shouldShow = shouldShowTrail(
      currentlyVisible: _trailVisible,
      maxScrollExtent: position.maxScrollExtent,
      pixels: position.pixels,
    );
    if (shouldShow == _trailVisible) {
      return;
    }
    _trailVisible = shouldShow;
    _setTrailVisible(shouldShow);
  }

  void _setTrailVisible(bool visible) {
    final target = visible ? 1.0 : 0.0;
    if ((_trailVisibility.value - target).abs() < 0.01) {
      return;
    }
    if (visible) {
      unawaited(
        _trailVisibility.animateTo(
          1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      unawaited(
        _trailVisibility.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        ),
      );
    }
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
    if (_isRecording) {
      return t.listening;
    }
    if (_isTranscribing) {
      return t.transcribing;
    }
    return switch (_hintCategory) {
      ComposerHintCategory.discovery => t.composerHint,
      ComposerHintCategory.openWords => t.composerHintWords,
      ComposerHintCategory.startChallenge => t.composerHintStartChallenge,
      ComposerHintCategory.viewChallenges => t.composerHintViewChallenges,
    };
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      if (mightBeAppCommand(text)) {
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
            case AssistantIntent.viewChallenges:
              unawaited(context.pushNamed(AppRouteNames.challenges));
              break;
            case AssistantIntent.startChallenge:
              unawaited(context.pushNamed(AppRouteNames.challengeNew));
              break;
            case AssistantIntent.none:
              break;
          }
          return;
        }
      }
      final naming = ref
          .read(timelineControllerProvider.notifier)
          .createNamed(text);
      _scheduleScrollToBottom(animate: true);
      await naming;
      if (!mounted) {
        return;
      }
      ref.invalidate(wordShelfProvider);
      ref.invalidate(progressProvider);
      _textController.clear();
      _settleScrollToBottom();
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

  Future<void> _toggleVoice() async {
    if (_isSubmitting || _isTranscribing) {
      return;
    }
    final voice = ref.read(voiceInputProvider);
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _error = null;
      });
      try {
        final text = await voice.stopAndTranscribe();
        if (!mounted) {
          return;
        }
        if (text == null) {
          setState(() => _isTranscribing = false);
          return;
        }
        _textController.text = text;
        _textController.selection = TextSelection.collapsed(
          offset: text.length,
        );
        setState(() => _isTranscribing = false);
        await _send();
      } on ApiException catch (error) {
        if (mounted) {
          setState(() {
            _isTranscribing = false;
            _error = error.code == 'no_speech' ? null : error.message;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isTranscribing = false;
            _error = context.t.timeline.audioUnavailable;
          });
        }
      }
      return;
    }

    try {
      if (!await voice.hasPermission()) {
        if (mounted) {
          setState(() => _error = context.t.timeline.micDenied);
        }
        return;
      }
      if (!mounted) {
        return;
      }
      FocusScope.of(context).unfocus();
      await voice.start();
      if (mounted) {
        setState(() {
          _isRecording = true;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.t.timeline.micDenied);
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
    final companion = ref.watch(companionProvider).value;
    ref.listen(companionProvider, (previous, next) {
      if (next.value?.isNamed == true && !_greetingChecked) {
        unawaited(_maybeShowDailyGreeting());
      }
    });
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

    Widget? companionEntry;
    final profile = companion;
    if (profile != null &&
        !profile.isNamed &&
        !(profile.setupDismissed && _hideCompanionInvite)) {
      companionEntry = profile.setupDismissed
          ? CompanionInviteRow(
              onName: () => unawaited(_openCompanionSetup()),
              onHide: () => setState(() => _hideCompanionInvite = true),
            )
          : CompanionFirstRunCard(
              onName: () => unawaited(_openCompanionSetup()),
              onLater: () => unawaited(_dismissCompanionSetup()),
            );
    }

    return AppScaffold(
      title: '',
      showAppBar: false,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: async.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: AppErrorView(
                        title: t.loadFailed,
                        message: error is ApiException
                            ? error.message
                            : context.t.common.somethingWentWrong,
                        onRetry: () =>
                            ref.invalidate(timelineControllerProvider),
                      ),
                    ),
                    data: (state) =>
                        _buildTimeline(context, state, t, companionEntry),
                  ),
                ),
              ],
            ),
          ),
          if (progress.hasValue)
            ClipRect(
              child: SizeTransition(
                sizeFactor: _trailVisibility,
                axisAlignment: 1,
                child: FadeTransition(
                  opacity: _trailVisibility,
                  child: TimelineProgressCard(
                    progress: progress.value!,
                    onWordsTap: () => unawaited(_openWords()),
                    onTalksTap: () => unawaited(_openTalks()),
                    onReadsTap: () => unawaited(_openReads()),
                    onPracticesTap: () => unawaited(_openPractice()),
                  ),
                ),
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
            hintText: _hintText(t),
            sendTooltip: t.send,
            meTooltip: context.t.navigation.me,
            askTooltip: context.t.ask.entryTooltip,
            speakTooltip: t.speak,
            stopTooltip: t.stopRecording,
            isSubmitting: _isSubmitting,
            isRecording: _isRecording,
            isTranscribing: _isTranscribing,
            onSend: _send,
            onOpenMe: () => unawaited(context.pushNamed(AppRouteNames.me)),
            onOpenAsk: () => unawaited(_openAsk()),
            onToggleRecording: () => unawaited(_toggleVoice()),
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  Future<void> _openCompanionSetup() async {
    await showCompanionSetupSheet(context);
  }

  Future<void> _dismissCompanionSetup() async {
    try {
      await ref.read(companionControllerProvider).dismissSetup();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
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

  Future<void> _openWords() async {
    await context.pushNamed(AppRouteNames.words);
    if (mounted) {
      ref.invalidate(wordShelfProvider);
    }
  }

  Future<void> _openPractice() async {
    await context.pushNamed(AppRouteNames.practice);
    if (mounted) {
      ref.invalidate(progressProvider);
    }
  }

  Future<void> _openTalks() async {
    await context.pushNamed(AppRouteNames.talks);
    if (mounted) {
      ref.invalidate(progressProvider);
    }
  }

  Future<void> _openReads() async {
    await context.pushNamed(AppRouteNames.reads);
    if (mounted) {
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
    Widget? companionEntry,
  ) {
    if (state.items.isEmpty) {
      return ListView(
        key: const Key('timeline.list'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s24,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        children: [
          _EmptyTimeline(t: t),
          if (companionEntry != null) ...[
            const SizedBox(height: AppSpacing.s12),
            companionEntry,
          ],
        ],
      );
    }

    if (!_didInitialScroll) {
      _didInitialScroll = true;
      _settleScrollToBottom();
    }

    final hasActiveChallenge =
        ref.watch(challengesProvider).value?.any((c) => c.isActive) ?? false;

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
        case TimelinePendingItem():
          widgets.add(PendingNamingCard(item: item));
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
    if (hasActiveChallenge) {
      widgets.add(const ChallengeCarousel());
    }
    if (companionEntry != null) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s4),
          child: companionEntry,
        ),
      );
    }
    return ListView.separated(
      key: const Key('timeline.list'),
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              child: AppLineIcon(
                AppLineGlyph.leaf,
                color: palette.primary,
                size: 30,
              ),
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
