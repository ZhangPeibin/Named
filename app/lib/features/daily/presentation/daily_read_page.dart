import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/audio/audio_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../i18n/strings.g.dart';
import '../../progress/providers/progress_providers.dart';
import '../../sentence/presentation/sentence_detail_sheet.dart';
import '../../words/presentation/word_lookup_sheet.dart';
import '../domain/daily_read.dart';
import '../domain/reader_theme.dart';
import '../providers/daily_providers.dart';
import '../providers/reader_theme_provider.dart';

class DailyReadPage extends ConsumerStatefulWidget {
  const DailyReadPage({super.key, this.date});

  final DateTime? date;

  @override
  ConsumerState<DailyReadPage> createState() => _DailyReadPageState();
}

class _DailyReadPageState extends ConsumerState<DailyReadPage> {
  final _scrollController = ScrollController();
  final _textKey = GlobalKey();
  final _audioKey = GlobalKey<_DailyAudioButtonState>();
  var _activeWordIndex = -1;
  var _lastPassageLine = -1;
  var _lastBilingualLine = -1;
  var _showTranslation = false;
  var _translationLoading = false;
  DailyTranslation? _translation;
  DailyCompletion? _completion;
  List<GlobalKey> _lineKeys = const [];
  final _startedAt = DateTime.now();
  var _completing = false;
  Timer? _completionTimer;

  bool get _isToday =>
      widget.date == null || DateUtils.isSameDay(widget.date, DateTime.now());

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
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
    if (position.maxScrollExtent <= 0) {
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 24) {
      _scheduleCompletion();
    } else {
      _completionTimer?.cancel();
      _completionTimer = null;
    }
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
      fontSize: 19,
      height: 1.75,
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
    if (index >= 0) {
      _scrollToWord(reading, index);
    }
  }

  Future<void> _toggleTranslation() async {
    if (_showTranslation) {
      setState(() {
        _showTranslation = false;
        _lastPassageLine = -1;
        _lastBilingualLine = -1;
      });
      _scrollToActiveWord();
      return;
    }
    if (_translation != null) {
      setState(() {
        _showTranslation = true;
        _lastPassageLine = -1;
        _lastBilingualLine = -1;
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
        _lastPassageLine = -1;
        _lastBilingualLine = -1;
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

  void _scrollToPassageWord(DailyRead reading, int index) {
    final textBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (textBox == null || !_scrollController.hasClients) {
      return;
    }
    final word = reading.words[index];
    final painter = TextPainter(
      text: TextSpan(
        text: reading.passage,
        style: _passageStyle(context, context.appPalette),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textBox.size.width);
    final lineStart = painter
        .getLineBoundary(TextPosition(offset: word.startChar))
        .start;
    if (lineStart == _lastPassageLine) {
      painter.dispose();
      return;
    }
    _lastPassageLine = lineStart;
    final local = painter.getOffsetForCaret(
      TextPosition(offset: word.startChar),
      Rect.zero,
    );
    painter.dispose();
    _ensureVisible(textBox.localToGlobal(local));
  }

  void _scrollToBilingualWord(
    DailyRead reading,
    DailyTranslationLine line,
    GlobalKey lineKey,
    DailyWord word,
  ) {
    final lineIndex = _translation?.lines.indexOf(line) ?? -1;
    if (lineIndex >= 0 && lineIndex == _lastBilingualLine) {
      return;
    }
    _lastBilingualLine = lineIndex;
    final textBox = lineKey.currentContext?.findRenderObject() as RenderBox?;
    if (textBox == null || !_scrollController.hasClients) {
      return;
    }
    final lineText = reading.passage.substring(line.startChar, line.endChar);
    final painter = TextPainter(
      text: TextSpan(
        text: lineText,
        style: _passageStyle(context, context.appPalette),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textBox.size.width);
    final localOffset = (word.startChar - line.startChar).clamp(
      0,
      lineText.length,
    );
    final local = painter.getOffsetForCaret(
      TextPosition(offset: localOffset),
      Rect.zero,
    );
    painter.dispose();
    _ensureVisible(textBox.localToGlobal(local));
  }

  void _ensureVisible(Offset wordGlobal) {
    final topGuard = MediaQuery.paddingOf(context).top + 92;
    final bottomGuard =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).bottom -
        148;
    if (wordGlobal.dy >= topGuard && wordGlobal.dy <= bottomGuard) {
      return;
    }
    final targetLine = topGuard + (bottomGuard - topGuard) * 0.34;
    final target = _scrollController.offset + wordGlobal.dy - targetLine;
    final max = _scrollController.position.maxScrollExtent;
    final clamped = target.clamp(0.0, max);
    final distance = (clamped - _scrollController.offset).abs();
    final duration = Duration(
      milliseconds: (220 + distance * 0.22).clamp(260, 460).round(),
    );
    unawaited(
      _scrollController.animateTo(
        clamped,
        duration: duration,
        curve: Curves.easeInOutCubic,
      ),
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
    final palette = isDark ? AppPalette.readerDark : context.appPalette;
    final async = ref.watch(dailyReadProvider(widget.date));
    final reading = async.value;
    if (reading != null) {
      _maybeScheduleShortContentCompletion(reading);
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
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 48, bottom: 120),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        async.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
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
                                  passageStyle: _passageStyle(context, palette),
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
                                  passageStyle: _passageStyle(context, palette),
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
                                    _completion?.wordCount ?? _wordCount(value),
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ColoredBox(
                    color: palette.canvas,
                    child: _ReaderTopBar(
                      title: reading?.title ?? t.title,
                      isDark: isDark,
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
                if (reading != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
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
                                onPressed: () =>
                                    _audioKey.currentState?.seekBy(-10),
                                icon: const Icon(Icons.replay_10),
                              ),
                              DailyAudioButton(
                                key: _audioKey,
                                url: reading.audioUrl!,
                                onPosition: (position) =>
                                    _onPosition(reading, position),
                                onComplete: () => unawaited(_finishReading()),
                              ),
                              _ReaderControl(
                                key: const Key('daily.forward10'),
                                tooltip: t.forward10,
                                onPressed: () =>
                                    _audioKey.currentState?.seekBy(10),
                                icon: const Icon(Icons.forward_10),
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
                                  : const Icon(Icons.translate),
                            ),
                          ],
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
          Icon(
            Icons.check_circle_outline,
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
  });

  final String title;
  final bool isDark;
  final VoidCallback onToggleTheme;

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
            icon: Icon(Icons.arrow_back, color: palette.primary),
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
          IconButton(
            key: const Key('daily.theme'),
            tooltip: isDark
                ? context.t.daily.lightReading
                : context.t.daily.darkReading,
            visualDensity: VisualDensity.compact,
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: palette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingHeader extends StatelessWidget {
  const _ReadingHeader({required this.targetWords});

  final List<String> targetWords;

  @override
  Widget build(BuildContext context) {
    if (targetWords.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.t.daily;
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.madeWith.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          t.madeWithBody,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s6,
          runSpacing: AppSpacing.s6,
          children: [for (final word in targetWords) AppTag(label: word)],
        ),
        const SizedBox(height: AppSpacing.s20),
      ],
    );
  }
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
          _ReadingHeader(targetWords: reading.targetWords),
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
      spans.add(
        TextSpan(
          text: reading.passage.substring(word.startChar, word.endChar),
          style: active
              ? passageStyle?.copyWith(
                  color: palette.primary,
                  backgroundColor: palette.accent.withValues(alpha: 0.18),
                )
              : null,
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
          _ReadingHeader(targetWords: reading.targetWords),
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
      spans.add(
        TextSpan(
          text: reading.passage.substring(word.startChar, word.endChar),
          style: active
              ? passageStyle?.copyWith(
                  color: palette.primary,
                  backgroundColor: palette.accent.withValues(alpha: 0.18),
                )
              : null,
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
    required this.onPosition,
    this.onComplete,
  });

  final String url;
  final ValueChanged<Duration> onPosition;
  final VoidCallback? onComplete;

  @override
  ConsumerState<DailyAudioButton> createState() => _DailyAudioButtonState();
}

class _DailyAudioButtonState extends ConsumerState<DailyAudioButton> {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<void> _completeSub;
  late final StreamSubscription<Duration> _positionSub;
  Uint8List? _bytes;
  var _isPlaying = false;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
      widget.onComplete?.call();
    });
    _positionSub = _player.onPositionChanged.listen(widget.onPosition);
  }

  @override
  void dispose() {
    unawaited(_stateSub.cancel());
    unawaited(_completeSub.cancel());
    unawaited(_positionSub.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> seekBy(int seconds) async {
    if (seconds == 0) {
      return;
    }
    final current = await _player.getCurrentPosition() ?? Duration.zero;
    final target = current + Duration(seconds: seconds);
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    if (_loading) {
      return;
    }
    if (_player.state == PlayerState.paused) {
      await _player.resume();
      return;
    }
    setState(() => _loading = true);
    try {
      final bytes =
          _bytes ??
          Uint8List.fromList(
            await ref.read(audioBytesApiProvider).fetch(widget.url),
          );
      _bytes = bytes;
      await _player.stop();
      await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.daily.audioUnavailable)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.daily;

    return IconButton(
      key: const Key('daily.audio'),
      tooltip: _isPlaying ? t.pause : t.listen,
      onPressed: _toggle,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: context.appPalette.primary,
        minimumSize: const Size(38, 38),
        fixedSize: const Size(38, 38),
        padding: EdgeInsets.zero,
      ),
      icon: _loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 30,
            ),
    );
  }
}
