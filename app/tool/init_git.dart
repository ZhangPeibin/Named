import 'dart:io';

void main(List<String> args) {
  _ensureProjectRoot();

  final options = _Options.parse(args);

  if (options.help) {
    stdout.writeln(_usage);
    return;
  }

  if (Directory('.git').existsSync()) {
    _fail(
      'Git is already initialized in this project. '
      'If this was copied from the template, remove the copied .git directory first.',
    );
  }

  _run('git', ['init']);

  if (options.initialBranch != null) {
    _run('git', ['branch', '-M', options.initialBranch!]);
  }

  if (options.commit) {
    _run('git', ['add', '.']);
    _run('git', ['commit', '-m', options.message]);
  }

  stdout
    ..writeln('Git repository initialized.')
    ..writeln('Initial branch: ${options.initialBranch ?? _currentBranch()}')
    ..writeln()
    ..writeln('Next steps:')
    ..writeln('  git status')
    ..writeln('  git remote add origin <repo-url>');
}

void _ensureProjectRoot() {
  if (!File('pubspec.yaml').existsSync()) {
    _fail(
      'pubspec.yaml was not found. Run this script from the Flutter project root.',
    );
  }
}

void _run(String executable, List<String> arguments) {
  final result = Process.runSync(executable, arguments);

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}

String _currentBranch() {
  final result = Process.runSync('git', ['branch', '--show-current']);

  if (result.exitCode == 0) {
    final branch = result.stdout.toString().trim();
    if (branch.isNotEmpty) {
      return branch;
    }
  }

  return 'default';
}

void _fail(String message) {
  stderr.writeln(message);
  exit(64);
}

class _Options {
  const _Options({
    required this.help,
    required this.commit,
    required this.message,
    required this.initialBranch,
  });

  factory _Options.parse(List<String> args) {
    var help = false;
    var commit = false;
    var message = 'Initial commit';
    String? initialBranch = 'main';

    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index];

      if (arg == '--help' || arg == '-h') {
        help = true;
        continue;
      }

      if (arg == '--commit') {
        commit = true;
        continue;
      }

      if (arg == '--no-branch') {
        initialBranch = null;
        continue;
      }

      if (arg.startsWith('--branch=')) {
        initialBranch = arg.substring('--branch='.length);
        continue;
      }

      if (arg == '--branch' && index + 1 < args.length) {
        initialBranch = args[index + 1];
        index += 1;
        continue;
      }

      if (arg.startsWith('--message=')) {
        message = arg.substring('--message='.length);
        continue;
      }

      if (arg == '--message' && index + 1 < args.length) {
        message = args[index + 1];
        index += 1;
      }
    }

    if (initialBranch != null &&
        !RegExp(r'^[A-Za-z0-9._/-]+$').hasMatch(initialBranch)) {
      _fail(
        'branch must contain only letters, numbers, dots, underscores, slashes, or hyphens.',
      );
    }

    if (message.trim().isEmpty) {
      _fail('message must not be empty.');
    }

    return _Options(
      help: help,
      commit: commit,
      message: message,
      initialBranch: initialBranch,
    );
  }

  final bool help;
  final bool commit;
  final String message;
  final String? initialBranch;
}

const _usage = '''
Usage:
  dart run tool/init_git.dart [options]

Options:
  --branch main              Initial branch name. Defaults to main.
  --no-branch                Keep Git's default initial branch.
  --commit                   Create the first commit after git init.
  --message "Initial commit" Commit message used with --commit.
''';
