import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../core/widgets/audio_control.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';
import '../../../timeline/domain/timeline_item.dart';
import '../../../timeline/providers/timeline_providers.dart';
import '../../../words/domain/word_shelf.dart';
import '../../../words/providers/words_providers.dart';
import '../../domain/challenge.dart';
import '../../providers/challenge_providers.dart';

Future<void> showChallengePracticeSheet(
  BuildContext context, {
  required Challenge challenge,
  required List<ChallengeItem> items,
}) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (context) =>
        ChallengePracticeSheet(challenge: challenge, items: items),
  );
}

class ChallengePracticeSheet extends ConsumerStatefulWidget {
  const ChallengePracticeSheet({
    super.key,
    required this.challenge,
    required this.items,
  });

  final Challenge challenge;
  final List<ChallengeItem> items;

  @override
  ConsumerState<ChallengePracticeSheet> createState() =>
      _ChallengePracticeSheetState();
}

enum _Step { listen, speak, exercise }

class _PracticeItem {
  _PracticeItem({
    required this.challengeItem,
    required this.isWord,
    required this.title,
    this.meaningZh,
    this.audioUrl,
    this.dictationAnswer,
    this.fillSentence,
    this.mcqQuestion,
    this.mcqOptions,
    this.mcqCorrectIndex,
  });

  final ChallengeItem challengeItem;
  final bool isWord;
  final String title;
  final String? meaningZh;
  final String? audioUrl;
  final String? dictationAnswer;
  final String? fillSentence;
  final String? mcqQuestion;
  final List<String>? mcqOptions;
  final int? mcqCorrectIndex;

  bool get hasMcq =>
      mcqOptions != null && mcqOptions!.length >= 2 && mcqCorrectIndex != null;
}

class _ChallengePracticeSheetState
    extends ConsumerState<ChallengePracticeSheet> {
  final _answerController = TextEditingController();
  final _recorder = AudioRecorder();
  AudioPlayer? _reviewPlayer;
  String? _recordingPath;
  var _isRecording = false;
  var _micDenied = false;

  List<_PracticeItem>? _items;
  var _index = 0;
  var _step = _Step.listen;
  var _checked = false;
  var _correct = false;

  @override
  void dispose() {
    _answerController.dispose();
    unawaited(_recorder.dispose());
    final player = _reviewPlayer;
    if (player != null) {
      unawaited(player.dispose());
    }
    _deleteRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _items ??= _resolve();
    final items = _items!;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final palette = context.appPalette;
    final item = items[_index];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s4,
          AppSpacing.s20,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.challenge.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${_index + 1} / ${items.length}',
                  style: AppTextStyles.caption.copyWith(color: palette.muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            _StepBar(step: _step),
            const SizedBox(height: AppSpacing.s16),
            Flexible(child: SingleChildScrollView(child: _body(item))),
            const SizedBox(height: AppSpacing.s16),
            _actions(item),
          ],
        ),
      ),
    );
  }

  Widget _body(_PracticeItem item) {
    switch (_step) {
      case _Step.listen:
        return _listenBody(item);
      case _Step.speak:
        return _speakBody(item);
      case _Step.exercise:
        return _exerciseBody(item);
    }
  }

  Widget _listenBody(_PracticeItem item) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          t.practiceListenHint,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
        if (item.audioUrl != null) ...[
          const SizedBox(height: AppSpacing.s16),
          AudioControl(
            sourceId: 'practice.${item.challengeItem.id}',
            resolveUrl: () async => item.audioUrl,
            playTooltip: context.t.timeline.play,
            pauseTooltip: context.t.timeline.pause,
            speedTooltip: context.t.timeline.speed,
            errorText: context.t.timeline.audioUnavailable,
          ),
        ],
      ],
    );
  }

  Widget _speakBody(_PracticeItem item) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          t.practiceSpeakHint,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s16),
        Row(
          children: [
            AppButton(
              key: const Key('practice.record'),
              label: _isRecording ? t.practiceStop : t.practiceRecord,
              icon: AppLineIcon(
                _isRecording ? AppLineGlyph.stop : AppLineGlyph.mic,
                size: 18,
                color: palette.onPrimary,
              ),
              onPressed: _toggleRecording,
            ),
          ],
        ),
        if (_micDenied) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            t.practiceMicDenied,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
        if (_recordingPath != null && !_isRecording) ...[
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            key: const Key('practice.playback'),
            label: t.practicePlayback,
            variant: AppButtonVariant.secondary,
            onPressed: _playRecording,
          ),
        ],
      ],
    );
  }

  Widget _exerciseBody(_PracticeItem item) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final useMcq = _useMcq(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (useMcq) ...[
          Text(
            item.mcqQuestion ?? item.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.s12),
          for (var i = 0; i < item.mcqOptions!.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: _OptionButton(
                label: item.mcqOptions![i],
                selected: _checked && _selectedOption == i,
                correct: _checked && item.mcqCorrectIndex == i,
                onTap: _checked ? null : () => _chooseOption(i),
              ),
            ),
        ] else ...[
          Text(
            item.fillSentence ?? item.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (item.meaningZh != null && item.fillSentence == null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              item.meaningZh!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          TextField(
            key: const Key('practice.answer'),
            controller: _answerController,
            enabled: !_checked,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: t.practicePlaceholder),
            onSubmitted: (_) => _checkText(item),
          ),
        ],
        if (_checked) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            _correct ? t.practiceCorrect : t.practiceIncorrect,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _correct ? palette.accent : palette.error,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            t.practiceAnswer.replaceFirst('{answer}', _answerText(item)),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
      ],
    );
  }

  Widget _actions(_PracticeItem item) {
    final t = context.t.challenge;
    switch (_step) {
      case _Step.listen:
        return AppButton(
          key: const Key('practice.next'),
          label: t.practiceNext,
          onPressed: () => setState(() => _step = _Step.speak),
        );
      case _Step.speak:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: t.practiceSkip,
                variant: AppButtonVariant.secondary,
                onPressed: () => setState(() => _step = _Step.exercise),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: AppButton(
                key: const Key('practice.next'),
                label: t.practiceNext,
                onPressed: () => setState(() => _step = _Step.exercise),
              ),
            ),
          ],
        );
      case _Step.exercise:
        final finished = _index == (_items!.length - 1);
        if (!_checked) {
          return AppButton(
            key: const Key('practice.check'),
            label: t.practiceCheck,
            onPressed: () => _check(item),
          );
        }
        return AppButton(
          key: const Key('practice.continue'),
          label: finished ? t.practiceDone : t.practiceNext,
          onPressed: () => _advance(item, finished),
        );
    }
  }

  // --- exercise state ---
  var _selectedOption = -1;

  bool _useMcq(_PracticeItem item) => item.hasMcq;

  void _chooseOption(int index) {
    setState(() {
      _selectedOption = index;
      _checked = true;
      _correct = _items![_index].mcqCorrectIndex == index;
    });
  }

  void _check(_PracticeItem item) {
    if (_useMcq(item)) {
      return;
    }
    _checkText(item);
  }

  void _checkText(_PracticeItem item) {
    final answer = item.dictationAnswer ?? '';
    setState(() {
      _checked = true;
      _correct = _normalize(_answerController.text) == _normalize(answer);
    });
  }

  String _answerText(_PracticeItem item) {
    if (_useMcq(item)) {
      final index = item.mcqCorrectIndex ?? 0;
      return (item.mcqOptions != null && index < item.mcqOptions!.length)
          ? item.mcqOptions![index]
          : '';
    }
    return item.dictationAnswer ?? '';
  }

  Future<void> _advance(_PracticeItem item, bool finished) async {
    await _markPracticed(item);
    if (!mounted) {
      return;
    }
    if (finished) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index += 1;
      _step = _Step.listen;
      _checked = false;
      _correct = false;
      _selectedOption = -1;
      _answerController.clear();
    });
  }

  Future<void> _markPracticed(_PracticeItem item) async {
    try {
      await ref
          .read(challengeActionsProvider)
          .markVisited(widget.challenge.id, item.challengeItem.id);
      if (item.isWord) {
        try {
          await ref
              .read(wordsRepositoryProvider)
              .markReviewed(item.challengeItem.focusId);
        } catch (_) {
          // Best-effort.
        }
      }
    } catch (_) {
      // Best-effort; the sheet still advances.
    }
  }

  // --- recording ---
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
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

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
    } catch (_) {
      // ignore
    }
    if (mounted) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _playRecording() async {
    final path = _recordingPath;
    if (path == null) {
      return;
    }
    final player = _reviewPlayer ??= AudioPlayer();
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

  // --- content resolution ---
  List<_PracticeItem> _resolve() {
    final timeline = ref.read(timelineControllerProvider).value;
    final shelf = ref.read(wordShelfProvider).value;

    final raws = <_Raw>[];
    for (final ci in widget.items) {
      TimelineItem? source;
      if (timeline != null) {
        for (final candidate in timeline.items) {
          final id = switch (candidate) {
            TimelineWordItem(:final id) => id,
            TimelineSceneItem(:final id) => id,
            _ => null,
          };
          if (id == ci.discoveryId) {
            source = candidate;
            break;
          }
        }
      }
      if (ci.focusType == 'word') {
        WordShelfItem? shelfWord;
        if (shelf != null) {
          for (final w in shelf.words) {
            if (w.id == ci.focusId) {
              shelfWord = w;
              break;
            }
          }
        }
        final word = switch (source) {
          TimelineWordItem(:final word) => word,
          _ => shelfWord?.word,
        };
        final audio = switch (source) {
          TimelineWordItem(:final audio) => audio,
          _ => shelfWord?.audio,
        };
        raws.add(
          _Raw(
            ci: ci,
            isWord: true,
            title: word?.spelling ?? ci.title,
            meaningZh: word?.primarySense?.definitionZh,
            audioUrl: audio?.urlFor(WordAudioAccent.us),
            dictationAnswer: word?.spelling ?? ci.title,
          ),
        );
      } else {
        final scene = switch (source) {
          TimelineSceneItem(:final scene) => scene,
          _ => null,
        };
        final audio = source is TimelineSceneItem ? source.audio : null;
        final natural = scene?.naturalEnglish ?? ci.title;
        String? fill;
        String? fillAnswer;
        if (scene != null) {
          for (final keyword in scene.keyWords) {
            if (keyword.trim().isEmpty) {
              continue;
            }
            final pattern = RegExp(
              RegExp.escape(keyword),
              caseSensitive: false,
            );
            if (pattern.hasMatch(natural)) {
              fill = natural.replaceFirst(pattern, '____');
              fillAnswer = keyword;
              break;
            }
          }
        }
        raws.add(
          _Raw(
            ci: ci,
            isWord: false,
            title: natural,
            audioUrl: audio?.isReady == true ? audio!.url : null,
            fillSentence: fill,
            dictationAnswer: fillAnswer,
            chunkMeanings: scene == null
                ? const []
                : scene.keyChunks.map((c) => c.meaningNative).toList(),
          ),
        );
      }
    }

    final wordMeanings = raws
        .where((r) => r.isWord && (r.meaningZh ?? '').trim().isNotEmpty)
        .map((r) => r.meaningZh!.trim())
        .toSet()
        .toList();
    final sceneMeanings = raws
        .expand((r) => r.chunkMeanings)
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    final items = <_PracticeItem>[];
    for (var i = 0; i < raws.length; i++) {
      final r = raws[i];
      List<String>? options;
      int? correctIndex;
      String? question;
      if (r.isWord && (r.meaningZh ?? '').trim().isNotEmpty) {
        final distractors = wordMeanings
            .where((m) => m != r.meaningZh!.trim())
            .take(3)
            .toList();
        if (distractors.length >= 2) {
          options = [r.meaningZh!.trim(), ...distractors]..sort();
          correctIndex = options.indexOf(r.meaningZh!.trim());
          question = r.title;
        }
      } else if (!r.isWord && r.chunkMeanings.isNotEmpty) {
        final correct = r.chunkMeanings.first.trim();
        final distractors = sceneMeanings
            .where((m) => m != correct)
            .take(3)
            .toList();
        if (correct.isNotEmpty && distractors.length >= 2) {
          options = [correct, ...distractors]..sort();
          correctIndex = options.indexOf(correct);
          question = r.title;
        }
      }

      final preferMcq = r.isWord ? i.isOdd : true;
      final useMcq = preferMcq && options != null;
      items.add(
        _PracticeItem(
          challengeItem: r.ci,
          isWord: r.isWord,
          title: r.title,
          meaningZh: r.meaningZh,
          audioUrl: r.audioUrl,
          dictationAnswer: useMcq ? null : (r.dictationAnswer ?? r.title),
          fillSentence: r.isWord ? null : (useMcq ? null : r.fillSentence),
          mcqQuestion: useMcq ? question : null,
          mcqOptions: useMcq ? options : null,
          mcqCorrectIndex: useMcq ? correctIndex : null,
        ),
      );
    }
    return items;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _Raw {
  _Raw({
    required this.ci,
    required this.isWord,
    required this.title,
    this.meaningZh,
    this.audioUrl,
    this.dictationAnswer,
    this.fillSentence,
    this.chunkMeanings = const [],
  });

  final ChallengeItem ci;
  final bool isWord;
  final String title;
  final String? meaningZh;
  final String? audioUrl;
  final String? dictationAnswer;
  final String? fillSentence;
  final List<String> chunkMeanings;
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final labels = [t.practiceListen, t.practiceSpeak, t.practiceExercise];
    final index = _Step.values.indexOf(step);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: i <= index ? palette.primary : palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: i <= index ? palette.onPrimary : palette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool correct;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final borderColor = correct
        ? palette.accent
        : selected
        ? palette.error
        : palette.line;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s16),
      borderColor: borderColor,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (correct)
            AppLineIcon(AppLineGlyph.checkCircle, color: palette.accent),
          if (selected && !correct)
            AppLineIcon(AppLineGlyph.close, color: palette.error),
        ],
      ),
    );
  }
}
