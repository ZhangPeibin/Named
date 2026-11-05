import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/console_error_reporter.dart';
import '../errors/error_reporter.dart';
import 'logger_provider.dart';

final errorReporterProvider = Provider<ErrorReporter>((ref) {
  return ConsoleErrorReporter(ref.watch(loggerProvider));
});
