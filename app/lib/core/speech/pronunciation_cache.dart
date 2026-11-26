import 'speech_audio.dart';
import 'speech_repository.dart';

/// Resolves US/UK pronunciation lazily and de-duplicates concurrent taps.
class PronunciationCache {
  PronunciationCache(this._repository);

  final SpeechRepository _repository;
  final Map<String, PronunciationAudio?> _resolved = {};
  final Map<String, Future<PronunciationAudio?>> _pending = {};

  Future<PronunciationAudio?> resolve(String text) {
    if (_resolved.containsKey(text)) {
      return Future.value(_resolved[text]);
    }
    final inFlight = _pending[text];
    if (inFlight != null) {
      return inFlight;
    }
    final future = _repository.pronounce(text).then((audio) {
      final value = audio.hasAudio ? audio : null;
      _resolved[text] = value;
      return value;
    });
    _pending[text] = future;
    return future.whenComplete(() => _pending.remove(text));
  }
}
