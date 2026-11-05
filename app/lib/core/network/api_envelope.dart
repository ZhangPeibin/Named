import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Unwraps a `{code, message, data}` response envelope.
///
/// Convention: `code == 0` means success. Returns the inner `data` map (or an
/// empty map when `data` is null/non-object). Throws [ApiException] when the
/// body is missing or `code != 0`.
///
/// Product apps with a different envelope should replace this helper (or pass
/// a custom parser into repositories) instead of changing call sites ad hoc.
/// The business `code` is stored in [ApiException.statusCode] for callers that
/// want to map it to UI copy.
Map<String, dynamic> unwrapApiData(Response<Map<String, dynamic>> response) {
  final body = response.data;
  if (body == null) {
    throw const ApiException(
      type: ApiExceptionType.badResponse,
      message: 'Empty response body',
    );
  }

  final code = body['code'];
  if (code is int && code != 0) {
    throw ApiException(
      type: ApiExceptionType.badResponse,
      message: (body['message'] as String?) ?? 'Request failed',
      statusCode: code,
      data: body['data'],
    );
  }

  final data = body['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }
  return const <String, dynamic>{};
}
