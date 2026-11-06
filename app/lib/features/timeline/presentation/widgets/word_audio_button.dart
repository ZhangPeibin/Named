import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/audio/audio_providers.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';

class WordAudioButton extends ConsumerStatefulWidget {
  const WordAudioButton({
    super.key,
    required this.audio,
    this.accent = WordAudioAccent.us,
  });

  final WordAudio? audio;
  final WordAudioAccent accent;

  @override
  ConsumerState<WordAudioButton> createState() => _WordAudioButtonState();
}

class _WordAudioButtonState extends ConsumerState<WordAudioButton> {
  static const _speeds = [0.5, 1.0, 2.0];
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<void> _completeSub;
  var _speed = 1.0;
  var _isPlaying = false;
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
  void didUpdateWidget(covariant WordAudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accent != widget.accent) {
      unawaited(_player.stop());
      _cachedUrl = null;
      _cachedBytes = null;
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    unawaited(_stateSub.cancel());
    unawaited(_completeSub.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _playAt(double speed) async {
    final url = widget.audio?.urlFor(widget.accent);
    if (url == null) {
      return;
    }

    if (_isPlaying && _speed == speed) {
      await _player.pause();
      return;
    }

    setState(() => _speed = speed);
    try {
      if (_isPlaying) {
        await _player.setPlaybackRate(speed);
        return;
      }

      final bytes = await _loadBytes(url);
      await _player.setPlaybackRate(speed);
      if (_player.state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.timeline.audioUnavailable)),
        );
      }
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

  String _speedLabel(double speed) {
    return speed == speed.roundToDouble()
        ? '${speed.toInt()}×'
        : '${speed.toString()}×';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audio?.hasAudio != true) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final speed in _speeds) ...[
          if (speed != _speeds.first) const SizedBox(width: AppSpacing.s4),
          _SpeedButton(
            key: Key('word.audio.speed.$speed'),
            label: _speedLabel(speed),
            selected: _speed == speed,
            onTap: () => _playAt(speed),
          ),
        ],
      ],
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? palette.primary : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            width: 42,
            height: 34,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? palette.onPrimary : palette.primary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
