import 'dart:convert';
import 'dart:io';

enum ReleasePlatform { common, android, ios }

void main(List<String> arguments) {
  final options = _Options.parse(arguments);
  final failures =
      ReleasePreflight(
        root: Directory.current,
        environment: Platform.environment,
      ).validate(
        configPath: options.configPath,
        platform: options.platform,
        requireIosExportOptions: options.requireIosExportOptions,
      );

  if (failures.isEmpty) {
    stdout.writeln('Release preflight passed.');
    return;
  }

  stderr.writeln('Release preflight failed:\n');
  for (final failure in failures) {
    stderr.writeln('- $failure');
  }
  stderr.writeln('\nBuild was not started.');
  exitCode = 1;
}

class ReleasePreflight {
  const ReleasePreflight({required this.root, required this.environment});

  final Directory root;
  final Map<String, String> environment;

  List<String> validate({
    required String configPath,
    required ReleasePlatform platform,
    bool requireIosExportOptions = false,
  }) {
    final failures = <String>[];
    final config = _readConfig(configPath, failures);
    if (config != null) {
      _validateConfig(config, failures);
    }
    _validateTemplateIdentity(failures);

    switch (platform) {
      case ReleasePlatform.common:
        break;
      case ReleasePlatform.android:
        _validateAndroid(failures);
      case ReleasePlatform.ios:
        _validateIos(failures, requireExportOptions: requireIosExportOptions);
    }

    return failures;
  }

  Map<String, Object?>? _readConfig(String configPath, List<String> failures) {
    final file = _file(configPath);
    if (!file.existsSync()) {
      failures.add('Production config does not exist: $configPath');
      return null;
    }

    try {
      final value = jsonDecode(file.readAsStringSync());
      if (value is! Map<String, Object?>) {
        failures.add('Production config must contain a JSON object.');
        return null;
      }
      return value;
    } on FormatException catch (error) {
      failures.add('Production config is invalid JSON: ${error.message}');
      return null;
    }
  }

  void _validateConfig(Map<String, Object?> config, List<String> failures) {
    final appName = _requiredString(config, 'APP_NAME', failures);
    final appEnvironment = _requiredString(config, 'APP_ENV', failures);
    final apiBaseUrl = _requiredString(config, 'API_BASE_URL', failures);
    final refreshPath = _requiredString(config, 'REFRESH_TOKEN_PATH', failures);
    final versionPath = _requiredString(
      config,
      'APP_VERSION_CHECK_PATH',
      failures,
    );
    final allowedHosts = _requiredString(
      config,
      'WEBVIEW_ALLOWED_HOSTS',
      failures,
    );

    if (appName != null && _containsTemplateValue(appName)) {
      failures.add('APP_NAME still contains a template placeholder.');
    }
    if (appEnvironment != null && appEnvironment != 'prod') {
      failures.add('APP_ENV must be "prod" for a production build.');
    }

    if (config['USE_MOCK_API'] is! bool) {
      failures.add('USE_MOCK_API must be an explicit boolean.');
    } else if (config['USE_MOCK_API'] == true) {
      failures.add('USE_MOCK_API must be false for a production build.');
    }

    if (apiBaseUrl != null) {
      final uri = Uri.tryParse(apiBaseUrl);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        failures.add('API_BASE_URL must be an absolute HTTPS URL.');
      } else if (_isPlaceholderHost(uri.host)) {
        failures.add('API_BASE_URL still uses a placeholder host.');
      }
    }

    for (final entry in {
      'REFRESH_TOKEN_PATH': refreshPath,
      'APP_VERSION_CHECK_PATH': versionPath,
    }.entries) {
      final value = entry.value;
      if (value != null && !value.startsWith('/')) {
        failures.add('${entry.key} must start with "/".');
      }
    }

    if (allowedHosts != null) {
      final hosts = allowedHosts
          .split(',')
          .map((host) => host.trim().toLowerCase())
          .where((host) => host.isNotEmpty)
          .toList();
      if (hosts.isEmpty || hosts.any(_isPlaceholderHost)) {
        failures.add(
          'WEBVIEW_ALLOWED_HOSTS must contain explicit production hosts.',
        );
      }
    }
  }

  void _validateTemplateIdentity(List<String> failures) {
    const checks = {
      'pubspec.yaml': ['name: flutter_template'],
      'android/app/build.gradle.kts': ['com.example.flutter_template'],
      'ios/Runner.xcodeproj/project.pbxproj': ['com.example.flutterTemplate'],
    };

    for (final entry in checks.entries) {
      final file = _file(entry.key);
      if (!file.existsSync()) {
        failures.add('Missing release project file: ${entry.key}');
        continue;
      }
      final content = file.readAsStringSync();
      if (entry.value.any(content.contains)) {
        failures.add('${entry.key} still contains a template identifier.');
      }
    }
  }

  void _validateAndroid(List<String> failures) {
    const signingVariables = [
      'ANDROID_KEYSTORE_PATH',
      'ANDROID_KEYSTORE_PASS',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASS',
    ];
    for (final variable in signingVariables) {
      if ((environment[variable] ?? '').trim().isEmpty) {
        failures.add('Missing Android release signing variable: $variable');
      }
    }

    final keystorePath = environment['ANDROID_KEYSTORE_PATH'];
    if (keystorePath != null &&
        keystorePath.trim().isNotEmpty &&
        !File(keystorePath).existsSync()) {
      failures.add('ANDROID_KEYSTORE_PATH does not point to an existing file.');
    }

    final manifest = _file('android/app/src/main/AndroidManifest.xml');
    if (!manifest.existsSync() ||
        !manifest.readAsStringSync().contains('android.permission.INTERNET')) {
      failures.add(
        'Main AndroidManifest.xml must declare INTERNET permission.',
      );
    }
  }

  void _validateIos(
    List<String> failures, {
    required bool requireExportOptions,
  }) {
    if (!_file(
      'ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme',
    ).existsSync()) {
      failures.add('The shared iOS prod scheme is missing.');
    }

    final project = _file('ios/Runner.xcodeproj/project.pbxproj');
    if (project.existsSync()) {
      final content = project.readAsStringSync();
      if (!content.contains('Release-prod')) {
        failures.add('The iOS Release-prod configuration is missing.');
      }
      if (!RegExp(r'DEVELOPMENT_TEAM = [^;]+;').hasMatch(content)) {
        failures.add('The iOS Development Team is not configured.');
      }
    }

    if (requireExportOptions &&
        !_file('ios/ExportOptions.plist').existsSync()) {
      failures.add(
        'ios/ExportOptions.plist is required for strict iOS export.',
      );
    }
  }

  String? _requiredString(
    Map<String, Object?> config,
    String key,
    List<String> failures,
  ) {
    final value = config[key];
    if (value is! String || value.trim().isEmpty) {
      failures.add('$key must be a non-empty string.');
      return null;
    }
    return value.trim();
  }

  bool _containsTemplateValue(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('flutter template') ||
        normalized.contains('flutter_template');
  }

  bool _isPlaceholderHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'example.com' ||
        normalized.endsWith('.example.com') ||
        normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0';
  }

  File _file(String path) => File('${root.path}/$path');
}

class _Options {
  const _Options({
    required this.configPath,
    required this.platform,
    required this.requireIosExportOptions,
  });

  factory _Options.parse(List<String> arguments) {
    var configPath = 'config/prod.json';
    var platform = ReleasePlatform.common;
    var requireIosExportOptions = false;

    for (final argument in arguments) {
      if (argument.startsWith('--config=')) {
        configPath = argument.substring('--config='.length);
      } else if (argument.startsWith('--platform=')) {
        final value = argument.substring('--platform='.length);
        platform = switch (value) {
          'common' => ReleasePlatform.common,
          'android' => ReleasePlatform.android,
          'ios' => ReleasePlatform.ios,
          _ => throw FormatException('Unknown release platform: $value'),
        };
      } else if (argument == '--require-ios-export-options') {
        requireIosExportOptions = true;
      } else {
        throw FormatException('Unknown argument: $argument');
      }
    }

    return _Options(
      configPath: configPath,
      platform: platform,
      requireIosExportOptions: requireIosExportOptions,
    );
  }

  final String configPath;
  final ReleasePlatform platform;
  final bool requireIosExportOptions;
}
