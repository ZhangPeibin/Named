import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../i18n/strings.g.dart';

/// A confirmation dialog with a title, optional description, and
/// confirm / cancel actions.
///
/// Use [showAppConfirmDialog] to display it and await the result:
/// ```dart
/// final confirmed = await showAppConfirmDialog(
///   context: context,
///   title: 'Delete item',
///   message: 'This action cannot be undone.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
/// if (confirmed == true) { ... }
/// ```
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.isDestructive = false,
  });

  final String title;
  final String? message;
  final String? confirmLabel;
  final String? cancelLabel;

  /// Tints the confirm button with the error colour.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final t = context.t.common;
    final colorScheme = Theme.of(context).colorScheme;
    final message = this.message;

    return AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      contentPadding: message != null
          ? const EdgeInsets.fromLTRB(
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s24,
              0,
            )
          : EdgeInsets.zero,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel ?? t.confirm),
        ),
      ],
    );
  }
}

Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
}
