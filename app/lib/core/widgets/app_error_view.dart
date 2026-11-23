import 'package:flutter/material.dart';

import 'app_button.dart';
import 'app_empty_view.dart';
import 'app_line_icon.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyView(
      icon: AppLineGlyph.error,
      iconColor: Theme.of(context).colorScheme.error,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Try again',
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: onRetry,
            ),
    );
  }
}
