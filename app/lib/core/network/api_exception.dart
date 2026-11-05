import 'package:dio/dio.dart';

enum ApiExceptionType {
  network,
  timeout,
  badResponse,
  unauthorized,
  forbidden,
  notFound,
  server,
  cancelled,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.code,
    this.data,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final String? code;
  final Object? data;

  factory ApiException.fromDioException(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException(
        type: ApiExceptionType.timeout,
        message: 'Request timeout',
      ),
      DioExceptionType.connectionError => const ApiException(
        type: ApiExceptionType.network,
        message: 'Network connection failed',
      ),
      DioExceptionType.badResponse => ApiException(
        type: _typeFromStatusCode(error.response?.statusCode),
        message: _responseMessage(error.response),
        statusCode: error.response?.statusCode,
        code: _responseCode(error.response),
        data: error.response?.data,
      ),
      DioExceptionType.cancel => const ApiException(
        type: ApiExceptionType.cancelled,
        message: 'Request was cancelled',
      ),
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown => ApiException(
        type: ApiExceptionType.unknown,
        message: error.message ?? 'Unexpected network error',
      ),
    };
  }

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (status: $statusCode)';
    return 'ApiException.${type.name}: $message$code';
  }

  static String _responseMessage(Response<dynamic>? response) {
    final data = response?.data;

    if (data case {'detail': final String detail}) {
      return detail;
    }

    if (data case {'message': final String message}) {
      return message;
    }

    if (data case {'error': final String message}) {
      return message;
    }

    return response?.statusMessage ?? 'Request failed';
  }

  static String? _responseCode(Response<dynamic>? response) {
    final data = response?.data;
    if (data case {'code': final String code}) {
      return code;
    }
    return null;
  }

  static ApiExceptionType _typeFromStatusCode(int? statusCode) {
    if (statusCode == null) {
      return ApiExceptionType.badResponse;
    }

    if (statusCode >= 500 && statusCode < 600) {
      return ApiExceptionType.server;
    }

    return switch (statusCode) {
      401 => ApiExceptionType.unauthorized,
      403 => ApiExceptionType.forbidden,
      404 => ApiExceptionType.notFound,
      _ => ApiExceptionType.badResponse,
    };
  }
}
