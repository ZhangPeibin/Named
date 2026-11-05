import 'package:flutter/foundation.dart';

/// Lightweight startup timing logs for diagnosing cold-start delays.
class StartupLogger {
  StartupLogger._();

  static final Stopwatch _watch = Stopwatch()..start();
  static final Set<String> _onceKeys = <String>{};

  static void mark(String message) {
    final elapsed = _watch.elapsedMilliseconds.toString().padLeft(5);
    debugPrint('[Startup][$elapsed ms] $message');
  }

  static void markOnce(String key, String message) {
    if (!_onceKeys.add(key)) {
      return;
    }
    mark(message);
  }
}
