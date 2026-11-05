import 'dart:io';

const _oldProjectName = 'flutter_template';
const _oldDisplayName = 'Flutter Template';
const _oldAndroidPackage = 'com.example.flutter_template';
const _oldIosBundleId = 'com.example.flutterTemplate';
const _oldTokens = [
  _oldProjectName,
  _oldDisplayName,
  _oldAndroidPackage,
  _oldIosBundleId,
  'com.example.flutterTemplate.RunnerTests',
];

void main(List<String> args) {
  _ensureProjectRoot();

  final options = _Options.parse(args);

  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  if (!options.isValid) {
    stderr
      ..writeln('Missing or invalid arguments.')
      ..writeln()
      ..writeln(_usage);
    exitCode = 64;
    return;
  }

  final projectName = options.requiredValue('project-name');
  final displayName = options.requiredValue('display-name');
  final androidPackage = options.requiredValue('android-package');
  final iosBundleId =
      options.value('ios-bundle-id') ?? _iosBundleIdFrom(androidPackage);

  _validateProjectName(projectName);
  _validateAndroidPackage(androidPackage);
  _validateIosBundleId(iosBundleId);
  _validateNewValuesDoNotContainOldTokens([
    projectName,
    displayName,
    androidPackage,
    iosBundleId,
  ]);

  final replacements = [
    MapEntry(
      'com.example.flutterTemplate.RunnerTests',
      '$iosBundleId.RunnerTests',
    ),
    MapEntry(_oldAndroidPackage, androidPackage),
    MapEntry(_oldIosBundleId, iosBundleId),
    MapEntry(_oldDisplayName, displayName),
    MapEntry(_oldProjectName, projectName),
  ];

  final files = <String>{
    'pubspec.yaml',
    'README.md',
    'README.zh-CN.md',
    '.vscode/launch.json',
    'config/dev.json',
    'config/staging.json',
    'config/prod.example.json',
    'config/prod.json',
    'lib/i18n/en.i18n.json',
    'lib/i18n/zh.i18n.json',
    'android/app/build.gradle.kts',
    'android/app/src/main/AndroidManifest.xml',
    'ios/Runner/Info.plist',
    'ios/Runner.xcodeproj/project.pbxproj',
    ..._textFilesIn('ios/Flutter', extension: '.xcconfig'),
    ..._textFilesIn('tool', extension: '.rb'),
    ..._dartFilesIn(['lib', 'test', 'integration_test']),
  };

  for (final path in files) {
    _replaceInFile(path, replacements);
  }

  final oldMainActivity = File(
    'android/app/src/main/kotlin/com/example/flutter_template/MainActivity.kt',
  );
  final newMainActivity = File(
    'android/app/src/main/kotlin/${androidPackage.replaceAll('.', '/')}/MainActivity.kt',
  );

  if (oldMainActivity.existsSync()) {
    _replaceInFile(oldMainActivity.path, [
      MapEntry(_oldAndroidPackage, androidPackage),
    ]);
    newMainActivity.parent.createSync(recursive: true);
    oldMainActivity.renameSync(newMainActivity.path);
    _deleteEmptyParents(
      Directory('android/app/src/main/kotlin/com/example/flutter_template'),
    );
  } else if (newMainActivity.existsSync()) {
    _replaceInFile(newMainActivity.path, [
      MapEntry(_oldAndroidPackage, androidPackage),
    ]);
  } else {
    stderr.writeln('Warning: MainActivity.kt was not found.');
  }

  _deleteIfExists(Directory('.idea'));
  _deleteIfExists(Directory('android/.idea'));
  _replaceTemplateModuleFiles(projectName);

  stdout
    ..writeln('Project template renamed.')
    ..writeln('Project name: $projectName')
    ..writeln('Display name: $displayName')
    ..writeln('Android package: $androidPackage')
    ..writeln('iOS bundle ID: $iosBundleId')
    ..writeln()
    ..writeln('Next steps:')
    ..writeln('  flutter clean')
    ..writeln('  flutter pub get')
    ..writeln('  dart run slang')
    ..writeln('  Reopen the project root in Android Studio');
}

void _ensureProjectRoot() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    _fail(
      'pubspec.yaml was not found. Run this script from the Flutter project root.',
    );
  }
}

void _replaceInFile(
  String path,
  Iterable<MapEntry<String, String>> replacements,
) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Warning: $path was not found.');
    return;
  }

  var content = file.readAsStringSync();
  for (final entry in replacements) {
    content = content.replaceAll(entry.key, entry.value);
  }
  file.writeAsStringSync(content);
}

void _deleteIfExists(FileSystemEntity entity) {
  if (entity.existsSync()) {
    entity.deleteSync(recursive: true);
  }
}

void _replaceTemplateModuleFiles(String projectName) {
  _renameOrCreateRootModuleFile(projectName);
  _renameOrCreateAndroidModuleFile(projectName);
}

void _renameOrCreateRootModuleFile(String projectName) {
  final oldFile = File('$_oldProjectName.iml');
  final newFile = File('$projectName.iml');

  if (oldFile.existsSync()) {
    oldFile.renameSync(newFile.path);
    return;
  }

  if (!newFile.existsSync()) {
    newFile.writeAsStringSync(_rootModuleFile);
  }
}

void _renameOrCreateAndroidModuleFile(String projectName) {
  final oldFile = File('android/${_oldProjectName}_android.iml');
  final newFile = File('android/${projectName}_android.iml');

  if (oldFile.existsSync()) {
    oldFile.renameSync(newFile.path);
    return;
  }

  if (!newFile.existsSync()) {
    newFile.writeAsStringSync(_androidModuleFile);
  }
}

void _deleteEmptyParents(Directory directory) {
  var current = directory;
  final stopAt = Directory('android/app/src/main/kotlin').absolute.path;

  while (current.absolute.path.startsWith(stopAt) &&
      current.absolute.path != stopAt) {
    if (!current.existsSync()) {
      current = current.parent;
      continue;
    }

    if (current.listSync().isNotEmpty) {
      return;
    }

    current.deleteSync();
    current = current.parent;
  }
}

Iterable<String> _dartFilesIn(List<String> directories) sync* {
  for (final path in directories) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      continue;
    }

    yield* directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.path);
  }
}

Iterable<String> _textFilesIn(
  String directoryPath, {
  required String extension,
}) sync* {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    return;
  }

  yield* directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith(extension))
      .map((file) => file.path);
}

String _iosBundleIdFrom(String androidPackage) {
  return androidPackage
      .split('.')
      .map((part) => part.replaceAll('_', '-'))
      .join('.');
}

void _validateProjectName(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
    _fail(
      'project-name must be a valid Dart package name, for example my_app.',
    );
  }
}

void _validateAndroidPackage(String value) {
  final segment = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
  final parts = value.split('.');

  if (parts.length < 2 || parts.any((part) => !segment.hasMatch(part))) {
    _fail(
      'android-package must be a valid Android package, for example com.example.my_app.',
    );
  }
}

void _validateIosBundleId(String value) {
  final segment = RegExp(r'^[A-Za-z0-9-]+$');
  final parts = value.split('.');

  if (parts.length < 2 || parts.any((part) => !segment.hasMatch(part))) {
    _fail('ios-bundle-id must use only letters, numbers, hyphens, and dots.');
  }
}

void _validateNewValuesDoNotContainOldTokens(List<String> values) {
  for (final value in values) {
    for (final token in _oldTokens) {
      if (value.contains(token)) {
        _fail('New values must not contain the old template token "$token".');
      }
    }
  }
}

void _fail(String message) {
  stderr.writeln(message);
  exit(64);
}

class _Options {
  const _Options(this.values, this.help);

  factory _Options.parse(List<String> args) {
    final values = <String, String>{};
    var help = false;

    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index];

      if (arg == '--help' || arg == '-h') {
        help = true;
        continue;
      }

      if (!arg.startsWith('--')) {
        continue;
      }

      final equalsIndex = arg.indexOf('=');
      if (equalsIndex > 2) {
        values[arg.substring(2, equalsIndex)] = arg.substring(equalsIndex + 1);
        continue;
      }

      final key = arg.substring(2);
      if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
        values[key] = args[index + 1];
        index += 1;
      }
    }

    return _Options(values, help);
  }

  final Map<String, String> values;
  final bool help;

  bool get isValid =>
      values.containsKey('project-name') &&
      values.containsKey('display-name') &&
      values.containsKey('android-package');

  String? value(String key) => values[key];

  String requiredValue(String key) => values[key]!;
}

const _usage = '''
Usage:
  dart run tool/setup_project.dart \\
    --project-name my_app \\
    --display-name "My App" \\
    --android-package com.example.my_app \\
    --ios-bundle-id com.example.my-app

Options:
  --project-name      Dart package name in pubspec.yaml, for example my_app.
  --display-name      App name shown on Android launcher and iOS Home Screen.
  --android-package   Android namespace and applicationId.
  --ios-bundle-id     Optional. Defaults to android-package with underscores changed to hyphens.
''';

const _rootModuleFile = '''
<?xml version="1.0" encoding="UTF-8"?>
<module type="JAVA_MODULE" version="4">
  <component name="NewModuleRootManager" inherit-compiler-output="true">
    <exclude-output />
    <content url="file://\$MODULE_DIR\$">
      <excludeFolder url="file://\$MODULE_DIR\$/.dart_tool" />
      <excludeFolder url="file://\$MODULE_DIR\$/.pub" />
      <excludeFolder url="file://\$MODULE_DIR\$/build" />
    </content>
    <orderEntry type="sourceFolder" forTests="false" />
    <orderEntry type="library" name="Dart SDK" level="project" />
    <orderEntry type="library" name="Dart Packages" level="project" />
    <orderEntry type="library" name="Flutter Plugins" level="project" />
  </component>
</module>
''';

const _androidModuleFile = '''
<?xml version="1.0" encoding="UTF-8"?>
<module type="JAVA_MODULE" version="4">
  <component name="FacetManager">
    <facet type="android" name="Android">
      <configuration>
        <option name="ALLOW_USER_CONFIGURATION" value="false" />
        <option name="GEN_FOLDER_RELATIVE_PATH_APT" value="/gen" />
        <option name="GEN_FOLDER_RELATIVE_PATH_AIDL" value="/gen" />
        <option name="MANIFEST_FILE_RELATIVE_PATH" value="/app/src/main/AndroidManifest.xml" />
        <option name="RES_FOLDER_RELATIVE_PATH" value="/app/src/main/res" />
        <option name="ASSETS_FOLDER_RELATIVE_PATH" value="/app/src/main/assets" />
        <option name="LIBS_FOLDER_RELATIVE_PATH" value="/app/src/main/libs" />
        <option name="PROGUARD_LOGS_FOLDER_RELATIVE_PATH" value="/app/src/main/proguard_logs" />
      </configuration>
    </facet>
  </component>
  <component name="NewModuleRootManager" inherit-compiler-output="true">
    <exclude-output />
    <content url="file://\$MODULE_DIR\$">
      <sourceFolder url="file://\$MODULE_DIR\$/app/src/main/java" isTestSource="false" />
      <sourceFolder url="file://\$MODULE_DIR\$/app/src/main/kotlin" isTestSource="false" />
      <sourceFolder url="file://\$MODULE_DIR\$/gen" isTestSource="false" generated="true" />
    </content>
    <orderEntry type="jdk" jdkName="Android API 24 Platform" jdkType="Android SDK" />
    <orderEntry type="sourceFolder" forTests="false" />
    <orderEntry type="library" name="Flutter for Android" level="project" />
    <orderEntry type="library" name="KotlinJavaRuntime" level="project" />
  </component>
</module>
''';
