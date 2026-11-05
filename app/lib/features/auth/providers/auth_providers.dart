import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_info_service.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/device_info_interceptor.dart';
import '../../../core/network/dio_logging_interceptor.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/providers/error_interceptor_provider.dart';
import '../../../core/providers/key_value_storage_provider.dart';
import '../../../core/providers/logger_provider.dart';
import '../../../core/providers/secure_storage_provider.dart';
import '../data/auth_api.dart';
import '../data/pending_soul_repository.dart';

/// Auth endpoints do not use the refresh interceptor. Named sessions are
/// extended by the server and use a single opaque token.
final authDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final logger = ref.watch(loggerProvider);
  final errorInterceptor = ref.watch(errorInterceptorProvider);

  final deviceInfoService = DeviceInfoService(
    secureStorage: secureStorage,
    config: config,
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );

  dio.interceptors
    ..add(DeviceInfoInterceptor(deviceInfoService))
    ..add(AuthInterceptor(secureStorage))
    ..add(errorInterceptor)
    ..add(DioLoggingInterceptor(logger));

  return dio;
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(authDioProvider));
});

final pendingSoulRepositoryProvider = Provider<PendingSoulRepository>((ref) {
  return PendingSoulRepository(ref.watch(keyValueStorageProvider));
});
