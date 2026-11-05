import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/refresh_token_interceptor.dart';

/// Default refresh client used by [RefreshTokenInterceptor].
///
/// Expects `POST {refreshPath}` with body `{ "refreshToken": "..." }` and a
/// JSON response containing `accessToken` (and optional `refreshToken`).
/// Replace this in product apps if your envelope differs.
class TokenRefreshClient {
  const TokenRefreshClient({required Dio dio, required String refreshPath})
    : _dio = dio,
      _refreshPath = refreshPath;

  final Dio _dio;
  final String _refreshPath;

  Future<RefreshedTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _refreshPath,
      data: {'refreshToken': refreshToken},
    );
    final data = response.data ?? const <String, dynamic>{};
    final accessToken = data['accessToken'] as String?;
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw StateError('Refresh response missing accessToken');
    }
    return (
      accessToken: accessToken,
      refreshToken: data['refreshToken'] as String?,
    );
  }
}

/// Dev-only refresh that accepts the fake tokens written by Dev Sign In.
class DevTokenRefreshClient {
  const DevTokenRefreshClient();

  Future<RefreshedTokens> refresh(String refreshToken) async {
    if (refreshToken.trim().isEmpty) {
      throw StateError('Missing refresh token');
    }
    return (
      accessToken: 'dev-refreshed-access-token',
      refreshToken: refreshToken,
    );
  }
}

RefreshTokens buildRefreshTokens({
  required AppConfig config,
  required Dio refreshDio,
}) {
  if (config.useMockApi) {
    return const DevTokenRefreshClient().refresh;
  }
  return TokenRefreshClient(
    dio: refreshDio,
    refreshPath: config.refreshTokenPath,
  ).refresh;
}
