import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/speech/speech_providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/audio_control.dart';
import '../../../i18n/strings.g.dart';
import '../../discover/domain/discover.dart';
import '../../timeline/domain/timeline_item.dart';
import '../../timeline/providers/timeline_providers.dart';
import '../../words/domain/word_shelf.dart';
import '../../words/providers/words_providers.dart';
import '../domain/challenge.dart';
import '../providers/challenge_providers.dart';

enum _Phase { listenSay, test }

enum _QuestionKind { cloze, translation, dictation, freeProduction }

class _Question {
  const _Question({
    required this.prompt,
    required this.kind,
    this.textAnswer,
    this.modelAnswer,
    this.audioText,
    this.audioUrl,
  });

  final String prompt;
  final _QuestionKind kind;
  final String? textAnswer;
  final String? modelAnswer;
  final String? audioText;
  final String? audioUrl;
}

class _PracticeItem {
  const _PracticeItem({
    required this.challengeItem,
    required this.isWord,
    required this.title,
    this.audioUrl,
    this.sentenceEn,
    required this.questions,
  });

  final ChallengeItem challengeItem;
  final bool isWord;
  final String title;
  final String? audioUrl;
  final String? sentenceEn;
  final List<_Question> questions;

  String get sayTarget {
    final sentence = sentenceEn?.trim() ?? '';
    return sentence.isNotEmpty ? sentence : title;
  }
}

class ChallengePracticePage extends ConsumerStatefulWidget {
  const ChallengePracticePage({
    super.key,
    required this.challengeId,
    this.itemId,
  });

  final String challengeId;
  final String? itemId;

  @override
  ConsumerState<ChallengePracticePage> createState() =>
      _ChallengePracticePageState();
}

class _ChallengePracticePageState extends ConsumerState<ChallengePracticePage> {
  final _answerController = TextEditingController();
  final _recorder = AudioRecorder();
  AudioPlayer? _reviewPlayer;
  String? _recordingPath;
  var _isRecording = false;
  var _isTranscribing = false;
  var _micDenied = false;
  var _transcript = '';
  bool? _sayOk;
  final _sentenceAudioCache = <String, String>{};

  List<_PracticeItem> _items = const [];
  List<String>? _practiceItemIds;
  var _index = 0;
  var _phase = _Phase.listenSay;
  var _question = 0;
  var _checked = false;
  var _correct = false;
  var _correctAnswers = 0;
  var _done = false;

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
    final t = context.t.challenge;
    final async = ref.watch(challengeProvider(widget.challengeId));
    final shelfValue = ref.watch(wordShelfProvider).value;
    final timelineValue = ref.watch(timelineControllerProvider).value;
    return AppScaffold(
      title: t.practiceTitle,
      centerBody: false,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.detailFailed,
            message: context.t.common.somethingWentWrong,
            onRetry: () =>
                ref.invalidate(challengeProvider(widget.challengeId)),
          ),
        ),
        data: (challenge) {
          _items = _resolveWith(
            _chooseItems(challenge),
            timelineValue,
            shelfValue,
          );
          if (_items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Text(
                  context.t.challenge.noContent,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          if (_done) {
            return _summaryView();
          }
          return _practiceView(context);
        },
      ),
    );
  }

  Widget _practiceView(BuildContext context) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final item = _items[_index];
    final totalQuestions = item.questions.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _phase == _Phase.listenSay
                    ? t.practiceListenSay
                    : '${t.practiceExercise} ${_question + 1}/$totalQuestions',
                style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
              ),
            ),
            Text(
              '${_index + 1} / ${_items.length}',
              style: AppTextStyles.caption.copyWith(color: palette.muted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        if (_phase == _Phase.listenSay)
          ..._listenSayBody(item)
        else
          ..._testBody(item),
        const SizedBox(height: AppSpacing.s20),
        _actions(item),
      ],
    );
  }

  List<Widget> _listenSayBody(_PracticeItem item) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final title = item.title.trim().isNotEmpty
        ? item.title
        : (item.challengeItem.title.trim().isNotEmpty
              ? item.challengeItem.title
              : '—');
    return [
      Text(title, style: Theme.of(context).textTheme.displayMedium),
      const SizedBox(height: AppSpacing.s8),
      Text(
        t.practiceListenHint,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: palette.muted),
      ),
      if (item.audioUrl != null) ...[
        const SizedBox(height: AppSpacing.s16),
        Align(
          alignment: Alignment.centerLeft,
          child: AudioControl(
            sourceId: 'practice.${item.challengeItem.id}',
            resolveUrl: () async => item.audioUrl,
            playTooltip: context.t.timeline.play,
            pauseTooltip: context.t.timeline.pause,
            speedTooltip: context.t.timeline.speed,
            errorText: context.t.timeline.audioUnavailable,
          ),
        ),
      ] else ...[
        const SizedBox(height: AppSpacing.s12),
        Text(
          context.t.timeline.audioUnavailable,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
      if (item.isWord && (item.sentenceEn?.trim().isNotEmpty ?? false)) ...[
        const SizedBox(height: AppSpacing.s20),
        Text(
          item.sentenceEn!.trim(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.s8),
        Align(
          alignment: Alignment.centerLeft,
          child: AudioControl(
            sourceId: 'practice.sentence.${item.challengeItem.id}',
            resolveUrl: () => _resolveSentenceAudio(item.sentenceEn!.trim()),
            playTooltip: context.t.timeline.play,
            pauseTooltip: context.t.timeline.pause,
            speedTooltip: context.t.timeline.speed,
            errorText: context.t.timeline.audioUnavailable,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          t.practiceSentenceHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
      const SizedBox(height: AppSpacing.s24),
      Text(
        t.practiceSpeakHint,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: palette.muted),
      ),
      const SizedBox(height: AppSpacing.s12),
      Row(
        children: [
          Expanded(
            child: AppButton(
              key: const Key('practice.record'),
              label: _isRecording ? t.practiceStop : t.practiceRecord,
              icon: AppLineIcon(
                _isRecording ? AppLineGlyph.stop : AppLineGlyph.mic,
                size: 18,
                color: palette.onPrimary,
              ),
              onPressed: _isTranscribing ? null : _toggleRecording,
            ),
          ),
          if (_recordingPath != null && !_isRecording) ...[
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: AppButton(
                key: const Key('practice.playback'),
                label: t.practicePlayback,
                variant: AppButtonVariant.secondary,
                onPressed: _playRecording,
              ),
            ),
          ],
        ],
      ),
      if (_isTranscribing) ...[
        const SizedBox(height: AppSpacing.s12),
        const LinearProgressIndicator(minHeight: 2),
      ],
      if (_micDenied) ...[
        const SizedBox(height: AppSpacing.s8),
        Text(
          t.practiceMicDenied,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
      if (_transcript.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.s12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_transcript, style: Theme.of(context).textTheme.bodyLarge),
              if (_sayOk != null) ...[
                const SizedBox(height: AppSpacing.s6),
                Text(
                  _sayOk! ? t.practiceSayOk : t.practiceSayRetry,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _sayOk! ? palette.accent : palette.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _testBody(_PracticeItem item) {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final question = item.questions[_question];

    final body = <Widget>[];
    switch (question.kind) {
      case _QuestionKind.dictation:
        body.add(Text(t.practiceDictation, style: textTheme.headlineMedium));
        body.add(const SizedBox(height: AppSpacing.s12));
        body.add(
          Align(
            alignment: Alignment.centerLeft,
            child: AudioControl(
              sourceId:
                  'practice.dictation.${item.challengeItem.id}.$_question',
              resolveUrl: () => _resolveQuestionAudio(question),
              playTooltip: context.t.timeline.play,
              pauseTooltip: context.t.timeline.pause,
              speedTooltip: context.t.timeline.speed,
              errorText: context.t.timeline.audioUnavailable,
            ),
          ),
        );
      case _QuestionKind.freeProduction:
        body.add(Text(question.prompt, style: textTheme.headlineMedium));
      case _QuestionKind.translation:
      case _QuestionKind.cloze:
        body.add(
          Text(
            (question.kind == _QuestionKind.translation
                    ? t.practiceTranslate
                    : t.practiceCloze)
                .toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
          ),
        );
        body.add(const SizedBox(height: AppSpacing.s8));
        body.add(Text(question.prompt, style: textTheme.headlineMedium));
    }
    body.add(const SizedBox(height: AppSpacing.s16));
    body.add(
      TextField(
        key: const Key('practice.answer'),
        controller: _answerController,
        enabled: !_checked,
        textInputAction: question.kind == _QuestionKind.freeProduction
            ? TextInputAction.newline
            : TextInputAction.done,
        maxLines: question.kind == _QuestionKind.freeProduction ? 3 : 1,
        decoration: InputDecoration(hintText: t.practicePlaceholder),
        onSubmitted: (_) => _check(item),
      ),
    );
    if (_checked) {
      body.add(const SizedBox(height: AppSpacing.s12));
      if (question.kind == _QuestionKind.freeProduction) {
        body.add(
          Text(
            t.practiceModel.replaceFirst(
              '{answer}',
              question.modelAnswer ?? '',
            ),
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        );
      } else {
        body.add(
          Text(
            _correct ? t.practiceCorrect : t.practiceIncorrect,
            style: textTheme.labelLarge?.copyWith(
              color: _correct ? palette.accent : palette.error,
            ),
          ),
        );
        body.add(const SizedBox(height: AppSpacing.s4));
        body.add(
          Text(
            t.practiceAnswer.replaceFirst('{answer}', _answerOf(question)),
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        );
      }
    }
    return body;
  }

  Widget _actions(_PracticeItem item) {
    final t = context.t.challenge;
    if (_phase == _Phase.listenSay) {
      return AppButton(
        key: const Key('practice.next'),
        label: t.practiceNext,
        variant: AppButtonVariant.secondary,
        onPressed: () => setState(() {
          _phase = _Phase.test;
          _question = 0;
          _resetAnswer();
        }),
      );
    }
    if (!_checked) {
      return AppButton(
        key: const Key('practice.check'),
        label: t.practiceCheck,
        onPressed: () => _check(item),
      );
    }
    return AppButton(
      key: const Key('practice.continue'),
      label: t.practiceNext,
      onPressed: () => _advance(item),
    );
  }

  Future<void> _advance(_PracticeItem item) async {
    final moreQuestions = _question < item.questions.length - 1;
    if (moreQuestions) {
      setState(() {
        _question += 1;
        _resetAnswer();
      });
      return;
    }
    await _markPracticed(item);
    if (!mounted) {
      return;
    }
    final moreItems = _index < _items.length - 1;
    if (moreItems) {
      setState(() {
        _index += 1;
        _phase = _Phase.listenSay;
        _question = 0;
        _resetAnswer();
        _transcript = '';
        _sayOk = null;
      });
    } else {
      setState(() => _done = true);
    }
  }

  void _resetAnswer() {
    _checked = false;
    _correct = false;
    _answerController.clear();
  }

  void _check(_PracticeItem item) {
    final question = item.questions[_question];
    if (question.kind != _QuestionKind.freeProduction &&
        _normalize(_answerController.text).isEmpty) {
      return;
    }
    setState(() {
      _checked = true;
      _correct = _answerMatches(question, _answerController.text);
      if (_correct) {
        _correctAnswers++;
      }
    });
  }

  bool _answerMatches(_Question question, String answer) {
    if (question.kind == _QuestionKind.freeProduction) {
      return true;
    }
    final expected = question.textAnswer ?? '';
    if (question.kind == _QuestionKind.cloze) {
      return _normalize(answer) == _normalize(expected);
    }
    return _sentenceMatches(expected, answer);
  }

  String _answerOf(_Question question) {
    switch (question.kind) {
      case _QuestionKind.freeProduction:
        return question.modelAnswer ?? '';
      case _QuestionKind.cloze:
      case _QuestionKind.translation:
      case _QuestionKind.dictation:
        return question.textAnswer ?? '';
    }
  }

  Future<void> _markPracticed(_PracticeItem item) async {
    try {
      await ref
          .read(challengeActionsProvider)
          .markVisited(widget.challengeId, item.challengeItem.id);
      if (item.isWord) {
        try {
          await ref
              .read(wordsRepositoryProvider)
              .markReviewed(item.challengeItem.focusId);
        } catch (_) {
          // best effort
        }
      }
    } catch (_) {
      // best effort
    }
  }

  Widget _summaryView() {
    final t = context.t.challenge;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      children: [
        const SizedBox(height: AppSpacing.s8),
        AppLineIcon(AppLineGlyph.sparkle, size: 40, color: palette.accent),
        const SizedBox(height: AppSpacing.s16),
        Text(
          t.practiceRecap.replaceFirst('{count}', '${_items.length}'),
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '$_correctAnswers / ${_totalQuestions()}',
          style: AppTextStyles.caption.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s24),
        AppButton(
          key: const Key('practice.finish'),
          label: t.practiceDone,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  int _totalQuestions() =>
      _items.fold(0, (sum, item) => sum + item.questions.length);

  // --- recording / STT ---
  Future<void> _toggleRecording() async {
    final item = _items[_index];
    if (_isRecording) {
      await _stopRecording(item);
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) setState(() => _micDenied = true);
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
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _micDenied = false;
        _transcript = '';
        _sayOk = null;
      });
    } catch (_) {
      if (mounted) setState(() => _micDenied = true);
    }
  }

  Future<void> _stopRecording(_PracticeItem item) async {
    try {
      await _recorder.stop();
    } catch (_) {
      // ignore
    }
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });
    final path = _recordingPath;
    try {
      if (path != null) {
        final bytes = await File(path).readAsBytes();
        final text = await ref.read(speechRepositoryProvider).transcribe(bytes);
        if (!mounted) return;
        setState(() {
          _transcript = text.trim();
          _sayOk = _sayMatches(item.sayTarget, text);
          _isTranscribing = false;
        });
      } else {
        setState(() => _isTranscribing = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _sayOk = null;
        });
      }
    }
  }

  Future<void> _playRecording() async {
    final path = _recordingPath;
    if (path == null) return;
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
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // ignore
    }
  }

  Future<String?> _resolveSentenceAudio(String text) async {
    final cached = _sentenceAudioCache[text];
    if (cached != null) {
      return cached;
    }
    final audio = await ref.read(speechRepositoryProvider).synthesize(text);
    if (!audio.isReady || audio.url == null) {
      return null;
    }
    _sentenceAudioCache[text] = audio.url!;
    return audio.url;
  }

  Future<String?> _resolveQuestionAudio(_Question question) async {
    if (question.audioUrl != null) {
      return question.audioUrl;
    }
    final text = question.audioText;
    if (text == null || text.isEmpty) {
      return null;
    }
    return _resolveSentenceAudio(text);
  }

  // --- content resolution ---
  List<ChallengeItem> _chooseItems(Challenge challenge) {
    final frozen = _practiceItemIds;
    if (frozen == null) {
      final selected = widget.itemId == null
          ? challenge.items.where((item) => !item.visited).take(3).toList()
          : challenge.items.where((item) => item.id == widget.itemId).toList();
      final source = selected.isEmpty
          ? challenge.items.take(3).toList()
          : selected;
      _practiceItemIds = source.map((item) => item.id).toList();
      return source;
    }
    final byId = {for (final item in challenge.items) item.id: item};
    return frozen
        .map((id) => byId[id])
        .whereType<ChallengeItem>()
        .toList(growable: false);
  }

  List<_PracticeItem> _resolveWith(
    List<ChallengeItem> source,
    TimelineState? timeline,
    WordShelf? shelf,
  ) {
    if (source.isEmpty) return const [];

    final raws = <_Raw>[];
    for (final ci in source) {
      TimelineItem? timelineItem;
      if (timeline != null) {
        for (final candidate in timeline.items) {
          final id = switch (candidate) {
            TimelineWordItem(:final id) => id,
            TimelineSceneItem(:final id) => id,
            _ => null,
          };
          if (id == ci.discoveryId) {
            timelineItem = candidate;
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
        final word = switch (timelineItem) {
          TimelineWordItem(:final word) => word,
          _ => shelfWord?.word,
        };
        final audio = switch (timelineItem) {
          TimelineWordItem(:final audio) => audio,
          _ => shelfWord?.audio,
        };
        final sense = word?.primarySense;
        raws.add(
          _Raw(
            ci: ci,
            isWord: true,
            title: word?.spelling ?? ci.title,
            meaningZh: sense?.definitionZh,
            exampleEn: sense?.exampleEn ?? '',
            exampleZh: sense?.exampleZh ?? '',
            audioUrl: audio?.urlFor(defaultWordAudioAccent),
            textAnswer: word?.spelling ?? ci.title,
          ),
        );
      } else {
        final scene = switch (timelineItem) {
          TimelineSceneItem(:final scene) => scene,
          _ => null,
        };
        final audio = timelineItem is TimelineSceneItem
            ? timelineItem.audio
            : null;
        final natural = scene?.naturalEnglish ?? ci.title;
        String? fill;
        String? fillAnswer;
        if (scene != null) {
          for (final keyword in scene.keyWords) {
            if (keyword.trim().isEmpty) continue;
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
        final chunk = (scene?.keyChunks.isNotEmpty ?? false)
            ? scene!.keyChunks.first
            : null;
        raws.add(
          _Raw(
            ci: ci,
            isWord: false,
            title: natural,
            audioUrl: audio?.isReady == true ? audio!.url : null,
            textAnswer: fillAnswer ?? natural,
            fillSentence: fill,
            chunkPhrase: chunk?.phrase,
            chunkExampleEn: chunk?.exampleEn,
            chunkMeanings: scene == null
                ? const []
                : scene.keyChunks.map((c) => c.meaningNative).toList(),
          ),
        );
      }
    }

    final t = context.t.challenge;
    final items = <_PracticeItem>[];
    for (final r in raws) {
      final questions = <_Question>[];
      if (r.isWord) {
        final target = r.title.trim();
        final exampleEn = r.exampleEn.trim();
        final exampleZh = r.exampleZh.trim();
        if (exampleEn.isNotEmpty) {
          final cloze = _clozeOf(exampleEn, target);
          if (cloze != null) {
            questions.add(
              _Question(
                prompt: cloze,
                kind: _QuestionKind.cloze,
                textAnswer: target,
              ),
            );
          }
          if (exampleZh.isNotEmpty) {
            questions.add(
              _Question(
                prompt: exampleZh,
                kind: _QuestionKind.translation,
                textAnswer: exampleEn,
              ),
            );
          }
          questions.add(
            _Question(
              prompt: t.practiceFreePrompt.replaceFirst('{word}', target),
              kind: _QuestionKind.freeProduction,
              modelAnswer: exampleEn,
            ),
          );
        }
        if (questions.isEmpty) {
          final prompt = (r.meaningZh ?? '').trim().isNotEmpty
              ? r.meaningZh!.trim()
              : target;
          questions.add(
            _Question(
              prompt: prompt,
              kind: _QuestionKind.cloze,
              textAnswer: target,
            ),
          );
        }
      } else {
        final natural = r.title.trim();
        if (natural.isNotEmpty) {
          questions.add(
            _Question(
              prompt: t.practiceDictation,
              kind: _QuestionKind.dictation,
              textAnswer: natural,
              audioUrl: r.audioUrl,
              audioText: r.audioUrl == null ? natural : null,
            ),
          );
        }
        if (r.fillSentence != null && r.textAnswer.isNotEmpty) {
          questions.add(
            _Question(
              prompt: r.fillSentence!,
              kind: _QuestionKind.cloze,
              textAnswer: r.textAnswer,
            ),
          );
        }
        final chunk = r.chunkPhrase?.trim() ?? '';
        if (chunk.isNotEmpty) {
          questions.add(
            _Question(
              prompt: t.practiceFreePrompt.replaceFirst('{word}', chunk),
              kind: _QuestionKind.freeProduction,
              modelAnswer: r.chunkExampleEn ?? '',
            ),
          );
        }
        if (questions.isEmpty) {
          questions.add(
            _Question(
              prompt: natural,
              kind: _QuestionKind.cloze,
              textAnswer: natural,
            ),
          );
        }
      }
      items.add(
        _PracticeItem(
          challengeItem: r.ci,
          isWord: r.isWord,
          title: r.title,
          audioUrl: r.audioUrl,
          sentenceEn: r.isWord
              ? (r.exampleEn.trim().isEmpty ? null : r.exampleEn.trim())
              : r.title,
          questions: questions,
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

  static bool _sayMatches(String target, String transcript) {
    final a = _normalize(target);
    final b = _normalize(transcript);
    if (a.isEmpty || b.isEmpty) return false;
    if (b.contains(a) || a.contains(b)) return true;
    final aw = a.split(' ').where((w) => w.isNotEmpty).toSet();
    final bw = b.split(' ').where((w) => w.isNotEmpty).toSet();
    if (aw.isEmpty) return false;
    return aw.intersection(bw).length / aw.length >= 0.6;
  }

  static bool _sentenceMatches(String target, String answer) {
    final a = _normalize(target);
    final b = _normalize(answer);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b || b.contains(a)) return true;
    final aw = a.split(' ').where((w) => w.isNotEmpty).toList();
    final bw = b.split(' ').where((w) => w.isNotEmpty).toSet();
    if (aw.isEmpty) return false;
    final hit = aw.where(bw.contains).length;
    return hit / aw.length >= 0.8;
  }

  static String? _clozeOf(String sentence, String word) {
    if (word.isEmpty) return null;
    final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
    if (!pattern.hasMatch(sentence)) return null;
    return sentence.replaceFirst(pattern, '____');
  }
}

class _Raw {
  _Raw({
    required this.ci,
    required this.isWord,
    required this.title,
    this.meaningZh,
    this.exampleEn = '',
    this.exampleZh = '',
    this.audioUrl,
    required this.textAnswer,
    this.fillSentence,
    this.chunkPhrase,
    this.chunkExampleEn,
    this.chunkMeanings = const [],
  });

  final ChallengeItem ci;
  final bool isWord;
  final String title;
  final String? meaningZh;
  final String exampleEn;
  final String exampleZh;
  final String? audioUrl;
  final String textAnswer;
  final String? fillSentence;
  final String? chunkPhrase;
  final String? chunkExampleEn;
  final List<String> chunkMeanings;
}
