import 'dart:io';

Future<void> main() async {
  final projectRoot = Directory.current.absolute;
  final packageConfig = File(
    '${projectRoot.path}/.dart_tool/package_config.json',
  );
  if (!packageConfig.existsSync()) {
    stderr.writeln('Run flutter pub get before checking generated code.');
    exitCode = 1;
    return;
  }

  final temporaryRoot = await Directory.systemTemp.createTemp(
    'flutter-template-generated-check-',
  );
  try {
    await _copyFile(
      File('${projectRoot.path}/pubspec.yaml'),
      File('${temporaryRoot.path}/pubspec.yaml'),
    );
    final slangConfig = File('${projectRoot.path}/slang.yaml');
    if (slangConfig.existsSync()) {
      await _copyFile(slangConfig, File('${temporaryRoot.path}/slang.yaml'));
    }
    await _copyDirectory(
      Directory('${projectRoot.path}/lib/i18n'),
      Directory('${temporaryRoot.path}/lib/i18n'),
    );
    await Link(
      '${temporaryRoot.path}/.dart_tool',
    ).create('${projectRoot.path}/.dart_tool');

    final result = await Process.run(Platform.resolvedExecutable, const [
      'run',
      'slang',
    ], workingDirectory: temporaryRoot.path);
    if (result.exitCode != 0) {
      stderr.write(result.stdout);
      stderr.write(result.stderr);
      exitCode = result.exitCode;
      return;
    }

    final differences = await _findGeneratedDifferences(
      Directory('${projectRoot.path}/lib/i18n'),
      Directory('${temporaryRoot.path}/lib/i18n'),
    );
    if (differences.isNotEmpty) {
      stderr.writeln('Generated translations are out of date:');
      for (final difference in differences) {
        stderr.writeln('  $difference');
      }
      stderr.writeln('Run `make gen` and commit the generated files.');
      exitCode = 1;
      return;
    }

    stdout.writeln('Generated translation check passed.');
  } finally {
    await temporaryRoot.delete(recursive: true);
  }
}

Future<List<String>> _findGeneratedDifferences(
  Directory current,
  Directory generated,
) async {
  final currentFiles = await _generatedFiles(current);
  final generatedFiles = await _generatedFiles(generated);
  final paths = {...currentFiles.keys, ...generatedFiles.keys}.toList()..sort();
  final differences = <String>[];

  for (final path in paths) {
    final currentFile = currentFiles[path];
    final generatedFile = generatedFiles[path];
    if (currentFile == null) {
      differences.add('$path is missing');
    } else if (generatedFile == null) {
      differences.add('$path is obsolete');
    } else if (!_sameBytes(
      await currentFile.readAsBytes(),
      await generatedFile.readAsBytes(),
    )) {
      differences.add('$path has changed');
    }
  }
  return differences;
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

Future<Map<String, File>> _generatedFiles(Directory directory) async {
  final files = <String, File>{};
  if (!directory.existsSync()) {
    return files;
  }
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.g.dart')) {
      files[_pathWithin(directory, entity)] = entity;
    }
  }
  return files;
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: true)) {
    final relative = _pathWithin(source, entity);
    if (entity is Directory) {
      await Directory('${destination.path}/$relative').create(recursive: true);
    } else if (entity is File) {
      await _copyFile(entity, File('${destination.path}/$relative'));
    }
  }
}

Future<void> _copyFile(File source, File destination) async {
  await destination.parent.create(recursive: true);
  await source.copy(destination.path);
}

String _pathWithin(Directory root, FileSystemEntity entity) =>
    entity.absolute.path.substring(root.absolute.path.length + 1);
