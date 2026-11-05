import 'package:logger/logger.dart';

import 'app_logger.dart';

class ConsoleAppLogger implements AppLogger {
  ConsoleAppLogger({Logger? logger, bool enableDebugLogs = true})
    : _logger = logger ?? _createDefaultLogger(enableDebugLogs);

  final Logger _logger;

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static Logger _createDefaultLogger(bool enableDebugLogs) {
    return Logger(
      filter: _MinimumLevelFilter(
        enableDebugLogs ? Level.debug : Level.warning,
      ),
      printer: PrettyPrinter(
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }
}

class _MinimumLevelFilter extends LogFilter {
  _MinimumLevelFilter(this.minimumLevel);

  final Level minimumLevel;

  @override
  bool shouldLog(LogEvent event) => event.level.index >= minimumLevel.index;
}
