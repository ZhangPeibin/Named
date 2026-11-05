import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/logging/app_logger.dart';
import 'package:named/core/network/dio_logging_interceptor.dart';
import 'package:named/core/network/error_interceptor.dart';
import 'package:named/core/providers/app_config_provider.dart';
import 'package:named/core/providers/dio_provider.dart';
import 'package:named/core/providers/logger_provider.dart';

void main() {
  test('creates Dio from app config', () {
    // ProviderContainer lets this test read Riverpod providers without
    // building a widget tree.
    final container = ProviderContainer(
      overrides: [
        // Use a test config so dioProvider can be verified without depending
        // on --dart-define files.
        appConfigProvider.overrideWithValue(
          const AppConfig(
            appName: 'Test App',
            environment: AppEnvironment.dev,
            apiBaseUrl: 'https://api.test',
          ),
        ),
        loggerProvider.overrideWithValue(_FakeAppLogger()),
      ],
    );
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    // dioProvider should use AppConfig as the single source of network config.
    expect(dio.options.baseUrl, 'https://api.test');
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 10));
    expect(dio.options.sendTimeout, const Duration(seconds: 10));
    // The shared Dio instance should log network activity through AppLogger.
    expect(dio.interceptors.whereType<DioLoggingInterceptor>(), hasLength(1));
    // Auth + refresh + error normalization are shared for all API calls.
    expect(dio.interceptors.whereType<ErrorInterceptor>(), hasLength(1));
  });
}

class _FakeAppLogger implements AppLogger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}
}
