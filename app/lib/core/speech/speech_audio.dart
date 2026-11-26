enum PronunciationAccent { us, uk }

const defaultPronunciationAccent = PronunciationAccent.uk;

/// A single synthesized speech clip.
class SpeechClip {
  const SpeechClip({required this.url, required this.status});

  final String? url;
  final String status;

  bool get isReady => status == 'ready' && url != null && url!.isNotEmpty;
}

/// US and UK pronunciations for one text.
class PronunciationAudio {
  const PronunciationAudio({required this.usUrl, required this.ukUrl});

  final String? usUrl;
  final String? ukUrl;

  String? urlFor(PronunciationAccent accent) {
    return switch (accent) {
      PronunciationAccent.us => usUrl ?? ukUrl,
      PronunciationAccent.uk => ukUrl ?? usUrl,
    };
  }

  bool get hasAudio => urlFor(defaultPronunciationAccent) != null;
}
