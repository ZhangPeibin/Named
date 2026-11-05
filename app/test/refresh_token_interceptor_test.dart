import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/logging/app_logger.dart';
import 'package:named/core/network/refresh_token_interceptor.dart';
import 'package:named/core/storage/secure_storage.dart';
import 'package:named/core/storage/storage_keys.dart';

void main() {
  test('refresh interceptor retries once after 401', () async {
    final storage = _MemorySecureStorage()
      ..writeSync(StorageKeys.accessToken, 'old-access')
      ..writeSync(StorageKeys.refreshToken, 'refresh-token');

    final adapter = _SequenceAdapter([
      _AdapterResult.status(401),
      _AdapterResult.json(200, '{"ok":true}'),
    ]);

    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = adapter;

    dio.interceptors.add(
      RefreshTokenInterceptor(
        dio: dio,
        secureStorage: storage,
        logger: _FakeLogger(),
        refreshPath: '/auth/refresh',
        refreshTokens: (refreshToken) async {
          expect(refreshToken, 'refresh-token');
          return (accessToken: 'new-access', refreshToken: 'refresh-token');
        },
      ),
    );

    final response = await dio.get<Map<String, dynamic>>('/secure');
    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(await storage.read(StorageKeys.accessToken), 'new-access');
    expect(adapter.requestCount, 2);
  });
}

class _AdapterResult {
  const _AdapterResult._({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  factory _AdapterResult.status(int statusCode) {
    return _AdapterResult._(
      statusCode: statusCode,
      body: '{}',
      headers: const {},
    );
  }

  factory _AdapterResult.json(int statusCode, String body) {
    return _AdapterResult._(
      statusCode: statusCode,
      body: body,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
}

class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this._results);

  final List<_AdapterResult> _results;
  var requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = requestCount;
    requestCount += 1;
    final result = _results[index];
    return ResponseBody.fromString(
      result.body,
      result.statusCode,
      headers: result.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> _values = {};

  void writeSync(String key, String value) {
    _values[key] = value;
  }

  @override
  Future<bool> contains(String key) async => _values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _values.clear();
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class _FakeLogger implements AppLogger {
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}
}
