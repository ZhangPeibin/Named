import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/audio_control.dart';
import '../../../../i18n/strings.g.dart';
import '../../../discover/domain/discover.dart';

/// Play/pause + speed control for a scene's audio. Backed by the shared
/// single-player audio controller.
class SceneAudioButton extends ConsumerWidget {
  const SceneAudioButton({super.key, required this.audio});

  final SceneAudio? audio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = audio?.url;
    if (audio?.isReady != true || url == null) {
      return const SizedBox.shrink();
    }
    final t = context.t.timeline;
    return AudioControl(
      sourceId: 'scene.$url',
      resolveUrl: () async => url,
      playTooltip: t.playMoment,
      pauseTooltip: t.pauseMoment,
      speedTooltip: t.speed,
      errorText: t.audioUnavailable,
      dimension: 28,
      iconSize: 12,
      color: context.appPalette.muted,
    );
  }
}
