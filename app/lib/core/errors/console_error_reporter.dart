import '../logging/app_logger.dart';
import 'error_reporter.dart';

class ConsoleErrorReporter implements ErrorReporter {
  const ConsoleErrorReporter(this._logger);

  final AppLogger _logger;

  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    _logger.error(
      [if (fatal) 'Fatal', reason ?? 'Unhandled error'].join(': '),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
