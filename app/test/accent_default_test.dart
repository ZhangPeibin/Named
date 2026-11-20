import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/discover/domain/discover.dart';
import 'package:named/features/talk/domain/talk.dart';

void main() {
  group('default accent', () {
    test('word audio prefers UK and falls back to US', () {
      const both = WordAudio(usUrl: 'us.mp3', ukUrl: 'uk.mp3');
      expect(defaultWordAudioAccent, WordAudioAccent.uk);
      expect(both.preferredUrl, 'uk.mp3');
      expect(both.urlFor(defaultWordAudioAccent), 'uk.mp3');

      const usOnly = WordAudio(usUrl: 'us.mp3', ukUrl: null);
      expect(usOnly.preferredUrl, 'us.mp3');
      expect(usOnly.hasAudio, isTrue);
    });

    test('pronunciation prefers UK and falls back to US', () {
      const both = PronunciationAudio(usUrl: 'us.mp3', ukUrl: 'uk.mp3');
      expect(defaultPronunciationAccent, PronunciationAccent.uk);
      expect(both.urlFor(defaultPronunciationAccent), 'uk.mp3');

      const usOnly = PronunciationAudio(usUrl: 'us.mp3', ukUrl: null);
      expect(usOnly.urlFor(defaultPronunciationAccent), 'us.mp3');
      expect(usOnly.hasAudio, isTrue);
    });
  });
}
