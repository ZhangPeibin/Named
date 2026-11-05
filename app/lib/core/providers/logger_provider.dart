import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../logging/console_app_logger.dart';

final loggerProvider = Provider<AppLogger>((ref) {
  return ConsoleAppLogger();
});
