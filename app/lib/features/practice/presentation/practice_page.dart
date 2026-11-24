import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_message_bubble.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../i18n/strings.g.dart';
import '../../discover/domain/discover.dart';
import '../../progress/providers/progress_providers.dart';
import '../../talk/providers/talk_providers.dart';
import '../../timeline/presentation/widgets/word_audio_button.dart';
import '../domain/practice_word.dart';
import '../providers/practice_providers.dart';

enum _PracticeNode { understand, pronounce, recognise, recall, use }

enum _ForwardResult { allowed, blocked, correct }

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({super.key});

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  final _recallController = TextEditingController();
  final _useController = TextEditingController();
  final _useScrollController = ScrollController();
  var _pageController = PageController();
  final _recorder = AudioRecorder();
  AudioPlayer? _player;
  Timer? _recordingTimer;
  Timer? _blockedHintTimer;
  String? _recordingPath;
  var _isRecording = false;
  var _isTranscribing = false;
  var _transcribeUse = false;
  var _micDenied = false;
  var _recordingSeconds = 0;
  var _pageIndex = 0;
  var _maxVisited = 0;
  var _showSwipeHint = true;
  var _transitioning = false;
  String? _blockedHint;
  String? _selectedOption;
  var _hintsRevealed = 0;
  var _recallChecked = false;
  var _recallCorrect = false;
  var _completing = false;
  var _completed = false;
  var _practiceCount = 0;
  var _sessionProgressed = false;
  var _allowPop = false;
  String? _completeError;
  final _useMessages = <_UseMessage>[];
  final _useHistory = <PracticeTurn>[];
  var _useTurns = 0;
  var _useSending = false;
  String? _useError;

  _PracticeNode get _node => _PracticeNode.values[_pageIndex];

  @override
  void dispose() {
    _recallController.dispose();
    _useController.dispose();
    _useScrollController.dispose();
    _pageController.dispose();
    _recordingTimer?.cancel();
    _blockedHintTimer?.cancel();
    unawaited(_recorder.dispose());
    final player = _player;
    if (player != null) {
      unawaited(player.dispose());
    }
    _deleteRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.practice;
    final async = ref.watch(practiceSessionProvider);
    return AppScaffold(
      title: t.title,
      centerBody: false,
      body: async.when(
        loading: () => const Center(child: AppLoadingView()),
        error: (error, stack) => _errorView(error, t),
        data: (word) => _completed
            ? _completeView(context, word, t)
            : _session(context, word, t),
      ),
    );
  }

  Widget _errorView(Object error, Translations$practice$en t) {
    if (error is ApiException && error.code == 'practice_no_words') {
      return Center(
        child: AppEmptyView(
          title: t.emptyTitle,
          message: t.emptyCopy,
          icon: AppLineGlyph.book,
          action: AppButton(
            label: context.t.words.title,
            variant: AppButtonVariant.secondary,
            expand: false,
            onPressed: () => unawaited(_openWords()),
          ),
        ),
      );
    }
    return Center(
      child: AppErrorView(
        title: t.loadFailed,
        message: error is ApiException
            ? error.message
            : context.t.common.somethingWentWrong,
        onRetry: () => ref.invalidate(practiceSessionProvider),
      ),
    );
  }

  Widget _session(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final total = _PracticeNode.values.length;

    return PopScope(
      canPop: _completed || _allowPop || !_sessionProgressed,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _completed) {
          return;
        }
        unawaited(_confirmLeave());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PracticeStepper(
            index: _pageIndex,
            maxIndex: _maxVisited,
            total: total,
            title: _nodeTitle(t),
          ),
          const SizedBox(height: AppSpacing.s20),
          Expanded(
            child: Semantics(
              onIncrease: _pageIndex < total - 1 ? _semanticAdvance : null,
              onDecrease: _pageIndex > 0 ? _semanticBack : null,
              child: PageView(
                key: const Key('practice.pages'),
                controller: _pageController,
                onPageChanged: (next) =>
                    unawaited(_handlePageChanged(next, word)),
                children: [
                  _scrollPage(_understandBody(context, word, t)),
                  _scrollPage(_pronounceBody(context, word, t)),
                  _scrollPage(_recogniseBody(context, word, t)),
                  _scrollPage(_recallBody(context, word, t)),
                  _useBody(context, word, t),
                ],
              ),
            ),
          ),
          _swipeHintBar(context, t),
        ],
      ),
    );
  }

  Widget _scrollPage(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: child,
    );
  }

  Widget _swipeHintBar(BuildContext context, Translations$practice$en t) {
    if (_node == _PracticeNode.use) {
      return const SizedBox(height: AppSpacing.s8);
    }
    final blocked = _blockedHint;
    final message = blocked ?? (_showSwipeHint ? t.swipeHint : null);
    if (message == null) {
      return const SizedBox(height: AppSpacing.s8);
    }
    final palette = context.appPalette;
    final color = blocked != null ? palette.accent : palette.muted;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLineIcon(AppLineGlyph.chevronLeft, size: 14, color: color),
          const SizedBox(width: AppSpacing.s4),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          AppLineIcon(AppLineGlyph.chevronRight, size: 14, color: color),
        ],
      ),
    );
  }

  Future<void> _handlePageChanged(int next, PracticeWord word) async {
    if (_transitioning) {
      return;
    }
    if (next == _pageIndex) {
      return;
    }
    if (next < _pageIndex) {
      setState(() {
        _pageIndex = next;
        _showSwipeHint = false;
        _blockedHint = null;
        _blockedHintTimer?.cancel();
      });
      return;
    }
    if (next > _pageIndex + 1) {
      _showBlockedHint(context.t.practice.swipeBlockedHint);
      await _snapBack();
      return;
    }
    final result = _evaluateForward(word);
    if (result == _ForwardResult.blocked) {
      await _snapBack();
      return;
    }
    if (result == _ForwardResult.correct) {
      await _snapBack();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) {
        return;
      }
      await _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() {
      _pageIndex = next;
      _maxVisited = next > _maxVisited ? next : _maxVisited;
      _showSwipeHint = false;
      _sessionProgressed = true;
      _blockedHint = null;
      _blockedHintTimer?.cancel();
    });
  }

  _ForwardResult _evaluateForward(PracticeWord word) {
    switch (_node) {
      case _PracticeNode.understand:
      case _PracticeNode.pronounce:
        return _ForwardResult.allowed;
      case _PracticeNode.recognise:
        if (_selectedOption == null) {
          _showBlockedHint(context.t.practice.swipeBlockedHint);
          return _ForwardResult.blocked;
        }
        return _ForwardResult.allowed;
      case _PracticeNode.recall:
        if (_recallChecked) {
          return _ForwardResult.allowed;
        }
        final input = _recallController.text.trim();
        if (input.isEmpty) {
          if (_hintsRevealed >= 4) {
            return _ForwardResult.allowed;
          }
          _showBlockedHint(context.t.practice.swipeBlockedHint);
          return _ForwardResult.blocked;
        }
        final correct = _normalizeAnswer(input) == _normalizeAnswer(word.label);
        _blockedHintTimer?.cancel();
        setState(() {
          _recallChecked = true;
          _recallCorrect = correct;
          _blockedHint = null;
          if (!correct) {
            _hintsRevealed = 4;
          }
        });
        return correct ? _ForwardResult.correct : _ForwardResult.blocked;
      case _PracticeNode.use:
        return _ForwardResult.blocked;
    }
  }

  void _showBlockedHint(String message) {
    _blockedHintTimer?.cancel();
    setState(() => _blockedHint = message);
    _blockedHintTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() => _blockedHint = null);
    });
  }

  Future<void> _snapBack() async {
    _transitioning = true;
    await _pageController.animateToPage(
      _pageIndex,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    _transitioning = false;
  }

  void _semanticAdvance() {
    if (_pageIndex >= _PracticeNode.values.length - 1) {
      return;
    }
    unawaited(
      _pageController.animateToPage(
        _pageIndex + 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  void _semanticBack() {
    if (_pageIndex == 0) {
      return;
    }
    unawaited(
      _pageController.animateToPage(
        _pageIndex - 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _confirmLeave() async {
    if (!_sessionProgressed) {
      setState(() => _allowPop = true);
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    final t = context.t.practice;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.leaveTitle),
        content: Text(t.leaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.leaveCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.leaveConfirm),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) {
      return;
    }
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }

  String _nodeTitle(Translations$practice$en t) {
    return switch (_node) {
      _PracticeNode.understand => t.understandTitle,
      _PracticeNode.pronounce => t.pronounceTitle,
      _PracticeNode.recognise => t.recogniseTitle,
      _PracticeNode.recall => t.recallTitle,
      _PracticeNode.use => t.useTitle,
    };
  }

  Widget _understandBody(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final palette = context.appPalette;
    final sense = word.word?.primarySense;
    final sentences = _exampleSentences(word);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wordHeader(context, word, showContext: false),
        if (word.context != null && word.context!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            word.context!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
        if (sense != null) ...[
          const SizedBox(height: AppSpacing.s16),
          Text(
            sense.definitionEn.isNotEmpty
                ? sense.definitionEn
                : sense.definitionZh,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (sense.definitionZh.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              sense.definitionZh,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
          ],
        ],
        if (sentences.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s20),
          for (final sentence in sentences) ...[
            _sentenceLine(context, sentence, word.label),
            const SizedBox(height: AppSpacing.s10),
          ],
        ],
        const SizedBox(height: AppSpacing.s8),
        Text(
          t.understandHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
    );
  }

  List<String> _exampleSentences(PracticeWord word) {
    final values = <String>[
      for (final sense in word.word?.senses ?? const <WordSense>[])
        sense.exampleEn,
      for (final chunk in word.word?.chunks ?? const <WordChunk>[])
        chunk.exampleEn,
      for (final note in word.word?.varietyNotes ?? const <VarietyNote>[])
        if (note.exampleEn != null) note.exampleEn!,
    ];
    final seen = <String>{};
    final sentences = <String>[];
    for (final value in values) {
      final sentence = value.trim();
      if (sentence.isEmpty) {
        continue;
      }
      final key = sentence.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }
      sentences.add(sentence);
      if (sentences.length == 3) {
        break;
      }
    }
    return sentences;
  }

  Widget _sentenceLine(BuildContext context, String sentence, String label) {
    final style = Theme.of(context).textTheme.bodyLarge;
    final lower = sentence.toLowerCase();
    final target = label.toLowerCase();
    final start = target.isEmpty ? -1 : lower.indexOf(target);
    if (start < 0) {
      return Text(sentence, style: style);
    }
    final palette = context.appPalette;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: sentence.substring(0, start)),
          TextSpan(
            text: sentence.substring(start, start + label.length),
            style: style?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: sentence.substring(start + label.length)),
        ],
      ),
    );
  }

  Widget _pronounceBody(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wordHeader(context, word, showAudio: false),
        const SizedBox(height: AppSpacing.s16),
        Text(
          t.pronounceHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _accentAudio(context, word.audio, WordAudioAccent.us, 'US'),
            const SizedBox(width: AppSpacing.s32),
            _accentAudio(context, word.audio, WordAudioAccent.uk, 'UK'),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _recordControl(context, t),
              if (_isRecording) ...[
                const SizedBox(height: AppSpacing.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: palette.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      t.recordingSeconds.replaceFirst(
                        '{seconds}',
                        '$_recordingSeconds',
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.error),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      t.recordingLimit,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ],
              if (_recordingPath != null && !_isRecording) ...[
                const SizedBox(height: AppSpacing.s12),
                AppButton(
                  key: const Key('practice.playback'),
                  label: t.playback,
                  icon: AppLineIcon(
                    AppLineGlyph.play,
                    size: 16,
                    color: palette.primary,
                  ),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  expand: false,
                  onPressed: () => unawaited(_playRecording()),
                ),
              ],
            ],
          ),
        ),
        if (_micDenied) ...[
          const SizedBox(height: AppSpacing.s12),
          Center(
            child: Text(
              t.micDenied,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ),
        ],
      ],
    );
  }

  Widget _recogniseBody(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final palette = context.appPalette;
    final options = _recogniseOptions(word);
    final selected = _selectedOption;
    final sentence = _recogniseSentence(word);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sentence ?? t.recognisePrompt,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (sentence != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            t.recogniseSentencePrompt,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        WordAudioButton(audio: word.audio, dimension: 40, iconSize: 16),
        const SizedBox(height: AppSpacing.s20),
        for (final option in options) ...[
          Semantics(
            button: true,
            selected: selected == option,
            label: option,
            child: AppCard(
              key: Key('practice.option.$option'),
              padding: const EdgeInsets.all(AppSpacing.s16),
              onTap: selected == null
                  ? () => setState(() {
                      _selectedOption = option;
                      _blockedHint = null;
                      _blockedHintTimer?.cancel();
                    })
                  : null,
              borderColor: selected == null
                  ? null
                  : option == word.label
                  ? palette.accent
                  : option == selected
                  ? palette.error
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (selected != null && option == word.label)
                    AppLineIcon(
                      AppLineGlyph.check,
                      size: 20,
                      color: palette.accent,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            selected == word.label
                ? t.recogniseCorrect
                : t.recogniseWrong.replaceFirst('{word}', word.label),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected == word.label ? palette.accent : palette.error,
            ),
          ),
        ],
      ],
    );
  }

  String? _recogniseSentence(PracticeWord word) {
    final target = word.label.toLowerCase();
    if (target.isEmpty) {
      return null;
    }
    for (final sentence in _exampleSentences(word)) {
      final index = sentence.toLowerCase().indexOf(target);
      if (index < 0) {
        continue;
      }
      return '${sentence.substring(0, index)}____'
          '${sentence.substring(index + word.label.length)}';
    }
    return null;
  }

  List<String> _recogniseOptions(PracticeWord word) {
    final options = List<String>.of(word.options);
    final index =
        word.label.codeUnits.fold<int>(0, (sum, code) => sum + code) %
        (options.length + 1);
    options.insert(index, word.label);
    return options;
  }

  Widget _recallBody(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final palette = context.appPalette;
    final sense = word.word?.primarySense;
    final ipa = _ipa(word);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (word.context != null && word.context!.trim().isNotEmpty) ...[
          _contextCallout(context, word.context!),
          const SizedBox(height: AppSpacing.s16),
        ],
        if (sense != null)
          Text(
            sense.definitionEn.isNotEmpty
                ? sense.definitionEn
                : sense.definitionZh,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        const SizedBox(height: AppSpacing.s12),
        AppField(
          label: t.recallPrompt,
          child: AppTextField(
            key: const Key('practice.recallInput'),
            controller: _recallController,
            autofocus: true,
            enabled: !_recallChecked,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _semanticAdvance(),
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              key: const Key('practice.recallMic'),
              onPressed: _isTranscribing || _recallChecked
                  ? null
                  : () => unawaited(_toggleRecording(transcribe: true)),
              icon: AppLineIcon(
                _isRecording ? AppLineGlyph.stop : AppLineGlyph.mic,
                size: 20,
              ),
            ),
          ),
        ),
        if (_isTranscribing) ...[
          const SizedBox(height: AppSpacing.s8),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (_micDenied) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            t.micDenied,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        Text(
          t.recallHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s8),
        ..._recallHints(context, word, t, ipa),
        if (_recallChecked) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            _recallCorrect
                ? t.recallCorrect
                : t.recallWrong.replaceFirst('{word}', word.label),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _recallCorrect ? palette.accent : palette.error,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _recallHints(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
    String ipa,
  ) {
    final children = <Widget>[];
    if (_hintsRevealed >= 1 && word.label.isNotEmpty) {
      children.add(_hintValue(context, '${word.label[0]}…'));
    }
    if (_hintsRevealed >= 2 && ipa.isNotEmpty) {
      children.add(_hintValue(context, ipa));
    }
    if (_hintsRevealed >= 3 && word.audio != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s6),
          child: Row(
            children: [
              WordAudioButton(audio: word.audio),
              const SizedBox(width: AppSpacing.s8),
              Text(t.hintAudio, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      );
    }
    if (_hintsRevealed >= 4) {
      children.add(_hintValue(context, word.label));
    }
    if (_hintsRevealed < 4) {
      final labels = [t.needHint, t.hintIpa, t.hintAudio, t.hintAnswer];
      final keys = [
        'practice.hint.firstLetter',
        'practice.hint.ipa',
        'practice.hint.audio',
        'practice.hint.answer',
      ];
      children.add(
        _hintButton(
          key: Key(keys[_hintsRevealed]),
          label: labels[_hintsRevealed],
          onPressed: () => setState(() => _hintsRevealed += 1),
        ),
      );
    }
    return children;
  }

  Widget _useBody(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final palette = context.appPalette;
    final canFinish = _useTurns >= 2 && !_completing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(word.label, style: Theme.of(context).textTheme.headlineSmall),
        if (word.context != null && word.context!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          _contextCallout(context, word.context!),
        ],
        const SizedBox(height: AppSpacing.s12),
        Expanded(
          child: ListView(
            controller: _useScrollController,
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            children: [
              AppMessageBubble(
                text: t.useOpening.replaceFirst('{word}', word.label),
                side: AppMessageSide.incoming,
                firstInGroup: true,
              ),
              const SizedBox(height: AppSpacing.s8),
              for (var index = 0; index < _useMessages.length; index++) ...[
                AppMessageBubble(
                  text: _useMessages[index].text,
                  side: _useMessages[index].isLearner
                      ? AppMessageSide.outgoing
                      : AppMessageSide.incoming,
                  firstInGroup:
                      index == 0 ||
                      _useMessages[index - 1].isLearner !=
                          _useMessages[index].isLearner,
                ),
                if (_useMessages[index].recast != null) ...[
                  const SizedBox(height: AppSpacing.s6),
                  _recastCard(context, _useMessages[index].recast!),
                ],
                const SizedBox(height: AppSpacing.s10),
              ],
            ],
          ),
        ),
        Text(
          _useTurns < 2
              ? t.useTurnsLeft.replaceFirst('{count}', '${2 - _useTurns}')
              : t.useTurnsDone,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
        if (_useError != null) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            _useError!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ],
        if (_completeError != null) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            _completeError!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        _PracticeComposer(
          controller: _useController,
          hintText: _useTurns < 2 ? t.usePlaceholder : t.useDonePlaceholder,
          isSending: _useSending,
          isRecording: _isRecording,
          isTranscribing: _isTranscribing,
          enabled: _useTurns < 2 && !_completing,
          canFinish: canFinish,
          isCompleting: _completing,
          sendTooltip: t.send,
          finishTooltip: t.finish,
          recordTooltip: _isRecording ? t.stop : t.record,
          onSend: () => unawaited(_sendUseTurn(word)),
          onToggleRecording: () =>
              unawaited(_toggleRecording(transcribe: true, forUse: true)),
          onFinish: () => unawaited(_complete(word)),
        ),
      ],
    );
  }

  Widget _recastCard(BuildContext context, String text) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s24,
        right: AppSpacing.s8,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: palette.warm,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.practice.recastLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _contextCallout(BuildContext context, String text) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: palette.warm,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.practice.contextLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _wordHeader(
    BuildContext context,
    PracticeWord word, {
    bool showAudio = true,
    bool showContext = true,
  }) {
    final palette = context.appPalette;
    final ipa = _ipa(word);
    final pos = word.word?.pos ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showContext &&
            word.context != null &&
            word.context!.trim().isNotEmpty) ...[
          _contextCallout(context, word.context!),
          const SizedBox(height: AppSpacing.s12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                word.label,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            if (showAudio && word.audio != null)
              WordAudioButton(audio: word.audio),
          ],
        ),
        if (ipa.isNotEmpty || pos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            [if (ipa.isNotEmpty) ipa, ...pos].join(' · '),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
      ],
    );
  }

  Widget _recordControl(BuildContext context, Translations$practice$en t) {
    final palette = context.appPalette;
    final active = _isRecording;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: active ? t.stop : t.record,
          child: Material(
            color: active ? palette.error : palette.primary,
            shape: const CircleBorder(),
            child: InkWell(
              key: const Key('practice.record'),
              customBorder: const CircleBorder(),
              onTap: _isTranscribing
                  ? null
                  : () => unawaited(_toggleRecording(transcribe: false)),
              child: SizedBox.square(
                dimension: 72,
                child: Center(
                  child: AppLineIcon(
                    active ? AppLineGlyph.stop : AppLineGlyph.mic,
                    size: 28,
                    color: palette.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          active ? t.stop : t.record,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }

  Widget _accentAudio(
    BuildContext context,
    WordAudio? audio,
    WordAudioAccent accent,
    String label,
  ) {
    final palette = context.appPalette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WordAudioButton(
          audio: audio,
          accent: accent,
          dimension: 36,
          iconSize: 14,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
    );
  }

  Widget _hintButton({
    required Key key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return AppButton(
      key: key,
      label: label,
      variant: AppButtonVariant.secondary,
      size: AppButtonSize.sm,
      expand: false,
      onPressed: onPressed,
    );
  }

  Widget _hintValue(BuildContext context, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s6),
      child: Text(value, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  String _ipa(PracticeWord word) {
    final values = word.word?.ipa.values ?? const <String>[];
    return values.where((value) => value.isNotEmpty).toSet().join(' · ');
  }

  Future<void> _sendUseTurn(PracticeWord word) async {
    final text = _useController.text.trim();
    if (text.isEmpty || _useSending || _useTurns >= 2) {
      return;
    }
    setState(() {
      _useSending = true;
      _useError = null;
    });
    try {
      final reply = await ref
          .read(practiceRepositoryProvider)
          .reply(wordId: word.id, text: text, history: List.of(_useHistory));
      if (!mounted) {
        return;
      }
      setState(() {
        _sessionProgressed = true;
        _useMessages.add(_UseMessage(text: text, isLearner: true));
        _useHistory.add(PracticeTurn(role: 'learner', text: text));
        _useMessages.add(
          _UseMessage(
            text: reply.reply,
            isLearner: false,
            recast: reply.recast,
          ),
        );
        _useHistory.add(PracticeTurn(role: 'assistant', text: reply.reply));
        _useTurns += 1;
        _useController.clear();
        _useSending = false;
      });
      _scrollUseToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _useSending = false;
        _useError = context.t.practice.useError;
      });
    }
  }

  String _normalizeAnswer(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _scrollUseToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_useScrollController.hasClients) {
        return;
      }
      unawaited(
        _useScrollController.animateTo(
          _useScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  Future<void> _complete(PracticeWord word) async {
    if (_completing || _completed) {
      return;
    }
    setState(() {
      _completing = true;
      _completeError = null;
    });
    try {
      final count = await ref
          .read(practiceRepositoryProvider)
          .complete(word.id);
      if (!mounted) {
        return;
      }
      ref.invalidate(progressProvider);
      setState(() {
        _completing = false;
        _completed = true;
        _practiceCount = count;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _completing = false;
        _completeError = context.t.common.somethingWentWrong;
      });
    }
  }

  Widget _completeView(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final palette = context.appPalette;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLineIcon(
              AppLineGlyph.checkCircle,
              size: 56,
              color: palette.accent,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              t.completeTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(word.label, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: AppSpacing.s8),
            Text(
              t.completeCount.replaceFirst('{count}', '$_practiceCount'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.s16,
              runSpacing: AppSpacing.s6,
              children: [
                Text(
                  t.hintsUsed.replaceFirst('{count}', '$_hintsRevealed'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
                Text(
                  t.repliesCount.replaceFirst('{count}', '$_useTurns'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              key: const Key('practice.another'),
              label: t.practiceAnother,
              size: AppButtonSize.lg,
              onPressed: _practiceAnother,
            ),
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              key: const Key('practice.done'),
              label: t.done,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.lg,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _practiceAnother() {
    setState(_resetSession);
    ref.invalidate(practiceSessionProvider);
  }

  void _resetSession() {
    _recallController.clear();
    _useController.clear();
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingSeconds = 0;
    _isRecording = false;
    _isTranscribing = false;
    _transcribeUse = false;
    _micDenied = false;
    _deleteRecording();
    _recordingPath = null;
    _pageController.dispose();
    _pageController = PageController();
    _pageIndex = 0;
    _maxVisited = 0;
    _showSwipeHint = true;
    _transitioning = false;
    _blockedHint = null;
    _blockedHintTimer?.cancel();
    _selectedOption = null;
    _hintsRevealed = 0;
    _recallChecked = false;
    _recallCorrect = false;
    _completing = false;
    _completed = false;
    _practiceCount = 0;
    _sessionProgressed = false;
    _allowPop = false;
    _completeError = null;
    _useMessages.clear();
    _useHistory.clear();
    _useTurns = 0;
    _useSending = false;
    _useError = null;
    if (_useScrollController.hasClients) {
      _useScrollController.jumpTo(0);
    }
  }

  Future<void> _openWords() async {
    await context.pushNamed(AppRouteNames.words);
    if (mounted) {
      ref.invalidate(practiceSessionProvider);
    }
  }

  Future<void> _toggleRecording({
    required bool transcribe,
    bool forUse = false,
  }) async {
    if (_isRecording) {
      await _stopRecording(transcribe: transcribe);
      return;
    }
    _transcribeUse = forUse;
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        setState(() => _micDenied = true);
      }
      return;
    }
    final path =
        '${Directory.systemTemp.path}/named-practice-${DateTime.now().microsecondsSinceEpoch}.wav';
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: path,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _micDenied = false;
        _recordingSeconds = 0;
      });
      _startRecordingTimer();
    } catch (_) {
      if (mounted) {
        setState(() => _micDenied = true);
      }
    }
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _recordingSeconds += 1);
      if (_recordingSeconds >= 10) {
        timer.cancel();
        unawaited(_stopRecording(transcribe: false));
      }
    });
  }

  Future<void> _stopRecording({required bool transcribe}) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // ignore
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isRecording = false;
      _isTranscribing = transcribe;
    });
    final path = _recordingPath;
    if (!transcribe || path == null) {
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
      return;
    }
    try {
      final bytes = await File(path).readAsBytes();
      final text = await ref
          .read(talkRepositoryProvider)
          .transcribeAudio(bytes);
      if (!mounted) {
        return;
      }
      if (_transcribeUse) {
        _useController.text = text.trim();
      } else {
        _recallController.text = text.trim();
      }
      setState(() => _isTranscribing = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
    }
  }

  Future<void> _playRecording() async {
    final path = _recordingPath;
    if (path == null) {
      return;
    }
    final player = _player ??= AudioPlayer();
    try {
      await player.stop();
      await player.play(DeviceFileSource(path));
    } catch (_) {
      // ignore
    }
  }

  void _deleteRecording() {
    final path = _recordingPath;
    if (path == null) {
      return;
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // ignore
    }
  }
}

class _PracticeStepper extends StatelessWidget {
  const _PracticeStepper({
    required this.index,
    required this.maxIndex,
    required this.total,
    required this.title,
  });

  final int index;
  final int maxIndex;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '${index + 1} / $total, $title',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1} / $total',
                style: textTheme.labelLarge?.copyWith(color: palette.muted),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(child: Text(title, style: textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Row(
            children: [
              for (var step = 0; step < total; step++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: step == index ? 6 : 4,
                    decoration: BoxDecoration(
                      color: step <= maxIndex || step == index
                          ? palette.primary
                          : palette.line,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                if (step < total - 1) const SizedBox(width: AppSpacing.s4),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeComposer extends StatelessWidget {
  const _PracticeComposer({
    required this.controller,
    required this.hintText,
    required this.isSending,
    required this.isRecording,
    required this.isTranscribing,
    required this.enabled,
    required this.canFinish,
    required this.isCompleting,
    required this.sendTooltip,
    required this.finishTooltip,
    required this.recordTooltip,
    required this.onSend,
    required this.onToggleRecording,
    required this.onFinish,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isSending;
  final bool isRecording;
  final bool isTranscribing;
  final bool enabled;
  final bool canFinish;
  final bool isCompleting;
  final String sendTooltip;
  final String finishTooltip;
  final String recordTooltip;
  final VoidCallback onSend;
  final VoidCallback onToggleRecording;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final inputEnabled = enabled && !isSending && !isCompleting;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: TextField(
              key: const Key('practice.useInput'),
              controller: controller,
              enabled: inputEnabled,
              onSubmitted: (_) {
                if (inputEnabled) {
                  onSend();
                }
              },
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
              style: textTheme.bodyLarge,
              cursorColor: palette.primary,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: textTheme.bodyMedium?.copyWith(color: palette.muted),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          SizedBox.square(
            dimension: 38,
            child: IconButton.filledTonal(
              key: const Key('practice.useVoice'),
              onPressed: inputEnabled ? onToggleRecording : null,
              tooltip: recordTooltip,
              style: IconButton.styleFrom(
                backgroundColor: isRecording
                    ? palette.accent
                    : palette.surfaceMuted,
                foregroundColor: isRecording
                    ? palette.onPrimary
                    : palette.primary,
                minimumSize: const Size.square(38),
                maximumSize: const Size.square(38),
                padding: EdgeInsets.zero,
              ),
              icon: isTranscribing
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.primary,
                      ),
                    )
                  : AppLineIcon(
                      isRecording ? AppLineGlyph.stop : AppLineGlyph.mic,
                      size: 20,
                      color: isRecording ? palette.onPrimary : palette.primary,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final canSend =
                  inputEnabled &&
                  value.text.trim().isNotEmpty &&
                  !isTranscribing;
              return SizedBox.square(
                dimension: 38,
                child: IconButton.filled(
                  key: const Key('practice.send'),
                  onPressed: canSend ? onSend : null,
                  tooltip: sendTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    disabledBackgroundColor: palette.surfaceMuted,
                    disabledForegroundColor: palette.muted,
                    minimumSize: const Size.square(38),
                    maximumSize: const Size.square(38),
                    padding: EdgeInsets.zero,
                  ),
                  icon: isSending
                      ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.onPrimary,
                          ),
                        )
                      : AppLineIcon(
                          AppLineGlyph.arrowUp,
                          size: 18,
                          color: canSend ? palette.onPrimary : palette.muted,
                        ),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.s4),
          SizedBox.square(
            dimension: 38,
            child: IconButton.filledTonal(
              key: const Key('practice.finish'),
              onPressed: canFinish ? onFinish : null,
              tooltip: finishTooltip,
              style: IconButton.styleFrom(
                backgroundColor: canFinish
                    ? palette.primary
                    : palette.surfaceMuted,
                foregroundColor: canFinish ? palette.onPrimary : palette.muted,
                disabledBackgroundColor: palette.surfaceMuted,
                disabledForegroundColor: palette.muted,
                minimumSize: const Size.square(38),
                maximumSize: const Size.square(38),
                padding: EdgeInsets.zero,
              ),
              icon: isCompleting
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.onPrimary,
                      ),
                    )
                  : AppLineIcon(
                      AppLineGlyph.check,
                      size: 20,
                      color: canFinish ? palette.onPrimary : palette.muted,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.s6),
        ],
      ),
    );
  }
}

class _UseMessage {
  const _UseMessage({required this.text, required this.isLearner, this.recast});

  final String text;
  final bool isLearner;
  final String? recast;
}
