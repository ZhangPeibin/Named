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
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/audio_speed_control.dart';
import '../../../i18n/strings.g.dart';
import '../../talk/domain/talk.dart';
import '../../talk/providers/talk_providers.dart';
import '../domain/sentence_detail.dart';
import '../providers/sentence_providers.dart';

Future<void> showSentenceDetailSheet(BuildContext context, String text) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appPalette.canvas,
    builder: (context) => UncontrolledProviderScope(
      container: container,
      child: SentenceDetailSheet(text: text),
    ),
  );
}

class SentenceDetailSheet extends ConsumerWidget {
  const SentenceDetailSheet({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.talk;
    final async = ref.watch(sentenceDetailProvider(text));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s16,
            AppSpacing.s20,
            AppSpacing.s20,
          ),
          child: async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.s20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => AppErrorView(
              title: t.sentenceLoadFailed,
              message: error is ApiException
                  ? error.message
                  : context.t.common.somethingWentWrong,
              onRetry: () => ref.invalidate(sentenceDetailProvider(text)),
            ),
            data: (detail) => _SentenceDetailView(detail: detail),
          ),
        ),
      ),
    );
  }
}

class _SentenceDetailView extends StatelessWidget {
  const _SentenceDetailView({required this.detail});

  final SentenceDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = context.t.talk;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.sentenceDetails, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s16),
        Text(
          detail.original,
          style: textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(detail.naturalEnglish, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s8),
        _SentenceAudioButton(text: detail.naturalEnglish),
        const SizedBox(height: AppSpacing.s20),
        _SectionLabel(label: t.explanation),
        const SizedBox(height: AppSpacing.s6),
        Text(detail.explanationNative, style: textTheme.bodyMedium),
        if (detail.grammarNotes.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionLabel(label: t.grammarNotes),
          const SizedBox(height: AppSpacing.s6),
          Text(detail.grammarNotes, style: textTheme.bodySmall),
        ],
        if (detail.chunks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionLabel(label: t.chunks),
          const SizedBox(height: AppSpacing.s8),
          for (final chunk in detail.chunks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: _ChunkRow(chunk: chunk),
            ),
        ],
        if (detail.keyWords.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          _SectionLabel(label: t.keyWords),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s6,
            children: [
              for (final word in detail.keyWords)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${word.word}  ${word.meaningNative}',
                    style: AppTextStyles.caption.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s20),
        AppButton(
          key: const Key('sentence.copyEnglish'),
          label: t.copyEnglish,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: detail.naturalEnglish));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t.copied)));
            }
          },
        ),
      ],
    );
  }
}

class _ChunkRow extends StatelessWidget {
  const _ChunkRow({required this.chunk});

  final SentenceChunk chunk;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            chunk.phrase,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            chunk.meaningNative,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ),
      ],
    );
  }
}

class _SentenceAudioButton extends ConsumerStatefulWidget {
  const _SentenceAudioButton({required this.text});

  final String text;

  @override
  ConsumerState<_SentenceAudioButton> createState() =>
      _SentenceAudioButtonState();
}

class _SentenceAudioButtonState extends ConsumerState<_SentenceAudioButton> {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<void> _completeSub;
  TalkAudio? _audio;
  Uint8List? _cachedBytes;
  var _speed = 1.0;
  var _isPlaying = false;
  var _loading = false;
  String? _error;

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
    });
  }

  @override
  void dispose() {
    unawaited(_stateSub.cancel());
    unawaited(_completeSub.cancel());
    unawaited(_player.stop());
    unawaited(_player.dispose());
    super.dispose();
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

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final audio =
          _audio ??
          await ref.read(talkRepositoryProvider).synthesizeSpeech(widget.text);
      final url = audio.url;
      if (!audio.isReady || url == null) {
        throw StateError('Speech audio unavailable');
      }
      _audio = audio;
      final bytes =
          _cachedBytes ??
          Uint8List.fromList(await ref.read(audioBytesApiProvider).fetch(url));
      _cachedBytes = bytes;
      await _player.stop();
      await _player.setPlaybackRate(_speed);
      await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.t.talk.audioUnavailable);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _setSpeed(double speed) async {
    setState(() => _speed = speed);
    if (_isPlaying || _player.state == PlayerState.paused) {
      await _player.setPlaybackRate(speed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.talk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AudioSpeedControl(
          playKey: const Key('sentence.audio'),
          speedKey: const Key('sentence.audio.speed'),
          isPlaying: _isPlaying,
          isLoading: _loading,
          speed: _speed,
          onToggle: _toggle,
          onSpeedChanged: (speed) => unawaited(_setSpeed(speed)),
          speedTooltip: t.speed,
          playTooltip: t.playReply,
          pauseTooltip: t.pauseReply,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.appPalette.error),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.eyebrow.copyWith(color: context.appPalette.muted),
    );
  }
}
