import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

final class ArchitectureViolation {
  const ArchitectureViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line: $message';
}

Future<List<ArchitectureViolation>> findArchitectureViolations(
  Directory projectRoot,
) async {
  final root = projectRoot.absolute;
  final violations = <ArchitectureViolation>[];

  for (final unsupportedPlatform in const [
    'linux',
    'macos',
    'web',
    'windows',
  ]) {
    if (Directory('${root.path}/$unsupportedPlatform').existsSync()) {
      violations.add(
        ArchitectureViolation(
          path: unsupportedPlatform,
          line: 1,
          message: 'This template supports Android and iOS only.',
        ),
      );
    }
  }

  final libDirectory = Directory('${root.path}/lib');
  if (!libDirectory.existsSync()) {
    return violations;
  }

  final packageName = _readPackageName(File('${root.path}/pubspec.yaml'));
  await for (final entity in libDirectory.list(recursive: true)) {
    if (entity is! File ||
        !entity.path.endsWith('.dart') ||
        entity.path.endsWith('.g.dart')) {
      continue;
    }

    final relativePath = _relativePath(root, entity);
    final parseResult = parseString(
      content: await entity.readAsString(),
      path: entity.path,
      throwIfDiagnostics: false,
    );
    final checker = _ArchitectureVisitor(
      filePath: relativePath,
      packageName: packageName,
      lineInfo: parseResult.lineInfo,
      violations: violations,
    );
    parseResult.unit.accept(checker);
  }

  violations.sort((left, right) {
    final pathComparison = left.path.compareTo(right.path);
    return pathComparison != 0
        ? pathComparison
        : left.line.compareTo(right.line);
  });
  return violations;
}

Future<void> main() async {
  final violations = await findArchitectureViolations(Directory.current);
  if (violations.isEmpty) {
    stdout.writeln('Architecture check passed.');
    return;
  }

  stderr.writeln('Architecture check failed:');
  for (final violation in violations) {
    stderr.writeln('  $violation');
  }
  exitCode = 1;
}

final class _ArchitectureVisitor extends RecursiveAstVisitor<void> {
  _ArchitectureVisitor({
    required this.filePath,
    required this.packageName,
    required this.lineInfo,
    required this.violations,
  });

  final String filePath;
  final String packageName;
  final LineInfo lineInfo;
  final List<ArchitectureViolation> violations;

  bool get _isDomain => filePath.contains('/domain/');
  bool get _isData => filePath.contains('/data/');
  bool get _isPresentation => filePath.contains('/presentation/');

  @override
  void visitImportDirective(ImportDirective node) {
    _checkDependency(node.uri.stringValue, node.offset);
    super.visitImportDirective(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _checkDependency(node.uri.stringValue, node.offset);
    super.visitExportDirective(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target?.toSource();
    if (node.methodName.name == 'fromEnvironment' &&
        (target == 'String' || target == 'bool') &&
        !filePath.startsWith('lib/core/config/')) {
      _add(
        node.offset,
        'Compile-time environment values may only be read in '
        'lib/core/config/.',
      );
    }
    super.visitMethodInvocation(node);
  }

  void _checkDependency(String? uri, int offset) {
    if (uri == null) {
      return;
    }

    final targetPath = _resolveInternalPath(uri);
    final isFlutter =
        uri.startsWith('package:flutter/') ||
        uri.startsWith('package:flutter_') ||
        uri == 'package:flutter_riverpod/flutter_riverpod.dart';

    if (_isDomain &&
        (isFlutter ||
            uri.startsWith('package:dio/') ||
            _targetsLayer(targetPath, 'data') ||
            _targetsLayer(targetPath, 'presentation') ||
            _targetsLayer(targetPath, 'providers'))) {
      _add(
        offset,
        'Domain code must remain framework-independent and may not depend '
        'on data, presentation, or providers.',
      );
    }

    if (_isData && _targetsLayer(targetPath, 'presentation')) {
      _add(offset, 'Data code may not depend on presentation code.');
    }

    if (_isPresentation &&
        (uri.startsWith('package:dio/') ||
            uri.startsWith('package:shared_preferences/') ||
            uri.startsWith('package:flutter_secure_storage/'))) {
      _add(
        offset,
        'Presentation code must access infrastructure through an '
        'abstraction or provider.',
      );
    }

    if (uri.startsWith('package:logger/') &&
        !filePath.startsWith('lib/core/logging/')) {
      _add(offset, 'package:logger is restricted to lib/core/logging/.');
    }

    if (uri.startsWith('package:toastification/') &&
        filePath != 'lib/app/app.dart' &&
        !filePath.startsWith('lib/core/feedback/')) {
      _add(
        offset,
        'package:toastification is restricted to the feedback adapter.',
      );
    }

    if (uri.startsWith('package:flutter_secure_storage/') &&
        filePath != 'lib/core/storage/flutter_secure_storage_adapter.dart') {
      _add(
        offset,
        'package:flutter_secure_storage is restricted to its adapter.',
      );
    }

    if (uri.startsWith('package:shared_preferences/') &&
        !const {
          'lib/main.dart',
          'lib/core/providers/key_value_storage_provider.dart',
          'lib/core/storage/shared_preferences_key_value_storage.dart',
        }.contains(filePath)) {
      _add(
        offset,
        'package:shared_preferences is restricted to bootstrap, its '
        'provider, and its adapter.',
      );
    }
  }

  String? _resolveInternalPath(String uri) {
    if (uri.startsWith('package:$packageName/')) {
      return 'lib/${uri.substring('package:$packageName/'.length)}';
    }
    if (uri.startsWith('package:') || uri.startsWith('dart:')) {
      return null;
    }

    final baseUri = Uri.file('/$filePath');
    return baseUri.resolve(uri).path.substring(1);
  }

  bool _targetsLayer(String? path, String layer) =>
      path != null && path.split('/').contains(layer);

  void _add(int offset, String message) {
    violations.add(
      ArchitectureViolation(
        path: filePath,
        line: lineInfo.getLocation(offset).lineNumber,
        message: message,
      ),
    );
  }
}

String _readPackageName(File pubspec) {
  if (!pubspec.existsSync()) {
    return '';
  }
  final match = RegExp(
    r'^name:\s*([a-zA-Z0-9_]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  return match?.group(1) ?? '';
}

String _relativePath(Directory root, File file) {
  final rootPath = root.absolute.path;
  return file.absolute.path.substring(rootPath.length + 1);
}
