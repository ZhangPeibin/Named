import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/network/api_exception.dart';

void main() {
  test('maps timeout errors to ApiException', () async {
    // Timeout errors do not have an HTTP response, so they should be classified
    // by DioExceptionType instead of status code.
    final apiException = ApiException.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/users'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(apiException.type, ApiExceptionType.timeout);
    expect(apiException.message, 'Request timeout');
  });

  test('maps not found responses with message payloads', () async {
    // Backend error payloads commonly expose a message field; preserve it for UI
    // and logging layers instead of showing a generic HTTP message.
    final apiException = ApiException.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/users'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/users'),
          statusCode: 404,
          data: {'message': 'User not found'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(apiException.type, ApiExceptionType.notFound);
    expect(apiException.message, 'User not found');
    expect(apiException.statusCode, 404);
    expect(apiException.data, {'message': 'User not found'});
  });

  test('maps problem+json detail and code', () {
    final apiException = ApiException.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/auth/verify'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/auth/verify'),
          statusCode: 400,
          data: {
            'type': 'about:blank',
            'title': 'Invalid Code',
            'status': 400,
            'detail': 'The code is invalid or has expired.',
            'code': 'invalid_code',
            'request_id': 'req-1',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(apiException.message, 'The code is invalid or has expired.');
    expect(apiException.code, 'invalid_code');
    expect(apiException.statusCode, 400);
  });

  test('maps HTTP status codes to specific exception types', () {
    // Status-code categories allow callers to handle auth, missing resources,
    // and server failures differently.
    expect(_badResponse(400).type, ApiExceptionType.badResponse);
    expect(_badResponse(401).type, ApiExceptionType.unauthorized);
    expect(_badResponse(403).type, ApiExceptionType.forbidden);
    expect(_badResponse(404).type, ApiExceptionType.notFound);
    expect(_badResponse(500).type, ApiExceptionType.server);
    expect(_badResponse(503).type, ApiExceptionType.server);
  });
}

ApiException _badResponse(int statusCode) {
  // Build only the DioException shape needed by the mapper; no HTTP request is
  // performed in these tests.
  return ApiException.fromDioException(
    DioException(
      requestOptions: RequestOptions(path: '/users'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/users'),
        statusCode: statusCode,
      ),
      type: DioExceptionType.badResponse,
    ),
  );
}
