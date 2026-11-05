import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/architecture_check.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('architecture-check-test-');
    await File(
      '${root.path}/pubspec.yaml',
    ).writeAsString('name: example_app\n');
  });

  tearDown(() => root.delete(recursive: true));

  test('accepts dependencies that follow the layer boundaries', () async {
    await _write(
      root,
      'lib/features/todo/domain/todo.dart',
      "import 'dart:convert';\nclass Todo {}\n",
    );
    await _write(
      root,
      'lib/features/todo/data/todo_repository.dart',
      "import '../domain/todo.dart';\n",
    );

    expect(await findArchitectureViolations(root), isEmpty);
  });

  test('rejects domain dependencies on frameworks and outer layers', () async {
    await _write(
      root,
      'lib/features/todo/domain/todo.dart',
      "import 'package:flutter/material.dart';\n"
          "export '../data/todo_repository.dart';\n",
    );

    final violations = await findArchitectureViolations(root);

    expect(violations, hasLength(2));
    expect(
      violations.map((violation) => violation.message),
      everyElement(contains('Domain code')),
    );
  });

  test('rejects infrastructure packages outside their adapters', () async {
    await _write(
      root,
      'lib/features/settings/presentation/page.dart',
      "import 'package:shared_preferences/shared_preferences.dart';\n"
          "import 'package:logger/logger.dart';\n",
    );

    final violations = await findArchitectureViolations(root);

    expect(violations, hasLength(3));
  });

  test('restricts environment reads and unsupported platforms', () async {
    await Directory('${root.path}/web').create();
    await _write(
      root,
      'lib/features/home/data/environment.dart',
      "const value = String.fromEnvironment('VALUE');\n",
    );

    final violations = await findArchitectureViolations(root);

    expect(violations, hasLength(2));
    expect(
      violations.map((violation) => violation.path),
      containsAll(['lib/features/home/data/environment.dart', 'web']),
    );
  });
}

Future<void> _write(Directory root, String path, String contents) async {
  final file = File('${root.path}/$path');
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}
