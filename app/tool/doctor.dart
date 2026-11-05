import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final checkRelease = arguments.contains('--release');
  final failures = <String>[];
  final warnings = <String>[];

  const requiredPaths = [
    'android/app/build.gradle.kts',
    'ios/Runner.xcodeproj/project.pbxproj',
    'config/dev.json',
    'config/staging.json',
    'config/prod.example.json',
    '.templateignore',
    '.fvmrc',
  ];
  for (final path in requiredPaths) {
    if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
      failures.add('Missing required file: $path');
    }
  }

  for (final unsupportedPlatform in ['web', 'windows', 'linux', 'macos']) {
    if (Directory(unsupportedPlatform).existsSync()) {
      failures.add(
        'Unsupported platform directory exists: $unsupportedPlatform/',
      );
    }
  }

  if (!File('config/prod.json').existsSync()) {
    warnings.add(
      'config/prod.json is missing; run make bootstrap before prod.',
    );
  }

  _checkFlutterVersion(failures, warnings);

  if (checkRelease) {
    const signingVariables = [
      'ANDROID_KEYSTORE_PATH',
      'ANDROID_KEYSTORE_PASS',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASS',
    ];
    for (final variable in signingVariables) {
      if ((Platform.environment[variable] ?? '').isEmpty) {
        failures.add('Missing Android release signing variable: $variable');
      }
    }
  }

  for (final warning in warnings) {
    stdout.writeln('WARN: $warning');
  }
  for (final failure in failures) {
    stderr.writeln('FAIL: $failure');
  }

  if (failures.isNotEmpty) {
    exitCode = 1;
    return;
  }
  stdout.writeln('Template doctor passed.');
}

void _checkFlutterVersion(List<String> failures, List<String> warnings) {
  try {
    final fvm = jsonDecode(File('.fvmrc').readAsStringSync());
    final expected = (fvm as Map<String, dynamic>)['flutter'] as String;
    final result = Process.runSync('flutter', ['--version', '--machine']);
    if (result.exitCode != 0) {
      warnings.add('Could not read Flutter version.');
      return;
    }
    final actual =
        (jsonDecode(result.stdout as String)
                as Map<String, dynamic>)['frameworkVersion']
            as String;
    if (actual != expected) {
      warnings.add('Flutter $actual is active; template recommends $expected.');
    }
  } on Object catch (error) {
    failures.add('Invalid toolchain configuration: $error');
  }
}
