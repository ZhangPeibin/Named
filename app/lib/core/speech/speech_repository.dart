import 'dart:typed_data';

import 'speech_api.dart';
import 'speech_audio.dart';

class SpeechRepository {
  const SpeechRepository(this._api);

  final SpeechApi _api;

  Future<String> transcribe(Uint8List wav) => _api.transcribe(wav);

  Future<SpeechClip> synthesize(String text) => _api.synthesize(text);

  Future<PronunciationAudio> pronounce(String text) => _api.pronounce(text);
}
