import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/token_refresh_client.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../device/device_info_service.dart';
import '../network/auth_interceptor.dart';
import '../network/device_info_interceptor.dart';
import '../network/dio_logging_interceptor.dart';
import '../network/error_interceptor.dart';
import '../network/refresh_token_interceptor.dart';
import 'app_config_provider.dart';
import 'logger_provider.dart';
import 'secure_storage_provider.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService(
    secureStorage: ref.watch(secureStorageProvider),
    config: ref.watch(appConfigProvider),
  );
});

final errorInterceptorProvider = Provider<ErrorInterceptor>((ref) {
  return ErrorInterceptor();
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(loggerProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final deviceInfoService = ref.watch(deviceInfoServiceProvider);
  final errorInterceptor = ref.watch(errorInterceptorProvider);

  final baseOptions = BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    headers: const {Headers.acceptHeader: Headers.jsonContentType},
  );

  final dio = Dio(baseOptions);
  final refreshDio = Dio(baseOptions);

  dio.interceptors
    ..add(DeviceInfoInterceptor(deviceInfoService))
    ..add(AuthInterceptor(secureStorage))
    ..add(
      RefreshTokenInterceptor(
        dio: dio,
        secureStorage: secureStorage,
        logger: logger,
        refreshPath: config.refreshTokenPath,
        refreshTokens: buildRefreshTokens(
          config: config,
          refreshDio: refreshDio,
        ),
        onRefreshFailed: () async {
          await ref.read(authNotifierProvider.notifier).handleSessionExpired();
        },
      ),
    )
    ..add(errorInterceptor)
    ..add(DioLoggingInterceptor(logger));

  refreshDio.interceptors
    ..add(DeviceInfoInterceptor(deviceInfoService))
    ..add(errorInterceptor)
    ..add(DioLoggingInterceptor(logger));

  return dio;
});
