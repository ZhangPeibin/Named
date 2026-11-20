import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/audio/audio_playback_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/audio_speed_control.dart';
import '../../../i18n/strings.g.dart';
import '../../progress/providers/progress_providers.dart';
import '../../question/presentation/ask_launcher.dart';
import '../../sentence/presentation/sentence_detail_sheet.dart';
import '../../words/presentation/word_lookup_sheet.dart';
import '../domain/daily_read.dart';
import '../domain/reader_theme.dart';
import '../providers/daily_providers.dart';
import '../providers/reader_speed_provider.dart';
import '../providers/reader_theme_provider.dart';

class DailyReadPage extends ConsumerStatefulWidget {
  const DailyReadPage({super.key, this.date});

  final DateTime? date;

  @override
  ConsumerState<DailyReadPage> createState() => _DailyReadPageState();
}

class _DailyReadPageState extends ConsumerState<DailyReadPage>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _textKey = GlobalKey();
  final _audioKey = GlobalKey<_DailyAudioButtonState>();
  var _activeWordIndex = -1;
  double? _lastPassageLineTop;
  int _lastBilingualLineIndex = -1;
  var _showTranslation = false;
  var _translationLoading = false;
  DailyTranslation? _translation;
  DailyCompletion? _completion;
  List<GlobalKey> _lineKeys = const [];
  final _startedAt = DateTime.now();
  var _completing = false;
  Timer? _completionTimer;
  Timer? _followPauseTimer;
  var _autoFollow = true;
  var _showSpeed = false;
  var _chromeVisible = true;
  var _chromeHideArmed = false;
  Timer? _chromeTimer;
  final _readingProgress = ValueNotifier<double>(0);
  late final Ticker _followTicker;
  double? _scrollTarget;
  double? _lastTickSeconds;
  final _playbackRate = ValueNotifier<double>(readerSpeedDefault);

  bool get _isToday =>
      widget.date == null || DateUtils.isSameDay(widget.date, DateTime.now());

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _followTicker = createTicker(_onFollowTick);
    unawaited(_restorePlaybackRate());
    _chromeTimer = Timer(const Duration(milliseconds: 2600), _hideChrome);
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _followPauseTimer?.cancel();
    _chromeTimer?.cancel();
    _followTicker.dispose();
    _playbackRate.dispose();
    _readingProgress.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_isToday || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final max = position.maxScrollExtent;
    _readingProgress.value = max <= 0
        ? 0
        : (position.pixels / max).clamp(0.0, 1.0);
    if (max <= 0) {
      return;
    }
    if (position.pixels >= max - 24) {
      _scheduleCompletion();
    } else {
      _completionTimer?.cancel();
      _completionTimer = null;
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final isUserScroll =
        (notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is ScrollUpdateNotification &&
            notification.dragDetails != null);
    if (isUserScroll) {
      _pauseAutoFollow();
    }
    return false;
  }

  void _hideChrome() {
    _chromeTimer?.cancel();
    _chromeTimer = null;
    if (!mounted || !_chromeVisible) {
      return;
    }
    setState(() {
      _chromeVisible = false;
      _showSpeed = false;
    });
  }

  void _showChrome({bool autoHide = true}) {
    _chromeTimer?.cancel();
    if (!_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
    if (autoHide) {
      _chromeTimer = Timer(const Duration(milliseconds: 2600), _hideChrome);
    }
  }

  void _toggleChrome() {
    if (_chromeVisible) {
      _hideChrome();
    } else {
      _showChrome();
    }
  }

  void _armChromeHide() {
    if (_chromeHideArmed) {
      return;
    }
    _chromeHideArmed = true;
    _chromeTimer?.cancel();
    _chromeTimer = Timer(const Duration(milliseconds: 2600), _hideChrome);
  }

  void _pauseAutoFollow() {
    _autoFollow = false;
    _scrollTarget = null;
    _stopFollowTicker();
    _followPauseTimer?.cancel();
    _followPauseTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      _autoFollow = true;
      if (_audioKey.currentState?.isPlaying != true) {
        return;
      }
      _lastPassageLineTop = null;
      _lastBilingualLineIndex = -1;
      _scrollToActiveWord();
    });
  }

  void _seekAudio(int seconds) {
    _lastPassageLineTop = null;
    _lastBilingualLineIndex = -1;
    unawaited(_audioKey.currentState?.seekBy(seconds) ?? Future<void>.value());
  }

  void _startFollowTicker() {
    if (!_autoFollow || _followTicker.isActive) {
      return;
    }
    _lastTickSeconds = null;
    unawaited(_followTicker.start());
  }

  void _stopFollowTicker() {
    if (_followTicker.isActive) {
      _followTicker.stop();
    }
    _lastTickSeconds = null;
  }

  Future<void> _restorePlaybackRate() async {
    final rate = await ref.read(readerSpeedProvider.future);
    if (mounted) {
      _playbackRate.value = rate;
    }
  }

  void _onFollowTick(Duration elapsed) {
    final target = _scrollTarget;
    if (!mounted ||
        !_autoFollow ||
        target == null ||
        !_scrollController.hasClients) {
      return;
    }
    final seconds = elapsed.inMicroseconds / 1000000;
    final last = _lastTickSeconds;
    _lastTickSeconds = seconds;
    if (last == null) {
      return;
    }
    final dt = (seconds - last).clamp(0.0, 0.05);
    final position = _scrollController.position;
    final current = position.pixels;
    final error = target - current;
    if (error.abs() < 0.5) {
      position.jumpTo(target.clamp(0.0, position.maxScrollExtent));
      _scrollTarget = null;
      _stopFollowTicker();
      return;
    }
    final maxSpeed = (110 * _playbackRate.value).clamp(70.0, 180.0);
    final speed = (error * 5).clamp(-maxSpeed, maxSpeed);
    final next = (current + speed * dt).clamp(0.0, position.maxScrollExtent);
    if ((next - current).abs() < 0.01) {
      return;
    }
    position.jumpTo(next);
  }

  void _setScrollTarget(Offset wordGlobal) {
    if (!_autoFollow || !_scrollController.hasClients) {
      return;
    }
    final topGuard = MediaQuery.paddingOf(context).top + 92;
    final bottomGuard =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).bottom -
        148;
    final center = (topGuard + bottomGuard) / 2;
    if ((wordGlobal.dy - center).abs() < 6) {
      return;
    }
    final target = _scrollController.offset + wordGlobal.dy - center;
    final max = _scrollController.position.maxScrollExtent;
    _scrollTarget = target.clamp(0.0, max);
    _startFollowTicker();
  }

  void _scheduleCompletion() {
    if (!_isToday ||
        _completionTimer != null ||
        _completing ||
        _completion != null) {
      return;
    }
    final reading = ref.read(dailyReadProvider(widget.date)).value;
    if (reading == null || reading.completed) {
      return;
    }
    _completionTimer = Timer(const Duration(milliseconds: 1500), () {
      _completionTimer = null;
      unawaited(_finishReading());
    });
  }

  void _maybeScheduleShortContentCompletion(DailyRead reading) {
    if (!_isToday || reading.completed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (_scrollController.position.maxScrollExtent <= 0) {
        _scheduleCompletion();
      }
    });
  }

  TextStyle? _passageStyle(BuildContext context, AppPalette palette) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: 'Lora',
      fontFamilyFallback: AppTextStyles.editorialFallback,
      fontVariations: const [FontVariation('wght', 600)],
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.55,
      letterSpacing: -0.2,
      color: palette.ink,
    );
  }

  void _onPosition(DailyRead reading, Duration position) {
    final ms = position.inMilliseconds;
    final index = reading.words.indexWhere(
      (word) => ms >= word.beginMs && ms < word.endMs,
    );
    if (index == _activeWordIndex) {
      return;
    }
    setState(() => _activeWordIndex = index);
    if (index >= 0 && _autoFollow) {
      _scrollToWord(reading, index);
    }
  }

  Future<void> _toggleTranslation() async {
    if (_showTranslation) {
      setState(() {
        _showTranslation = false;
        _lastPassageLineTop = null;
        _lastBilingualLineIndex = -1;
      });
      _scrollToActiveWord();
      return;
    }
    if (_translation != null) {
      setState(() {
        _showTranslation = true;
        _lastPassageLineTop = null;
        _lastBilingualLineIndex = -1;
      });
      _scrollToActiveWord();
      return;
    }
    if (_translationLoading) {
      return;
    }
    setState(() => _translationLoading = true);
    try {
      final translation = await ref
          .read(dailyRepositoryProvider)
          .fetchTranslation(date: widget.date);
      if (!mounted) {
        return;
      }
      setState(() {
        _translation = translation;
        _lineKeys = List.generate(translation.lines.length, (_) => GlobalKey());
        _lastPassageLineTop = null;
        _lastBilingualLineIndex = -1;
        _showTranslation = true;
      });
      _scrollToActiveWord();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.daily.translationUnavailable)),
      );
    } finally {
      if (mounted) {
        setState(() => _translationLoading = false);
      }
    }
  }

  Future<void> _finishReading() async {
    if (!mounted) {
      return;
    }
    final reading = ref.read(dailyReadProvider(widget.date)).value;
    if (!_isToday ||
        reading == null ||
        reading.completed ||
        _completing ||
        _completion != null) {
      return;
    }
    _completionTimer?.cancel();
    _completionTimer = null;
    _scrollTarget = null;
    _stopFollowTicker();
    setState(() => _completing = true);
    final seconds = DateTime.now()
        .difference(_startedAt)
        .inSeconds
        .clamp(0, 3600);
    try {
      final completion = await ref
          .read(dailyRepositoryProvider)
          .complete(durationSeconds: seconds);
      if (!mounted) {
        return;
      }
      setState(() => _completion = completion);
      ref.invalidate(progressProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          unawaited(
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
            ),
          );
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.daily.completeUnavailable)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  int _wordCount(DailyRead reading) {
    if (reading.words.isNotEmpty) {
      return reading.words.length;
    }
    return reading.passage
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  void _openAsk(DailyRead reading) {
    final hasActiveWord =
        _activeWordIndex >= 0 && _activeWordIndex < reading.words.length;
    final quote = hasActiveWord ? reading.words[_activeWordIndex].text : null;
    unawaited(
      openAsk(
        context,
        type: 'reading',
        ref: reading.date.toIso8601String().split('T').first,
        quote: quote,
        suggestedQuestion: quote == null
            ? 'Ask about this reading.'
            : 'What does "$quote" mean here?',
      ),
    );
  }

  void _scrollToActiveWord() {
    final reading = ref.read(dailyReadProvider(widget.date)).value;
    if (reading == null || _activeWordIndex < 0) {
      return;
    }
    _scrollToWord(reading, _activeWordIndex);
  }

  void _scrollToWord(DailyRead reading, int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= reading.words.length) {
        return;
      }
      final translation = _showTranslation ? _translation : null;
      if (translation != null && _lineKeys.length == translation.lines.length) {
        final word = reading.words[index];
        final lineIndex = translation.lines.indexWhere(
          (line) =>
              word.startChar >= line.startChar && word.startChar < line.endChar,
        );
        if (lineIndex >= 0) {
          _scrollToBilingualWord(
            reading,
            translation.lines[lineIndex],
            _lineKeys[lineIndex],
            word,
          );
          return;
        }
      }
      _scrollToPassageWord(reading, index);
    });
  }

  RenderParagraph? _paragraph(GlobalKey key) {
    return key.currentContext?.findRenderObject() as RenderParagraph?;
  }

  void _scrollToPassageWord(DailyRead reading, int index) {
    final paragraph = _paragraph(_textKey);
    if (paragraph == null || !_scrollController.hasClients) {
      return;
    }
    final word = reading.words[index];
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: word.startChar, extentOffset: word.endChar),
    );
    if (boxes.isEmpty) {
      return;
    }
    final box = boxes.first;
    if (box.top == _lastPassageLineTop) {
      return;
    }
    _lastPassageLineTop = box.top;
    _setScrollTarget(
      paragraph.localToGlobal(Offset(0, (box.top + box.bottom) / 2)),
    );
  }

  void _scrollToBilingualWord(
    DailyRead reading,
    DailyTranslationLine line,
    GlobalKey lineKey,
    DailyWord word,
  ) {
    final lineIndex = _translation?.lines.indexOf(line) ?? -1;
    if (lineIndex >= 0 && lineIndex == _lastBilingualLineIndex) {
      return;
    }
    _lastBilingualLineIndex = lineIndex;
    final paragraph = _paragraph(lineKey);
    if (paragraph == null || !_scrollController.hasClients) {
      return;
    }
    final localStart = (word.startChar - line.startChar).clamp(
      0,
      line.text.length,
    );
    final localEnd = (word.endChar - line.startChar).clamp(
      localStart,
      line.text.length,
    );
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: localStart, extentOffset: localEnd),
    );
    if (boxes.isEmpty) {
      return;
    }
    final box = boxes.first;
    _setScrollTarget(
      paragraph.localToGlobal(Offset(0, (box.top + box.bottom) / 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.daily;
    final baseTheme = Theme.of(context);
    final readerMode =
        ref.watch(readerThemeProvider).value ?? ReaderThemeMode.system;
    final isDark = switch (readerMode) {
      ReaderThemeMode.light => false,
      ReaderThemeMode.dark => true,
      ReaderThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final palette = isDark ? AppPalette.readerDark : AppPalette.readerLight;
    final async = ref.watch(dailyReadProvider(widget.date));
    final reading = async.value;
    if (reading != null) {
      _maybeScheduleShortContentCompletion(reading);
      WidgetsBinding.instance.addPostFrameCallback((_) => _armChromeHide());
    }
    final translation = _showTranslation ? _translation : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Theme(
        data: baseTheme.copyWith(extensions: [palette]),
        child: Scaffold(
          backgroundColor: palette.canvas,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleChrome,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 48, bottom: 120),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            async.when(
                              loading: () => const _DailyLoading(),
                              error: (error, stack) => Center(
                                child: AppErrorView(
                                  title: t.title,
                                  message: error is ApiException
                                      ? error.message
                                      : context.t.common.somethingWentWrong,
                                  onRetry: () => ref.invalidate(
                                    dailyReadProvider(widget.date),
                                  ),
                                ),
                              ),
                              data: (value) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (translation == null)
                                    _DailyReadBody(
                                      reading: value,
                                      textKey: _textKey,
                                      activeWordIndex: _activeWordIndex,
                                      passageStyle: _passageStyle(
                                        context,
                                        palette,
                                      ),
                                      onShowWord: (text) => unawaited(
                                        showWordLookupSheet(context, text),
                                      ),
                                      onShowSentence: (text) => unawaited(
                                        showSentenceDetailSheet(context, text),
                                      ),
                                    )
                                  else
                                    _BilingualReadBody(
                                      reading: value,
                                      translation: translation,
                                      lineKeys: _lineKeys,
                                      activeWordIndex: _activeWordIndex,
                                      passageStyle: _passageStyle(
                                        context,
                                        palette,
                                      ),
                                      onShowWord: (text) => unawaited(
                                        showWordLookupSheet(context, text),
                                      ),
                                      onShowSentence: (text) => unawaited(
                                        showSentenceDetailSheet(context, text),
                                      ),
                                    ),
                                  _DailyCompletion(
                                    completed:
                                        _completion != null || value.completed,
                                    streak: _completion?.streak ?? value.streak,
                                    wordCount:
                                        _completion?.wordCount ??
                                        _wordCount(value),
                                    durationSeconds:
                                        _completion?.durationSeconds ??
                                        value.durationSeconds,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_chromeVisible,
                    child: AnimatedOpacity(
                      opacity: _chromeVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: ColoredBox(
                        color: palette.canvas,
                        child: _ReaderTopBar(
                          title: reading?.title ?? t.title,
                          isDark: isDark,
                          onAsk: reading == null
                              ? null
                              : () => _openAsk(reading),
                          onToggleTheme: () => unawaited(
                            ref
                                .read(readerThemeProvider.notifier)
                                .setMode(
                                  isDark
                                      ? ReaderThemeMode.light
                                      : ReaderThemeMode.dark,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (reading?.audioUrl != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 88,
                    child: IgnorePointer(
                      ignoring: !_showSpeed || !_chromeVisible,
                      child: AnimatedSlide(
                        offset: _showSpeed
                            ? Offset.zero
                            : const Offset(0, 0.18),
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: _showSpeed ? 1 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: Center(
                            child: ValueListenableBuilder<double>(
                              valueListenable: _playbackRate,
                              builder: (context, rate, child) => _SpeedRail(
                                rate: rate,
                                onChanged: (value) {
                                  _playbackRate.value = value;
                                  unawaited(
                                    _audioKey.currentState?.setPlaybackRate(
                                          value,
                                        ) ??
                                        Future<void>.value(),
                                  );
                                },
                                onCommit: () => unawaited(
                                  ref
                                      .read(readerSpeedProvider.notifier)
                                      .setRate(_playbackRate.value),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (reading != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: IgnorePointer(
                      ignoring: !_chromeVisible,
                      child: AnimatedOpacity(
                        opacity: _chromeVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: palette.primary.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (reading.audioUrl != null) ...[
                                  _ReaderControl(
                                    key: const Key('daily.back10'),
                                    tooltip: t.back10,
                                    onPressed: () => _seekAudio(-10),
                                    icon: const AppLineIcon(
                                      AppLineGlyph.replay,
                                    ),
                                  ),
                                  DailyAudioButton(
                                    key: _audioKey,
                                    url: reading.audioUrl!,
                                    playbackRate: _playbackRate,
                                    onPosition: (position) =>
                                        _onPosition(reading, position),
                                    onComplete: () =>
                                        unawaited(_finishReading()),
                                  ),
                                  _ReaderControl(
                                    key: const Key('daily.forward10'),
                                    tooltip: t.forward10,
                                    onPressed: () => _seekAudio(10),
                                    icon: const AppLineIcon(
                                      AppLineGlyph.forward,
                                    ),
                                  ),
                                  ValueListenableBuilder<double>(
                                    valueListenable: _playbackRate,
                                    builder: (context, rate, child) =>
                                        _SpeedButton(
                                          rate: rate,
                                          active: _showSpeed,
                                          onTap: () => setState(
                                            () => _showSpeed = !_showSpeed,
                                          ),
                                        ),
                                  ),
                                ],
                                _ReaderControl(
                                  key: const Key('daily.translate'),
                                  tooltip: _showTranslation
                                      ? t.hideTranslation
                                      : t.translate,
                                  onPressed: _translationLoading
                                      ? null
                                      : _toggleTranslation,
                                  active: _showTranslation,
                                  icon: _translationLoading
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const AppLineIcon(
                                          AppLineGlyph.translate,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: 2,
                  child: IgnorePointer(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _readingProgress,
                      builder: (context, value, child) => Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: value.clamp(0.0, 1.0),
                          child: ColoredBox(
                            color: palette.primary.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyLoading extends StatelessWidget {
  const _DailyLoading();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.daily;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: palette.warm,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppLineIcon(
                AppLineGlyph.book,
                size: 28,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              t.preparing,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              t.preparingBody,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s20),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: palette.primary,
                backgroundColor: palette.line,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.rate,
    required this.active,
    required this.onTap,
  });

  final double rate;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return IconButton(
      key: const Key('daily.speed.button'),
      tooltip: context.t.daily.speed,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: active
            ? palette.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        foregroundColor: palette.primary,
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
      icon: Text(
        audioRateLabel(rate),
        style: TextStyle(
          color: palette.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpeedRail extends StatelessWidget {
  const _SpeedRail({
    required this.rate,
    required this.onChanged,
    required this.onCommit,
  });

  final double rate;
  final ValueChanged<double> onChanged;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.daily;
    final fraction =
        ((rate - readerSpeedMin) / (readerSpeedMax - readerSpeedMin)).clamp(
          0.0,
          1.0,
        );

    return Tooltip(
      message: t.speed,
      child: Container(
        width: 192,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                audioRateLabel(rate),
                style: AppTextStyles.caption.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return GestureDetector(
                    key: const Key('daily.speed'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      onChanged(_rateFor(details.localPosition.dx, width));
                      onCommit();
                    },
                    onHorizontalDragUpdate: (details) {
                      onChanged(_rateFor(details.localPosition.dx, width));
                    },
                    onHorizontalDragEnd: (_) => onCommit(),
                    child: SizedBox(
                      height: 32,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: palette.line,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            width: fraction * width,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: palette.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (fraction * (width - 12)).clamp(0.0, width),
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: palette.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.canvas.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _rateFor(double dx, double width) {
    final fraction = (dx / width).clamp(0.0, 1.0);
    final raw = readerSpeedMin + fraction * (readerSpeedMax - readerSpeedMin);
    return ((raw * 20).round() / 20).clamp(readerSpeedMin, readerSpeedMax);
  }
}

class _DailyCompletion extends StatelessWidget {
  const _DailyCompletion({
    required this.completed,
    required this.streak,
    required this.wordCount,
    required this.durationSeconds,
  });

  final bool completed;
  final int streak;
  final int wordCount;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    if (!completed) {
      return const SizedBox.shrink();
    }
    final t = context.t.daily;
    final palette = context.appPalette;
    final summary = t.completeSummary
        .replaceFirst('{minutes}', '$_minutes')
        .replaceFirst('{words}', '$wordCount');
    final streakLabel = streak > 0
        ? t.streakDays.replaceFirst('{count}', '$streak')
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s4,
        AppSpacing.s20,
        AppSpacing.s24,
      ),
      child: Row(
        key: const Key('daily.completion'),
        children: [
          AppLineIcon(
            AppLineGlyph.checkCircle,
            color: palette.primary,
            size: AppSize.size18,
          ),
          const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: Text(
              streakLabel == null ? summary : '$summary · $streakLabel',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ),
        ],
      ),
    );
  }

  int get _minutes {
    final seconds = durationSeconds;
    if (seconds == null) {
      return 1;
    }
    return (seconds / 60).ceil().clamp(1, 60);
  }
}

class _ReaderControl extends StatelessWidget {
  const _ReaderControl({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.active = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 22,
      style: IconButton.styleFrom(
        backgroundColor: active
            ? palette.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        foregroundColor: active ? palette.primary : palette.muted,
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
      icon: icon,
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.title,
    required this.isDark,
    required this.onToggleTheme,
    this.onAsk,
  });

  final String title;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s8, 0, AppSpacing.s20, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('daily.back'),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            visualDensity: VisualDensity.compact,
            icon: AppLineIcon(AppLineGlyph.arrowLeft, color: palette.primary),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(color: palette.muted),
            ),
          ),
          if (onAsk != null)
            IconButton(
              key: const Key('daily.ask'),
              tooltip: context.t.ask.entryTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: onAsk,
              icon: AppLineIcon(AppLineGlyph.chat, color: palette.primary),
            ),
          IconButton(
            key: const Key('daily.theme'),
            tooltip: isDark
                ? context.t.daily.lightReading
                : context.t.daily.darkReading,
            visualDensity: VisualDensity.compact,
            onPressed: onToggleTheme,
            icon: AppLineIcon(
              isDark ? AppLineGlyph.sun : AppLineGlyph.moon,
              color: palette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle? _activeWordStyle(AppPalette palette, TextStyle? base) {
  final isDark = palette.canvas.computeLuminance() < 0.2;
  return base?.copyWith(
    color: palette.ink,
    backgroundColor: isDark ? const Color(0xFF3B3028) : const Color(0xFFF2E4D3),
  );
}

TextStyle? _wordStyle(
  AppPalette palette,
  TextStyle? base, {
  required bool active,
  required bool target,
}) {
  if (!active && !target) {
    return null;
  }
  var style = active ? _activeWordStyle(palette, base) : base;
  if (target) {
    style = style?.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: palette.accent.withValues(alpha: 0.6),
      decorationThickness: 1.4,
    );
  }
  return style;
}

class _DailyReadBody extends StatelessWidget {
  const _DailyReadBody({
    required this.reading,
    required this.textKey,
    required this.activeWordIndex,
    required this.passageStyle,
    required this.onShowWord,
    required this.onShowSentence,
  });

  final DailyRead reading;
  final GlobalKey textKey;
  final int activeWordIndex;
  final TextStyle? passageStyle;
  final ValueChanged<String> onShowWord;
  final ValueChanged<String> onShowSentence;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        0,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onLongPressStart: (details) => _handleLongPress(details),
            child: Text.rich(
              TextSpan(style: passageStyle, children: _passageSpans(palette)),
              key: textKey,
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _passageSpans(AppPalette palette) {
    final spans = <InlineSpan>[];
    final words = [...reading.words]
      ..sort((a, b) => a.startChar.compareTo(b.startChar));
    final activeWord =
        activeWordIndex >= 0 && activeWordIndex < reading.words.length
        ? reading.words[activeWordIndex]
        : null;
    var cursor = 0;
    for (final word in words) {
      if (word.startChar < cursor ||
          word.startChar >= reading.passage.length ||
          word.endChar > reading.passage.length ||
          word.startChar >= word.endChar) {
        continue;
      }
      if (word.startChar > cursor) {
        spans.add(
          TextSpan(text: reading.passage.substring(cursor, word.startChar)),
        );
      }
      final active =
          activeWord != null && word.startChar == activeWord.startChar;
      final target = reading.targetWords.any(
        (value) => value.toLowerCase() == word.text.toLowerCase(),
      );
      spans.add(
        TextSpan(
          text: reading.passage.substring(word.startChar, word.endChar),
          style: _wordStyle(
            palette,
            passageStyle,
            active: active,
            target: target,
          ),
        ),
      );
      cursor = word.endChar;
    }
    if (cursor < reading.passage.length) {
      spans.add(TextSpan(text: reading.passage.substring(cursor)));
    }
    return spans;
  }

  void _handleLongPress(LongPressStartDetails details) {
    final textBox = textKey.currentContext?.findRenderObject() as RenderBox?;
    if (textBox == null) {
      return;
    }
    final local = textBox.globalToLocal(details.globalPosition);
    final painter = TextPainter(
      text: TextSpan(text: reading.passage, style: passageStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textBox.size.width);
    final offset = painter.getPositionForOffset(local).offset;
    painter.dispose();
    final word = _wordAt(reading.passage, offset);
    if (word != null) {
      onShowWord(word);
    }
  }

  String? _wordAt(String text, int offset) {
    if (text.isEmpty) {
      return null;
    }
    var index = offset.clamp(0, text.length - 1);
    if (!_isWordChar(text[index])) {
      if (index > 0 && _isWordChar(text[index - 1])) {
        index -= 1;
      } else if (index + 1 < text.length && _isWordChar(text[index + 1])) {
        index += 1;
      } else {
        return null;
      }
    }
    var start = index;
    var end = index + 1;
    while (start > 0 && _isWordChar(text[start - 1])) {
      start -= 1;
    }
    while (end < text.length && _isWordChar(text[end])) {
      end += 1;
    }
    final word = text.substring(start, end).trim();
    return word.isEmpty ? null : word;
  }

  bool _isWordChar(String char) {
    return RegExp(r"[A-Za-z0-9']").hasMatch(char);
  }
}

class _BilingualReadBody extends StatelessWidget {
  const _BilingualReadBody({
    required this.reading,
    required this.translation,
    required this.lineKeys,
    required this.activeWordIndex,
    required this.passageStyle,
    required this.onShowWord,
    required this.onShowSentence,
  });

  final DailyRead reading;
  final DailyTranslation translation;
  final List<GlobalKey> lineKeys;
  final int activeWordIndex;
  final TextStyle? passageStyle;
  final ValueChanged<String> onShowWord;
  final ValueChanged<String> onShowSentence;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        0,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < translation.lines.length; index++) ...[
            GestureDetector(
              onLongPressStart: (details) => _handleLineLongPress(
                details,
                translation.lines[index],
                lineKeys[index],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: passageStyle,
                      children: _lineSpans(palette, translation.lines[index]),
                    ),
                    key: lineKeys[index],
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  Text(
                    translation.lines[index].translation,
                    style: textTheme.bodyMedium?.copyWith(
                      color: palette.muted,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            if (index < translation.lines.length - 1)
              const SizedBox(height: AppSpacing.s16),
          ],
        ],
      ),
    );
  }

  List<InlineSpan> _lineSpans(AppPalette palette, DailyTranslationLine line) {
    final spans = <InlineSpan>[];
    final words =
        reading.words
            .where(
              (word) =>
                  word.startChar >= line.startChar &&
                  word.endChar <= line.endChar,
            )
            .toList()
          ..sort((a, b) => a.startChar.compareTo(b.startChar));
    final activeWord =
        activeWordIndex >= 0 && activeWordIndex < reading.words.length
        ? reading.words[activeWordIndex]
        : null;
    var cursor = line.startChar;
    for (final word in words) {
      if (word.startChar < cursor ||
          word.startChar >= line.endChar ||
          word.endChar > line.endChar ||
          word.startChar >= word.endChar) {
        continue;
      }
      if (word.startChar > cursor) {
        spans.add(
          TextSpan(text: reading.passage.substring(cursor, word.startChar)),
        );
      }
      final active =
          activeWord != null && word.startChar == activeWord.startChar;
      final target = reading.targetWords.any(
        (value) => value.toLowerCase() == word.text.toLowerCase(),
      );
      spans.add(
        TextSpan(
          text: reading.passage.substring(word.startChar, word.endChar),
          style: _wordStyle(
            palette,
            passageStyle,
            active: active,
            target: target,
          ),
        ),
      );
      cursor = word.endChar;
    }
    if (cursor < line.endChar) {
      spans.add(
        TextSpan(text: reading.passage.substring(cursor, line.endChar)),
      );
    }
    return spans;
  }

  void _handleLineLongPress(
    LongPressStartDetails details,
    DailyTranslationLine line,
    GlobalKey lineKey,
  ) {
    final textBox = lineKey.currentContext?.findRenderObject() as RenderBox?;
    if (textBox == null) {
      return;
    }
    final local = textBox.globalToLocal(details.globalPosition);
    final painter = TextPainter(
      text: TextSpan(text: line.text, style: passageStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textBox.size.width);
    final offset = painter.getPositionForOffset(local).offset;
    painter.dispose();
    final word = _wordAt(reading.passage, line.startChar + offset);
    if (word != null) {
      onShowWord(word);
    }
  }

  String? _wordAt(String text, int offset) {
    if (text.isEmpty) {
      return null;
    }
    var index = offset.clamp(0, text.length - 1);
    if (!_isWordChar(text[index])) {
      if (index > 0 && _isWordChar(text[index - 1])) {
        index -= 1;
      } else if (index + 1 < text.length && _isWordChar(text[index + 1])) {
        index += 1;
      } else {
        return null;
      }
    }
    var start = index;
    var end = index + 1;
    while (start > 0 && _isWordChar(text[start - 1])) {
      start -= 1;
    }
    while (end < text.length && _isWordChar(text[end])) {
      end += 1;
    }
    final word = text.substring(start, end).trim();
    return word.isEmpty ? null : word;
  }

  bool _isWordChar(String char) {
    return RegExp(r"[A-Za-z0-9']").hasMatch(char);
  }
}

class DailyAudioButton extends ConsumerStatefulWidget {
  const DailyAudioButton({
    super.key,
    required this.url,
    required this.playbackRate,
    required this.onPosition,
    this.onComplete,
  });

  final String url;
  final ValueListenable<double> playbackRate;
  final ValueChanged<Duration> onPosition;
  final VoidCallback? onComplete;

  @override
  ConsumerState<DailyAudioButton> createState() => _DailyAudioButtonState();
}

class _DailyAudioButtonState extends ConsumerState<DailyAudioButton> {
  static const _sourceId = 'daily.reading';

  StreamSubscription<String>? _completionSub;

  @override
  void initState() {
    super.initState();
    widget.playbackRate.addListener(_applyPlaybackRate);
    _completionSub = ref
        .read(audioPlaybackControllerProvider.notifier)
        .completions
        .listen((id) {
          if (id == _sourceId) {
            widget.onComplete?.call();
          }
        });
  }

  @override
  void dispose() {
    widget.playbackRate.removeListener(_applyPlaybackRate);
    unawaited(_completionSub?.cancel());
    super.dispose();
  }

  bool get isPlaying =>
      ref.read(audioPlaybackControllerProvider).isPlayingId(_sourceId);

  void _applyPlaybackRate() {
    final state = ref.read(audioPlaybackControllerProvider);
    if (state.activeId == _sourceId) {
      unawaited(
        ref
            .read(audioPlaybackControllerProvider.notifier)
            .applyPlaybackRate(widget.playbackRate.value),
      );
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    final state = ref.read(audioPlaybackControllerProvider);
    if (state.activeId == _sourceId) {
      await ref
          .read(audioPlaybackControllerProvider.notifier)
          .applyPlaybackRate(rate);
    }
  }

  Future<void> seekBy(int seconds) async {
    await ref.read(audioPlaybackControllerProvider.notifier).seekBy(seconds);
  }

  Future<void> _toggle() async {
    try {
      await ref
          .read(audioPlaybackControllerProvider.notifier)
          .toggle(
            _sourceId,
            () async => widget.url,
            speed: widget.playbackRate.value,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.daily.audioUnavailable)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.daily;
    ref.listen(audioPlaybackControllerProvider, (previous, next) {
      if (next.activeId == _sourceId && next.position != previous?.position) {
        widget.onPosition(next.position);
      }
    });
    final state = ref.watch(audioPlaybackControllerProvider);
    final playing = state.isPlayingId(_sourceId);
    final loading = state.isLoadingId(_sourceId);

    return IconButton(
      key: const Key('daily.audio'),
      tooltip: playing ? t.pause : t.listen,
      onPressed: _toggle,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: context.appPalette.primary,
        minimumSize: const Size(38, 38),
        fixedSize: const Size(38, 38),
        padding: EdgeInsets.zero,
      ),
      icon: loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : AppLineIcon(
              playing ? AppLineGlyph.pause : AppLineGlyph.play,
              size: 24,
              color: context.appPalette.muted,
            ),
    );
  }
}
