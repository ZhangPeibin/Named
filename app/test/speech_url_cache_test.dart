import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/speech/speech_api.dart';
import 'package:named/core/speech/speech_audio.dart';
import 'package:named/core/speech/speech_repository.dart';
import 'package:named/core/speech/speech_url_cache.dart';

class _CountingSpeechApi implements SpeechApi {
  var calls = 0;

  @override
  Future<PronunciationAudio> pronounce(String text) async {
    return const PronunciationAudio(usUrl: null, ukUrl: null);
  }

  @override
  Future<SpeechClip> synthesize(String text) async {
    calls++;
    return SpeechClip(url: 'https://audio.test/$text.mp3', status: 'ready');
  }

  @override
  Future<String> transcribe(Uint8List wav) async => 'text';
}

void main() {
  test('concurrent taps for one text synthesize once', () async {
    final api = _CountingSpeechApi();
    final cache = SpeechUrlCache(SpeechRepository(api));

    final results = await Future.wait([
      cache.resolve('I like you'),
      cache.resolve('I like you'),
    ]);

    expect(results, [
      'https://audio.test/I like you.mp3',
      'https://audio.test/I like you.mp3',
    ]);
    expect(api.calls, 1);

    final again = await cache.resolve('I like you');
    expect(again, 'https://audio.test/I like you.mp3');
    expect(api.calls, 1);
  });
}
