class SensitiveDataRedactor {
  const SensitiveDataRedactor._();

  static const replacement = '[REDACTED]';
  static final _sensitiveKey = RegExp(
    r'(authorization|token|password|passwd|secret|api[-_]?key|otp|code)',
    caseSensitive: false,
  );

  static Uri uri(Uri uri) {
    if (!uri.hasQuery && uri.userInfo.isEmpty) {
      return uri;
    }

    final parameters = <String, String>{};
    uri.queryParameters.forEach((key, value) {
      parameters[key] = _sensitiveKey.hasMatch(key) ? replacement : value;
    });

    return uri.replace(
      userInfo: uri.userInfo.isEmpty ? null : 'redacted',
      queryParameters: parameters.isEmpty ? null : parameters,
    );
  }
}
