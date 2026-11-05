import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import '../logging/sensitive_data_redactor.dart';

class DioLoggingInterceptor extends Interceptor {
  const DioLoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug(
      '${options.method} ${SensitiveDataRedactor.uri(options.uri)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug(
      '${response.requestOptions.method} '
      '${SensitiveDataRedactor.uri(response.requestOptions.uri)} '
      '-> ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.error(
      '${err.requestOptions.method} '
      '${SensitiveDataRedactor.uri(err.requestOptions.uri)} failed',
      error: err.error ?? err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}
