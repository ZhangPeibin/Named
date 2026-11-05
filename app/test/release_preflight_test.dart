import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/release_preflight.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('release-preflight-');
    _writeValidProject(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('accepts a valid common production configuration', () {
    final failures = ReleasePreflight(root: root, environment: const {})
        .validate(
          configPath: 'config/prod.json',
          platform: ReleasePlatform.common,
        );

    expect(failures, isEmpty);
  });

  test('reports all unsafe production configuration values', () {
    _writeJson(root, 'config/prod.json', {
      'APP_NAME': 'Flutter Template',
      'APP_ENV': 'dev',
      'API_BASE_URL': 'http://api.example.com',
      'USE_MOCK_API': true,
      'REFRESH_TOKEN_PATH': 'refresh',
      'APP_VERSION_CHECK_PATH': '',
      'WEBVIEW_ALLOWED_HOSTS': 'example.com',
    });
    _write(root, 'pubspec.yaml', 'name: named\n');

    final failures = ReleasePreflight(root: root, environment: const {})
        .validate(
          configPath: 'config/prod.json',
          platform: ReleasePlatform.common,
        );

    expect(failures, hasLength(greaterThanOrEqualTo(7)));
    expect(failures.any((value) => value.contains('APP_ENV')), isTrue);
    expect(failures.any((value) => value.contains('USE_MOCK_API')), isTrue);
    expect(failures.any((value) => value.contains('HTTPS')), isTrue);
    expect(failures.any((value) => value.contains('template')), isTrue);
  });

  test('checks Android signing and the keystore path', () {
    final failures =
        ReleasePreflight(
          root: root,
          environment: const {'ANDROID_KEYSTORE_PATH': '/missing/release.jks'},
        ).validate(
          configPath: 'config/prod.json',
          platform: ReleasePlatform.android,
        );

    expect(
      failures.where((value) => value.contains('signing variable')),
      hasLength(3),
    );
    expect(failures.any((value) => value.contains('existing file')), isTrue);
  });

  test('checks iOS team and strict export options', () {
    _write(
      root,
      'ios/Runner.xcodeproj/project.pbxproj',
      'Release-prod\nPRODUCT_BUNDLE_IDENTIFIER = com.acme.app;\n',
    );

    final failures = ReleasePreflight(root: root, environment: const {})
        .validate(
          configPath: 'config/prod.json',
          platform: ReleasePlatform.ios,
          requireIosExportOptions: true,
        );

    expect(failures.any((value) => value.contains('Development Team')), isTrue);
    expect(failures.any((value) => value.contains('ExportOptions')), isTrue);
  });
}

void _writeValidProject(Directory root) {
  _writeJson(root, 'config/prod.json', {
    'APP_NAME': 'Sample App',
    'APP_ENV': 'prod',
    'API_BASE_URL': 'https://api.acme.test',
    'USE_MOCK_API': false,
    'REFRESH_TOKEN_PATH': '/api/auth/refresh',
    'APP_VERSION_CHECK_PATH': '/api/app/version',
    'WEBVIEW_ALLOWED_HOSTS': 'www.acme.test,help.acme.test',
  });
  _write(root, 'pubspec.yaml', 'name: sample_app\n');
  _write(
    root,
    'android/app/build.gradle.kts',
    'applicationId = "com.acme.sample"\n',
  );
  _write(
    root,
    'android/app/src/main/AndroidManifest.xml',
    '<uses-permission android:name="android.permission.INTERNET" />\n',
  );
  _write(
    root,
    'ios/Runner.xcodeproj/project.pbxproj',
    'Release-prod\n'
        'DEVELOPMENT_TEAM = ABC123;\n'
        'PRODUCT_BUNDLE_IDENTIFIER = com.acme.sample;\n',
  );
  _write(
    root,
    'ios/Runner.xcodeproj/xcshareddata/xcschemes/prod.xcscheme',
    '<Scheme />\n',
  );
}

void _writeJson(Directory root, String path, Map<String, Object?> value) {
  _write(root, path, const JsonEncoder.withIndent('  ').convert(value));
}

void _write(Directory root, String path, String content) {
  final file = File('${root.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}
