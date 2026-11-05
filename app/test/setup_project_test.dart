import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/setup_project.dart' as setup;

void main() {
  test('setup project replaces Android, iOS, config, and i18n branding', () {
    final root = Directory.systemTemp.createTempSync('flutter-template-setup-');
    addTearDown(() => root.deleteSync(recursive: true));
    _writeFixture(root);
    final originalDirectory = Directory.current;
    try {
      Directory.current = root;
      setup.main([
        '--project-name',
        'sample_app',
        '--display-name',
        'Sample App',
        '--android-package',
        'com.acme.sample',
        '--ios-bundle-id',
        'com.acme.sample',
      ]);
    } finally {
      Directory.current = originalDirectory;
    }
    expect(
      File('${root.path}/pubspec.yaml').readAsStringSync(),
      contains('sample_app'),
    );
    expect(
      File('${root.path}/lib/i18n/en.i18n.json').readAsStringSync(),
      contains('Sample App'),
    );
    expect(
      File('${root.path}/config/prod.json').readAsStringSync(),
      contains('Sample App'),
    );
    expect(
      File(
        '${root.path}/ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync(),
      contains('com.acme.sample'),
    );
    expect(
      File(
        '${root.path}/android/app/src/main/kotlin/com/acme/sample/MainActivity.kt',
      ).existsSync(),
      isTrue,
    );

    const oldTokens = [
      'flutter_template',
      'Flutter Template',
      'com.example.flutter_template',
      'com.example.flutterTemplate',
    ];
    final textFiles = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => !file.path.endsWith('.iml'));
    for (final file in textFiles) {
      final content = file.readAsStringSync();
      for (final token in oldTokens) {
        expect(content, isNot(contains(token)), reason: file.path);
      }
    }
  });
}

void _writeFixture(Directory root) {
  final files = <String, String>{
    'pubspec.yaml': 'name: flutter_template\n',
    'README.md': '# Flutter Template\n',
    'README.zh-CN.md': '# Flutter Template\n',
    '.vscode/launch.json': '{"name":"flutter_template"}\n',
    'config/dev.json': '{"APP_NAME":"Flutter Template"}\n',
    'config/staging.json': '{"APP_NAME":"Flutter Template"}\n',
    'config/prod.example.json': '{"APP_NAME":"Flutter Template"}\n',
    'config/prod.json': '{"APP_NAME":"Flutter Template"}\n',
    'lib/i18n/en.i18n.json': '{"app":{"name":"Flutter Template"}}\n',
    'lib/i18n/zh.i18n.json': '{"app":{"name":"Flutter Template"}}\n',
    'lib/main.dart': "import 'package:flutter_template/app.dart';\n",
    'test/widget_test.dart': "import 'package:flutter_template/app.dart';\n",
    'integration_test/app_test.dart':
        "import 'package:flutter_template/main.dart';\n",
    'android/app/build.gradle.kts':
        'namespace = "com.example.flutter_template"\n'
        'applicationId = "com.example.flutter_template"\n'
        'resValue("string", "app_name", "Flutter Template")\n',
    'android/app/src/main/AndroidManifest.xml':
        '<application android:label="Flutter Template" />\n',
    'android/app/src/main/kotlin/com/example/flutter_template/MainActivity.kt':
        'package com.example.flutter_template\n',
    'ios/Runner/Info.plist': '<string>Flutter Template</string>\n',
    'ios/Runner.xcodeproj/project.pbxproj':
        'PRODUCT_BUNDLE_IDENTIFIER = com.example.flutterTemplate;\n',
    'ios/Flutter/Debug.xcconfig': 'APP_DISPLAY_NAME=Flutter Template\n',
    'tool/configure_ios_flavors.rb':
        "bundle = 'com.example.flutterTemplate'\nname = 'Flutter Template'\n",
  };

  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key}');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
  }
}
