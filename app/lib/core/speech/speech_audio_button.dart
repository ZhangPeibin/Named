import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/audio_control.dart';
import 'speech_providers.dart';

/// Inline play control for any piece of text. Synthesizes lazily through the
/// shared speech cache, or uses a URL already returned by the server.
class SpeechAudioButton extends ConsumerWidget {
  const SpeechAudioButton({
    super.key,
    required this.text,
    required this.sourceId,
    required this.playTooltip,
    required this.pauseTooltip,
    required this.speedTooltip,
    this.errorText,
    this.prefetchedUrl,
    this.dimension = 28,
    this.iconSize = 12,
    this.color,
  });

  final String text;
  final String sourceId;
  final String playTooltip;
  final String pauseTooltip;
  final String speedTooltip;
  final String? errorText;
  final String? prefetchedUrl;
  final double dimension;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AudioControl(
      sourceId: sourceId,
      resolveUrl: () async {
        final prefetched = prefetchedUrl;
        if (prefetched != null && prefetched.isNotEmpty) {
          return prefetched;
        }
        return ref.read(speechUrlCacheProvider).resolve(text);
      },
      playTooltip: playTooltip,
      pauseTooltip: pauseTooltip,
      speedTooltip: speedTooltip,
      errorText: errorText,
      dimension: dimension,
      iconSize: iconSize,
      color: color,
    );
  }
}
