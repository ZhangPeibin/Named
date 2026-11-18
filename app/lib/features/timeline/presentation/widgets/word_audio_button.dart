import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/audio_control.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';

/// Play/pause + speed control for a word's US/UK audio. Backed by the shared
/// single-player audio controller.
class WordAudioButton extends ConsumerWidget {
  const WordAudioButton({
    super.key,
    required this.audio,
    this.accent = WordAudioAccent.us,
  });

  final WordAudio? audio;
  final WordAudioAccent accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = audio?.urlFor(accent);
    if (url == null) {
      return const SizedBox.shrink();
    }
    final t = context.t.timeline;
    final palette = context.appPalette;
    return AudioControl(
      sourceId: 'word.$url',
      resolveUrl: () async => url,
      playTooltip: t.play,
      pauseTooltip: t.pause,
      speedTooltip: t.speed,
      errorText: t.audioUnavailable,
      dimension: 28,
      iconSize: 12,
      color: palette.muted,
    );
  }
}
