import 'dart:async';

abstract interface class ErrorReporter {
  FutureOr<void> report(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  });
}
