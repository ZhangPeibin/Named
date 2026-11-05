import 'dart:async';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';

/// Result of a successful token refresh.
typedef RefreshedTokens = ({String accessToken, String? refreshToken});

/// Injected refresh call — path and response parsing stay outside this class.
typedef RefreshTokens = Future<RefreshedTokens> Function(String refreshToken);

/// Retries a failed request once after refreshing the access token.
///
/// Refresh path / parsing are injected via [refreshTokens] so business apps can
/// plug in their own API without hardcoding product endpoints here.
class RefreshTokenInterceptor extends QueuedInterceptor {
  RefreshTokenInterceptor({
    required Dio dio,
    required SecureStorage secureStorage,
    required AppLogger logger,
    required String refreshPath,
    required RefreshTokens refreshTokens,
    Future<void> Function()? onRefreshFailed,
  }) : _dio = dio,
       _secureStorage = secureStorage,
       _logger = logger,
       _refreshPath = refreshPath,
       _refreshTokens = refreshTokens,
       _onRefreshFailed = onRefreshFailed;

  final Dio _dio;
  final SecureStorage _secureStorage;
  final AppLogger _logger;
  final String _refreshPath;
  final RefreshTokens _refreshTokens;
  final Future<void> Function()? _onRefreshFailed;

  static const _retriedKey = '_refresh_token_retried';

  // Instance state — must share lifetime with the Dio instance passed to the
  // constructor. Do not invalidate dioProvider mid-flight; a Dio rebuild would
  // drop an in-progress refresh and leave queued requests waiting forever.
  Completer<String?>? _refreshing;
  Future<void>? _sessionExpiredFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      await _handleSessionExpiredOnce();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions.copyWith(
        extra: {...err.requestOptions.extra, _retriedKey: true},
      );
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (error, stackTrace) {
      _logger.warning(
        'Retry after token refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      handler.next(err);
    }
  }

  bool _shouldRefresh(DioException err) {
    final requestOptions = err.requestOptions;
    return err.response?.statusCode == 401 &&
        requestOptions.path != _refreshPath &&
        requestOptions.extra[_retriedKey] != true;
  }

  Future<String?> _refreshAccessToken() {
    final inflight = _refreshing;
    if (inflight != null) {
      return inflight.future;
    }

    final completer = Completer<String?>();
    _refreshing = completer;

    unawaited(
      _doRefresh()
          .then(completer.complete)
          .catchError((Object error, StackTrace stackTrace) {
            _logger.warning(
              'Refresh access token failed',
              error: error,
              stackTrace: stackTrace,
            );
            completer.complete(null);
          })
          .whenComplete(() => _refreshing = null),
    );

    return completer.future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      _logger.warning('Refresh aborted: no refresh token in storage');
      return null;
    }

    _logger.info('Refreshing access token');
    final tokens = await _refreshTokens(refreshToken);
    await _secureStorage.write(StorageKeys.accessToken, tokens.accessToken);
    final nextRefresh = tokens.refreshToken;
    if (nextRefresh != null && nextRefresh.trim().isNotEmpty) {
      await _secureStorage.write(StorageKeys.refreshToken, nextRefresh);
    }
    _logger.info('Access token refreshed');
    return tokens.accessToken;
  }

  Future<void> _handleSessionExpiredOnce() {
    final inflight = _sessionExpiredFuture;
    if (inflight != null) {
      return inflight;
    }

    final future = _handleSessionExpired().whenComplete(() {
      _sessionExpiredFuture = null;
    });
    _sessionExpiredFuture = future;
    return future;
  }

  Future<void> _handleSessionExpired() async {
    _logger.warning('Session expired: clearing auth tokens');
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);

    final callback = _onRefreshFailed;
    if (callback == null) {
      return;
    }

    try {
      await callback();
    } catch (error, stackTrace) {
      _logger.warning(
        'onRefreshFailed callback threw',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
