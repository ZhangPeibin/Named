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
import '../../../core/widgets/app_composer.dart';
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

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({super.key});

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  final _recallController = TextEditingController();
  final _useController = TextEditingController();
  final _recorder = AudioRecorder();
  AudioPlayer? _player;
  String? _recordingPath;
  var _isRecording = false;
  var _isTranscribing = false;
  var _micDenied = false;
  var _node = _PracticeNode.understand;
  String? _selectedOption;
  var _showFirstLetter = false;
  var _showIpaHint = false;
  var _showAudioHint = false;
  var _showAnswer = false;
  var _completing = false;
  var _completed = false;
  var _practiceCount = 0;
  String? _completeError;
  final _useMessages = <_UseMessage>[];
  final _useHistory = <PracticeTurn>[];
  var _useTurns = 0;
  var _useSending = false;
  String? _useError;

  @override
  void dispose() {
    _recallController.dispose();
    _useController.dispose();
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
    final palette = context.appPalette;
    final total = _PracticeNode.values.length;
    final isLast = _node == _PracticeNode.use;
    final canFinish = !isLast || _useTurns >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PracticeStepper(
          index: _node.index,
          total: total,
          title: _nodeTitle(t),
        ),
        const SizedBox(height: AppSpacing.s20),
        Expanded(
          child: SingleChildScrollView(child: _nodeBody(context, word, t)),
        ),
        if (_completeError != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            _completeError!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        AppButton(
          key: const Key('practice.next'),
          label: isLast ? t.finish : t.next,
          size: AppButtonSize.lg,
          isLoading: _completing,
          onPressed: canFinish ? () => _next(word) : null,
        ),
      ],
    );
  }

  Widget _nodeBody(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    return switch (_node) {
      _PracticeNode.understand => _understandBody(context, word, t),
      _PracticeNode.pronounce => _pronounceBody(context, word, t),
      _PracticeNode.recognise => _recogniseBody(context, word, t),
      _PracticeNode.recall => _recallBody(context, word, t),
      _PracticeNode.use => _useBody(context, word, t),
    };
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wordHeader(context, word),
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
          if (sense.exampleEn.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            AppCard(
              child: Text(
                sense.exampleEn,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.s16),
        Text(
          t.understandHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
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
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            _accentAudio(context, word.audio, WordAudioAccent.us, 'US'),
            const SizedBox(width: AppSpacing.s20),
            _accentAudio(context, word.audio, WordAudioAccent.uk, 'UK'),
          ],
        ),
        const SizedBox(height: AppSpacing.s20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                key: const Key('practice.record'),
                label: _isRecording ? t.stop : t.record,
                icon: AppLineIcon(
                  _isRecording ? AppLineGlyph.stop : AppLineGlyph.mic,
                  size: 18,
                  color: palette.onPrimary,
                ),
                onPressed: _isTranscribing
                    ? null
                    : () => unawaited(_toggleRecording(transcribe: false)),
              ),
            ),
            if (_recordingPath != null && !_isRecording) ...[
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppButton(
                  key: const Key('practice.playback'),
                  label: t.playback,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => unawaited(_playRecording()),
                ),
              ),
            ],
          ],
        ),
        if (_micDenied) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            t.micDenied,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.recognisePrompt, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.s12),
        WordAudioButton(audio: word.audio, dimension: 40, iconSize: 16),
        const SizedBox(height: AppSpacing.s20),
        for (final option in options) ...[
          AppCard(
            key: Key('practice.option.$option'),
            onTap: () => setState(() => _selectedOption = option),
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
          const SizedBox(height: AppSpacing.s8),
        ],
        if (selected != null && selected != word.label) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            t.recogniseWrong.replaceFirst('{word}', word.label),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
      ],
    );
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
          Text(
            word.context!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s8),
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
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              key: const Key('practice.recallMic'),
              onPressed: _isTranscribing
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
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s6,
          children: [
            _hintButton(
              key: const Key('practice.hint.firstLetter'),
              label: t.hintFirstLetter,
              onPressed: () => setState(() => _showFirstLetter = true),
            ),
            _hintButton(
              key: const Key('practice.hint.ipa'),
              label: t.hintIpa,
              onPressed: () => setState(() => _showIpaHint = true),
            ),
            _hintButton(
              key: const Key('practice.hint.audio'),
              label: t.hintAudio,
              onPressed: () => setState(() => _showAudioHint = true),
            ),
            _hintButton(
              key: const Key('practice.hint.answer'),
              label: t.hintAnswer,
              onPressed: () => setState(() => _showAnswer = true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        if (_showFirstLetter && word.label.isNotEmpty)
          _hintValue(context, '${word.label[0]}…'),
        if (_showIpaHint && ipa.isNotEmpty) _hintValue(context, ipa),
        if (_showAudioHint && word.audio != null) ...[
          Row(
            children: [
              WordAudioButton(audio: word.audio),
              const SizedBox(width: AppSpacing.s8),
              _hintValue(context, t.hintAudio),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        if (_showAnswer) _hintValue(context, word.label),
      ],
    );
  }

  Widget _useBody(
    BuildContext context,
    PracticeWord word,
    Translations$practice$en t,
  ) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wordHeader(context, word),
        const SizedBox(height: AppSpacing.s16),
        Text(t.usePrompt, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.s12),
        for (var index = 0; index < _useMessages.length; index++)
          AppMessageBubble(
            text: _useMessages[index].text,
            side: _useMessages[index].isLearner
                ? AppMessageSide.outgoing
                : AppMessageSide.incoming,
            firstInGroup:
                index == 0 ||
                _useMessages[index - 1].isLearner !=
                    _useMessages[index].isLearner,
            secondaryLabel: t.recastLabel,
            secondaryText: _useMessages[index].recast,
          ),
        if (_useTurns < 2) ...[
          const SizedBox(height: AppSpacing.s12),
          AppComposer(
            controller: _useController,
            hintText: t.usePlaceholder,
            sendTooltip: t.send,
            onSend: () => unawaited(_sendUseTurn(word)),
            isSending: _useSending,
            maxLines: 4,
            inputKey: const Key('practice.useInput'),
            sendKey: const Key('practice.send'),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            t.useTurnsLeft.replaceFirst('{count}', '${2 - _useTurns}'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
        if (_useError != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            _useError!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ],
      ],
    );
  }

  Widget _wordHeader(
    BuildContext context,
    PracticeWord word, {
    bool showAudio = true,
  }) {
    final palette = context.appPalette;
    final ipa = _ipa(word);
    final pos = word.word?.pos ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (word.context != null && word.context!.trim().isNotEmpty) ...[
          Text(
            word.context!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s4),
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

  void _next(PracticeWord word) {
    if (_node == _PracticeNode.use) {
      unawaited(_complete(word));
      return;
    }
    if (_isRecording) {
      unawaited(_recorder.stop());
    }
    setState(() {
      _completeError = null;
      _isRecording = false;
      _node = _PracticeNode.values[_node.index + 1];
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
          const SizedBox(height: AppSpacing.s24),
          AppButton(
            key: const Key('practice.done'),
            label: t.done,
            size: AppButtonSize.lg,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _openWords() async {
    await context.pushNamed(AppRouteNames.words);
    if (mounted) {
      ref.invalidate(practiceSessionProvider);
    }
  }

  Future<void> _toggleRecording({required bool transcribe}) async {
    if (_isRecording) {
      await _stopRecording(transcribe: transcribe);
      return;
    }
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
      });
    } catch (_) {
      if (mounted) {
        setState(() => _micDenied = true);
      }
    }
  }

  Future<void> _stopRecording({required bool transcribe}) async {
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
      _recallController.text = text.trim();
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
    required this.total,
    required this.title,
  });

  final int index;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
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
                  height: 4,
                  decoration: BoxDecoration(
                    color: step <= index ? palette.primary : palette.line,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              if (step < total - 1) const SizedBox(width: AppSpacing.s4),
            ],
          ],
        ),
      ],
    );
  }
}

class _UseMessage {
  const _UseMessage({required this.text, required this.isLearner, this.recast});

  final String text;
  final bool isLearner;
  final String? recast;
}
