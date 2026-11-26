import 'speech_repository.dart';

/// Resolves synthesized speech lazily and de-duplicates concurrent taps for the
/// same text, so one suggestion never pays for two TTS requests.
class SpeechUrlCache {
  SpeechUrlCache(this._repository);

  final SpeechRepository _repository;
  final Map<String, String> _resolved = {};
  final Map<String, Future<String?>> _pending = {};

  Future<String?> resolve(String text) {
    final cached = _resolved[text];
    if (cached != null) {
      return Future.value(cached);
    }
    final inFlight = _pending[text];
    if (inFlight != null) {
      return inFlight;
    }
    final future = _repository.synthesize(text).then((clip) {
      final url = clip.isReady ? clip.url : null;
      if (url != null) {
        _resolved[text] = url;
      }
      return url;
    });
    _pending[text] = future;
    return future.whenComplete(() => _pending.remove(text));
  }
}
