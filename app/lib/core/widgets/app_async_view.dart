import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import 'app_error_view.dart';
import 'app_loading_view.dart';

/// Renders the three states of an [AsyncValue] using [AppLoadingView],
/// [AppErrorView], and a caller-supplied data builder.
///
/// ```dart
/// AppAsyncView(
///   value: ref.watch(myProvider),
///   data: (item) => Text(item.name),
/// )
/// ```
class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Override the default [AppLoadingView].
  final Widget? loading;

  /// Override the default [AppErrorView].
  final Widget Function(Object error, StackTrace? stack)? error;

  @override
  Widget build(BuildContext context) {
    final t = context.t.common;

    return value.when(
      loading: () => loading ?? const AppLoadingView(),
      error: (err, stack) =>
          error?.call(err, stack) ??
          AppErrorView(title: t.somethingWentWrong, message: t.pleaseTryAgain),
      data: data,
    );
  }
}
