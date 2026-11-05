import 'dart:io';

/// Scaffolds a new feature under `lib/features/<name>/` following the layered
/// architecture enforced by `tool/architecture_check.dart`.
///
/// Usage:
///   dart run tool/new_feature.dart my_feature
///   dart run tool/new_feature.dart my_feature --ui-only
///
/// The generated code is a compile-ready starting point full of `TODO`
/// markers. It is the constructive counterpart to the architecture checker:
/// the checker rejects the wrong shape, this generator produces the right one.
void main(List<String> args) {
  _ensureProjectRoot();

  final options = _Options.parse(args);
  if (options.help) {
    stdout.writeln(_usage);
    return;
  }
  if (options.name == null) {
    stderr
      ..writeln('Missing feature name.')
      ..writeln()
      ..writeln(_usage);
    exitCode = 64;
    return;
  }

  final name = options.name!;
  _validateName(name);

  final featureDir = Directory('lib/features/$name');
  if (featureDir.existsSync()) {
    stderr.writeln('Feature already exists: ${featureDir.path}');
    exitCode = 65;
    return;
  }

  final tokens = _Tokens.fromSnake(name);
  final files = options.uiOnly ? _uiOnlyFiles(tokens) : _fullSliceFiles(tokens);

  for (final entry in files.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(_render(entry.value, tokens));
    stdout.writeln('  created ${file.path}');
  }

  // Normalize output with dart format so it is always format-clean regardless
  // of how long the feature name is.
  _formatFiles(files.keys.toList());

  stdout
    ..writeln()
    ..writeln('Feature "$name" scaffolded.')
    ..writeln()
    ..writeln('Next steps:')
    ..writeln('  1. Add a route in lib/app/router/app_router.dart:')
    ..writeln(
      "       static const ${tokens.camel} = '/$name';  "
      '// in AppRoutePaths',
    )
    ..writeln(
      "       static const ${tokens.camel} = '${tokens.camel}';  "
      '// in AppRouteNames',
    )
    ..writeln('       GoRoute(')
    ..writeln('         path: AppRoutePaths.${tokens.camel},')
    ..writeln('         name: AppRouteNames.${tokens.camel},')
    ..writeln(
      '         builder: (context, state) => '
      'const ${tokens.pascal}Page(),',
    )
    ..writeln('       )')
    ..writeln(
      '  2. Move user-visible strings into lib/i18n/*.i18n.json, '
      'then run: make gen',
    )
    ..writeln('  3. Fill in the TODO markers, then run: make check');
}

const _usage = '''
Scaffold a new feature under lib/features/<name>/.

Usage:
  dart run tool/new_feature.dart <feature_name> [--ui-only]

Arguments:
  <feature_name>   snake_case name, e.g. user_profile

Options:
  --ui-only        Generate only a presentation page (no data/domain layers).
  -h, --help       Show this help.
''';

class _Options {
  const _Options({this.name, this.uiOnly = false, this.help = false});

  factory _Options.parse(List<String> args) {
    String? name;
    var uiOnly = false;
    var help = false;
    for (final arg in args) {
      switch (arg) {
        case '-h' || '--help':
          help = true;
        case '--ui-only':
          uiOnly = true;
        default:
          if (arg.startsWith('-')) {
            stderr.writeln('Unknown option: $arg');
            exitCode = 64;
          } else {
            name ??= arg;
          }
      }
    }
    return _Options(name: name, uiOnly: uiOnly, help: help);
  }

  final String? name;
  final bool uiOnly;
  final bool help;
}

class _Tokens {
  const _Tokens({
    required this.snake,
    required this.pascal,
    required this.camel,
  });

  factory _Tokens.fromSnake(String snake) {
    final parts = snake.split('_').where((part) => part.isNotEmpty).toList();
    final pascal = parts.map(_capitalize).join();
    final camel = pascal.isEmpty
        ? pascal
        : pascal[0].toLowerCase() + pascal.substring(1);
    return _Tokens(snake: snake, pascal: pascal, camel: camel);
  }

  final String snake;
  final String pascal;
  final String camel;
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

String _render(String template, _Tokens tokens) => template
    .replaceAll('__PASCAL__', tokens.pascal)
    .replaceAll('__CAMEL__', tokens.camel)
    .replaceAll('__SNAKE__', tokens.snake);

Map<String, String> _fullSliceFiles(_Tokens t) => {
  'lib/features/${t.snake}/domain/${t.snake}.dart': _domainTemplate,
  'lib/features/${t.snake}/data/dto/${t.snake}_dto.dart': _dtoTemplate,
  'lib/features/${t.snake}/data/api/${t.snake}_api.dart': _apiTemplate,
  'lib/features/${t.snake}/data/repositories/${t.snake}_repository.dart':
      _repositoryTemplate,
  'lib/features/${t.snake}/providers/${t.snake}_providers.dart':
      _providersTemplate,
  'lib/features/${t.snake}/presentation/${t.snake}_page.dart': _pageTemplate,
};

Map<String, String> _uiOnlyFiles(_Tokens t) => {
  'lib/features/${t.snake}/presentation/${t.snake}_page.dart':
      _uiOnlyPageTemplate,
};

void _formatFiles(List<String> paths) {
  final executable = Platform.resolvedExecutable;
  // Only shell out when running under the Dart CLI. Under `flutter test` the
  // resolved executable is flutter_tester, which must not be invoked here.
  if (!executable.endsWith('${Platform.pathSeparator}dart') &&
      !executable.endsWith('${Platform.pathSeparator}dart.exe')) {
    return;
  }
  final result = Process.runSync(executable, ['format', ...paths]);
  if (result.exitCode != 0) {
    stderr.writeln('Warning: dart format failed:\n${result.stderr}');
  }
}

void _validateName(String name) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    stderr.writeln(
      'Feature name must be snake_case (lowercase, digits, underscores) '
      'and start with a letter. Received: "$name".',
    );
    exitCode = 64;
    exit(64);
  }
}

void _ensureProjectRoot() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync() || !pubspec.readAsStringSync().contains('name:')) {
    stderr.writeln('Run this from the project root (pubspec.yaml not found).');
    exitCode = 64;
    exit(64);
  }
}

const _domainTemplate = r'''
/// Domain entity for the __SNAKE__ feature.
///
/// Keep this framework-independent: no Flutter, Riverpod, Dio, or imports from
/// data/, presentation/, or providers/ (enforced by tool/architecture_check).
class __PASCAL__ {
  const __PASCAL__({required this.id});

  final String id;
}
''';

const _dtoTemplate = r'''
import '../../domain/__SNAKE__.dart';

/// Data-transfer object for [__PASCAL__]. Serialization lives here so the
/// domain entity stays free of parsing concerns.
class __PASCAL__Dto {
  const __PASCAL__Dto({required this.id});

  factory __PASCAL__Dto.fromJson(Map<String, dynamic> json) {
    // TODO(__SNAKE__): map the real fields from the API payload.
    return __PASCAL__Dto(id: json['id'] as String);
  }

  final String id;

  __PASCAL__ toDomain() => __PASCAL__(id: id);
}
''';

const _apiTemplate = r'''
import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../dto/__SNAKE___dto.dart';

abstract class __PASCAL__Api {
  Future<__PASCAL__Dto> fetch__PASCAL__();
}

class Remote__PASCAL__Api implements __PASCAL__Api {
  const Remote__PASCAL__Api(this._dio);

  final Dio _dio;

  @override
  Future<__PASCAL__Dto> fetch__PASCAL__() async {
    try {
      // TODO(__SNAKE__): replace with the real endpoint path.
      final response = await _dio.get<Map<String, dynamic>>('/__SNAKE__');
      final data = response.data;
      if (data == null) {
        throw const ApiException(
          type: ApiExceptionType.badResponse,
          message: '__PASCAL__ response was empty',
        );
      }
      return __PASCAL__Dto.fromJson(data);
    } on DioException catch (error) {
      // Convert transport failures into a stable application error at the
      // boundary — never let DioException leak into providers/presentation.
      final apiException = error.error;
      if (apiException is ApiException) {
        throw apiException;
      }
      throw ApiException.fromDioException(error);
    }
  }
}
''';

const _repositoryTemplate = r'''
import '../../domain/__SNAKE__.dart';
import '../api/__SNAKE___api.dart';

class __PASCAL__Repository {
  const __PASCAL__Repository(this._api);

  final __PASCAL__Api _api;

  Future<__PASCAL__> fetch__PASCAL__() async {
    final dto = await _api.fetch__PASCAL__();
    return dto.toDomain();
  }
}
''';

const _providersTemplate = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/dio_provider.dart';
import '../data/api/__SNAKE___api.dart';
import '../data/repositories/__SNAKE___repository.dart';
import '../domain/__SNAKE__.dart';

final __CAMEL__ApiProvider = Provider<__PASCAL__Api>((ref) {
  return Remote__PASCAL__Api(ref.watch(dioProvider));
});

final __CAMEL__RepositoryProvider = Provider<__PASCAL__Repository>((ref) {
  return __PASCAL__Repository(ref.watch(__CAMEL__ApiProvider));
});

final __CAMEL__Provider = FutureProvider.autoDispose<__PASCAL__>((ref) {
  return ref.watch(__CAMEL__RepositoryProvider).fetch__PASCAL__();
});
''';

const _pageTemplate = r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../providers/__SNAKE___providers.dart';

class __PASCAL__Page extends ConsumerWidget {
  const __PASCAL__Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final __CAMEL__ = ref.watch(__CAMEL__Provider);

    // TODO(__SNAKE__): move the title into lib/i18n/*.i18n.json, run make gen.
    return AppScaffold(
      title: '__PASCAL__',
      body: AppAsyncView(
        value: __CAMEL__,
        data: (__CAMEL__) => Text('__PASCAL__: ${__CAMEL__.id}'),
      ),
    );
  }
}
''';

const _uiOnlyPageTemplate = r'''
import 'package:flutter/material.dart';

import '../../../core/widgets/app_scaffold.dart';

class __PASCAL__Page extends StatelessWidget {
  const __PASCAL__Page({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(__SNAKE__): move the title into lib/i18n/*.i18n.json, run make gen.
    return const AppScaffold(
      title: '__PASCAL__',
      body: Text('__PASCAL__'),
    );
  }
}
''';
