import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:named/core/logging/console_app_logger.dart';

void main() {
  test('forwards log calls to logger package', () {
    final output = _MemoryLogOutput();
    final appLogger = ConsoleAppLogger(
      logger: Logger(printer: SimplePrinter(colors: false), output: output),
    );
    final error = StateError('failure');
    final stackTrace = StackTrace.current;

    appLogger.debug('debug message');
    appLogger.info('info message');
    appLogger.warning('warning message');
    appLogger.error('error message', error: error, stackTrace: stackTrace);

    expect(output.lines.any((line) => line.contains('debug message')), isTrue);
    expect(output.lines.any((line) => line.contains('info message')), isTrue);
    expect(
      output.lines.any((line) => line.contains('warning message')),
      isTrue,
    );
    expect(output.lines.any((line) => line.contains('error message')), isTrue);
    expect(
      output.lines.any((line) => line.contains('Bad state: failure')),
      isTrue,
    );
  });
}

class _MemoryLogOutput extends LogOutput {
  final lines = <String>[];

  @override
  void output(OutputEvent event) {
    lines.addAll(event.lines);
  }
}
