import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_playback_controller.dart';
import 'audio_speed_control.dart';

/// The single play/pause + speed control used everywhere in the app. It binds to
/// the shared [audioPlaybackControllerProvider], so only one clip plays at a
/// time and every control stays in sync.
class AudioControl extends ConsumerWidget {
  const AudioControl({
    super.key,
    required this.sourceId,
    required this.resolveUrl,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.speedTooltip,
    this.errorText,
    this.dimension = 28,
    this.showLabel = false,
    this.color,
    this.iconSize = 12,
    this.playKey,
    this.speedKey,
  });

  /// A stable id for this clip, used to know when it is the active one.
  final String sourceId;

  /// Resolves (and may synthesize) the audio URL lazily when play is tapped.
  final Future<String?> Function() resolveUrl;

  final String playTooltip;
  final String pauseTooltip;
  final String speedTooltip;

  /// Shown in a snackbar if playback fails.
  final String? errorText;
  final double dimension;

  /// Optional override for the icon/accent colour (defaults to primary).
  final Color? color;

  /// Optional icon size (defaults to 16).
  final double iconSize;

  /// When true, shows the play/pause text next to the icon.
  final bool showLabel;

  final Key? playKey;
  final Key? speedKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlaybackControllerProvider);
    final isPlaying = state.isPlayingId(sourceId);
    final isLoading = state.isLoadingId(sourceId);

    return AudioSpeedControl(
      playKey: playKey ?? ValueKey('audio.$sourceId.play'),
      speedKey: speedKey ?? ValueKey('audio.$sourceId.speed'),
      isPlaying: isPlaying,
      isLoading: isLoading,
      speed: state.speed,
      onToggle: () => unawaited(_toggle(context, ref)),
      onSpeedChanged: (speed) => unawaited(
        ref
            .read(audioPlaybackControllerProvider.notifier)
            .setSpeed(speed, id: sourceId),
      ),
      speedTooltip: speedTooltip,
      playTooltip: playTooltip,
      pauseTooltip: pauseTooltip,
      dimension: dimension,
      color: color,
      iconSize: iconSize,
      label: showLabel ? (isPlaying ? pauseTooltip : playTooltip) : null,
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(audioPlaybackControllerProvider.notifier)
          .toggle(sourceId, resolveUrl);
    } catch (_) {
      if (errorText != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText!)));
      }
    }
  }
}
