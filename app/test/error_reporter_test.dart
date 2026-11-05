import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/errors/console_error_reporter.dart';
import 'package:named/core/logging/app_logger.dart';

void main() {
  test('console reporter forwards errors to the injected logger', () {
    final logger = _RecordingLogger();
    const error = FormatException('invalid');
    final stackTrace = StackTrace.current;

    ConsoleErrorReporter(
      logger,
    ).report(error, stackTrace, reason: 'bootstrap', fatal: true);

    expect(logger.message, 'Fatal: bootstrap');
    expect(logger.loggedError, same(error));
    expect(logger.stackTrace, same(stackTrace));
  });
}

class _RecordingLogger implements AppLogger {
  String? message;
  Object? loggedError;
  StackTrace? stackTrace;

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    this.message = message;
    loggedError = error;
    this.stackTrace = stackTrace;
  }
}
