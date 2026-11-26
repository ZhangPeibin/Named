import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/speech/speech_audio_button.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';

/// Play/pause + speed control for a scene's audio. Uses a ready URL when the
/// server already has one, otherwise synthesizes the sentence on demand.
class SceneAudioButton extends ConsumerWidget {
  const SceneAudioButton({super.key, required this.audio, this.text});

  final SceneAudio? audio;
  final String? text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = audio?.isReady == true ? audio?.url : null;
    final label = text?.trim() ?? '';
    if (url == null && label.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.t.timeline;
    return SpeechAudioButton(
      text: label.isNotEmpty ? label : (url ?? ''),
      sourceId: url != null ? 'scene.$url' : 'scene.$label',
      prefetchedUrl: url,
      playTooltip: t.playMoment,
      pauseTooltip: t.pauseMoment,
      speedTooltip: t.speed,
      errorText: t.audioUnavailable,
      color: context.appPalette.muted,
    );
  }
}
