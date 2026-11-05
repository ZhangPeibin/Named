import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/network/api_envelope.dart';
import 'package:named/core/network/api_exception.dart';

void main() {
  test('unwraps successful envelope data', () {
    final data = unwrapApiData(
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/x'),
        data: {
          'code': 0,
          'message': 'ok',
          'data': {'id': 1},
        },
      ),
    );

    expect(data, {'id': 1});
  });

  test('throws ApiException when business code is non-zero', () {
    expect(
      () => unwrapApiData(
        Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/x'),
          data: {'code': 10001, 'message': 'invalid', 'data': null},
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 10001)
            .having((e) => e.message, 'message', 'invalid'),
      ),
    );
  });

  test('returns empty map when data is absent on success', () {
    final data = unwrapApiData(
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/x'),
        data: {'code': 0, 'message': 'ok'},
      ),
    );

    expect(data, isEmpty);
  });
}
