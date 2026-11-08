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

class SceneAudioButton extends ConsumerStatefulWidget {
  const SceneAudioButton({super.key, required this.audio});

  final SceneAudio? audio;

  @override
  ConsumerState<SceneAudioButton> createState() => _SceneAudioButtonState();
}

class _SceneAudioButtonState extends ConsumerState<SceneAudioButton> {
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5];

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
  void didUpdateWidget(covariant SceneAudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audio?.url != widget.audio?.url) {
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
          SnackBar(content: Text(context.t.timeline.audioUnavailable)),
        );
      }
    }
  }

  Future<void> _setSpeed(double speed) async {
    setState(() => _speed = speed);
    if (_isPlaying) {
      await _player.setPlaybackRate(speed);
    }
  }

  String _speedLabel(double speed) {
    return speed == speed.roundToDouble()
        ? '${speed.toInt()}×'
        : '${speed.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}×';
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
    if (widget.audio?.isReady != true) {
      return const SizedBox.shrink();
    }

    final palette = context.appPalette;
    final t = context.t.timeline;

    final label = _isPlaying ? t.pauseMoment : t.playMoment;

    return Material(
      color: palette.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: label,
            onTap: _toggle,
            excludeSemantics: true,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s6,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.volume_up_outlined,
                  size: 16,
                  color: palette.primary,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 18, color: palette.line),
          PopupMenuButton<double>(
            tooltip: t.speed,
            initialValue: _speed,
            onSelected: (speed) => unawaited(_setSpeed(speed)),
            itemBuilder: (context) => [
              for (final speed in _speeds)
                CheckedPopupMenuItem<double>(
                  value: speed,
                  checked: speed == _speed,
                  child: Text(_speedLabel(speed)),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _speedLabel(_speed),
                    style: AppTextStyles.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 14, color: palette.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
