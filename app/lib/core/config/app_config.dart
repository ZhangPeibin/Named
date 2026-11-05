enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment parse(String value) {
    return switch (value) {
      'dev' => AppEnvironment.dev,
      'staging' => AppEnvironment.staging,
      'prod' => AppEnvironment.prod,
      _ => throw FormatException(
        'APP_ENV must be one of: dev, staging, prod. Received: "$value".',
      ),
    };
  }
}

class AppConfig {
  const AppConfig({
    required this.appName,
    required this.environment,
    required this.apiBaseUrl,
    this.useMockApi = false,
    this.refreshTokenPath = '/api/v1/auth/refresh',
    this.appVersionCheckPath = '/api/v1/app/version/check',
    this.webViewAllowedHosts = const {'example.com', 'www.example.com'},
  });

  AppConfig.fromEnvironment()
    : this(
        appName: const String.fromEnvironment(
          'APP_NAME',
          defaultValue: 'Named',
        ),
        environment: AppEnvironment.parse(
          const String.fromEnvironment('APP_ENV'),
        ),
        apiBaseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.example.com',
        ),
        useMockApi: const bool.fromEnvironment('USE_MOCK_API'),
        refreshTokenPath: const String.fromEnvironment(
          'REFRESH_TOKEN_PATH',
          defaultValue: '/api/v1/auth/refresh',
        ),
        appVersionCheckPath: const String.fromEnvironment(
          'APP_VERSION_CHECK_PATH',
          defaultValue: '/api/v1/app/version/check',
        ),
        webViewAllowedHosts: _parseHosts(
          const String.fromEnvironment(
            'WEBVIEW_ALLOWED_HOSTS',
            defaultValue: 'example.com,www.example.com',
          ),
        ),
      );

  final String appName;
  final AppEnvironment environment;
  final String apiBaseUrl;

  /// When true, demo features use local mock data instead of remote APIs.
  final bool useMockApi;

  /// Relative path used by the injected token refresh client.
  final String refreshTokenPath;

  /// Relative path for app version check.
  final String appVersionCheckPath;

  /// Host allowlist for in-app WebView navigation.
  final Set<String> webViewAllowedHosts;

  bool get isProduction => environment == AppEnvironment.prod;

  static Set<String> _parseHosts(String raw) {
    return raw
        .split(',')
        .map((host) => host.trim().toLowerCase())
        .where((host) => host.isNotEmpty)
        .toSet();
  }
}
