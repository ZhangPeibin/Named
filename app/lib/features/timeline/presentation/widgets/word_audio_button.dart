import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/speech/speech_providers.dart';
import '../../../../core/widgets/audio_control.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';

/// Play/pause + speed control for a word's US/UK audio. Backed by the shared
/// single-player audio controller.
class WordAudioButton extends ConsumerWidget {
  const WordAudioButton({
    super.key,
    required this.audio,
    this.text,
    this.accent = defaultWordAudioAccent,
    this.dimension = 28,
    this.iconSize = 12,
  });

  final WordAudio? audio;
  final String? text;
  final WordAudioAccent accent;
  final double dimension;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = audio?.urlFor(accent);
    final label = text?.trim() ?? '';
    if (url == null && label.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.t.timeline;
    final palette = context.appPalette;
    return AudioControl(
      sourceId: url != null ? 'word.$url' : 'word.$label.${accent.name}',
      resolveUrl: () async {
        final direct = audio?.urlFor(accent);
        if (direct != null) {
          return direct;
        }
        if (label.isEmpty) {
          return null;
        }
        final pronunciation = await ref
            .read(pronunciationCacheProvider)
            .resolve(label);
        if (pronunciation == null) {
          return null;
        }
        return switch (accent) {
          WordAudioAccent.us => pronunciation.usUrl ?? pronunciation.ukUrl,
          WordAudioAccent.uk => pronunciation.ukUrl ?? pronunciation.usUrl,
        };
      },
      playTooltip: t.play,
      pauseTooltip: t.pause,
      speedTooltip: t.speed,
      errorText: t.audioUnavailable,
      dimension: dimension,
      iconSize: iconSize,
      color: palette.muted,
    );
  }
}
