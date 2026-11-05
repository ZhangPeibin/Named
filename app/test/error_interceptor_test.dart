import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/network/api_exception.dart';
import 'package:named/core/network/error_interceptor.dart';

void main() {
  group('ErrorInterceptor', () {
    late ErrorInterceptor interceptor;

    setUp(() {
      interceptor = ErrorInterceptor();
      interceptor.suppressGlobalErrorToastsForTesting = true;
    });

    test('wraps DioException with ApiException', () {
      late DioException captured;

      interceptor.onError(
        DioException(
          requestOptions: RequestOptions(path: '/users'),
          type: DioExceptionType.connectionError,
        ),
        _CapturingErrorHandler((error) => captured = error),
      );

      expect(captured.error, isA<ApiException>());
      expect((captured.error! as ApiException).type, ApiExceptionType.network);
    });

    test('locks repeated global fault toasts until a success response', () {
      final networkError = DioException(
        requestOptions: RequestOptions(path: '/users'),
        type: DioExceptionType.connectionError,
      );

      interceptor.onError(networkError, _NoOpErrorHandler());
      expect(
        interceptor.activeGlobalErrorTypeForTesting,
        ApiExceptionType.network,
      );

      interceptor.onError(networkError, _NoOpErrorHandler());
      expect(
        interceptor.activeGlobalErrorTypeForTesting,
        ApiExceptionType.network,
      );

      interceptor.onResponse(
        Response<dynamic>(
          requestOptions: RequestOptions(path: '/users'),
          statusCode: 200,
        ),
        _NoOpResponseHandler(),
      );
      expect(interceptor.activeGlobalErrorTypeForTesting, isNull);
    });
  });
}

class _CapturingErrorHandler extends ErrorInterceptorHandler {
  _CapturingErrorHandler(this._onNext);

  final void Function(DioException error) _onNext;

  @override
  void next(DioException err) {
    _onNext(err);
  }
}

class _NoOpErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}

class _NoOpResponseHandler extends ResponseInterceptorHandler {
  @override
  void next(Response<dynamic> response) {}
}
