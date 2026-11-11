import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/audio/audio_providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/audio_speed_control.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/talk.dart';
import '../../providers/talk_providers.dart';

class HelpSheet extends ConsumerStatefulWidget {
  const HelpSheet({
    super.key,
    required this.conversationId,
    required this.initialText,
  });

  final String conversationId;
  final String initialText;

  @override
  ConsumerState<HelpSheet> createState() => _HelpSheetState();
}

class _HelpSheetState extends ConsumerState<HelpSheet> {
  late final TextEditingController _controller;
  HelpSuggestion? _suggestion;
  String? _error;
  var _isLoading = false;
  var _alternativeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.t.talk.helpEmptyInput);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _suggestion = null;
      _alternativeIndex = 0;
    });
    try {
      final suggestion = await ref
          .read(talkRepositoryProvider)
          .helpExpression(conversationId: widget.conversationId, text: text);
      if (mounted) {
        setState(() {
          _suggestion = suggestion;
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    }
  }

  void _nextAlternative() {
    final suggestion = _suggestion;
    if (suggestion == null || suggestion.alternatives.isEmpty) {
      return;
    }
    setState(() {
      _alternativeIndex =
          (_alternativeIndex + 1) % suggestion.alternatives.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.talk;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final suggestion = _suggestion;
    final hasAlternative = suggestion?.alternatives.isNotEmpty == true;
    final displayedEnglish = suggestion == null
        ? ''
        : _alternativeIndex == 0
        ? suggestion.naturalEnglish
        : suggestion.alternatives[_alternativeIndex - 1];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.helpTitle, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.s6),
          Text(
            t.helpSubtitle,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppTextField(
            key: const Key('talk.helpInput'),
            controller: _controller,
            hintText: t.helpInputHint,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_ask()),
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const Key('talk.helpAsk'),
              label: t.helpAsk,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _ask,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              _error!,
              style: textTheme.bodySmall?.copyWith(color: palette.error),
            ),
          ],
          if (suggestion != null) ...[
            const SizedBox(height: AppSpacing.s20),
            Text(
              t.helpResultTitle.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    displayedEnglish,
                    style: textTheme.headlineMedium,
                  ),
                ),
                if (suggestion.audio?.isReady == true) ...[
                  const SizedBox(width: AppSpacing.s8),
                  _HelpAudioButton(audio: suggestion.audio),
                ],
              ],
            ),
            if (suggestion.note != null &&
                suggestion.note!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s6),
              Text(
                suggestion.note!,
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
            if (hasAlternative) ...[
              const SizedBox(height: AppSpacing.s8),
              TextButton(
                key: const Key('talk.helpAlternative'),
                onPressed: _nextAlternative,
                child: Text(t.helpAnotherWay),
              ),
            ],
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                key: const Key('talk.helpUseThis'),
                label: t.helpUseThis,
                onPressed: () => Navigator.of(context).pop(suggestion),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpAudioButton extends ConsumerStatefulWidget {
  const _HelpAudioButton({required this.audio});

  final TalkAudio? audio;

  @override
  ConsumerState<_HelpAudioButton> createState() => _HelpAudioButtonState();
}

class _HelpAudioButtonState extends ConsumerState<_HelpAudioButton> {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<void> _completeSub;
  var _isPlaying = false;
  var _speed = 1.0;
  String? _cachedUrl;
  Uint8List? _cachedBytes;

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
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    final url = widget.audio?.url;
    if (widget.audio?.isReady != true || url == null) {
      return;
    }

    try {
      final bytes = await _loadBytes(url);
      if (!mounted) {
        return;
      }
      await _player.setPlaybackRate(_speed);
      if (_player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.talk.audioUnavailable)),
        );
      }
    }
  }

  Future<void> _setSpeed(double speed) async {
    setState(() => _speed = speed);
    if (_isPlaying || _player.state == PlayerState.paused) {
      await _player.setPlaybackRate(speed);
    }
  }

  Future<Uint8List> _loadBytes(String url) async {
    if (_cachedUrl == url && _cachedBytes != null) {
      return _cachedBytes!;
    }
    final data = await ref.read(audioBytesApiProvider).fetch(url);
    _cachedUrl = url;
    _cachedBytes = Uint8List.fromList(data);
    return _cachedBytes!;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.talk;

    return Semantics(
      container: true,
      label: _isPlaying ? t.pauseReply : t.playReply,
      excludeSemantics: true,
      child: AudioSpeedControl(
        playKey: const Key('talk.helpAudio'),
        speedKey: const Key('talk.helpAudio.speed'),
        isPlaying: _isPlaying,
        isLoading: false,
        speed: _speed,
        onToggle: _toggle,
        onSpeedChanged: (speed) => unawaited(_setSpeed(speed)),
        speedTooltip: t.speed,
        playTooltip: t.playReply,
        pauseTooltip: t.pauseReply,
      ),
    );
  }
}
