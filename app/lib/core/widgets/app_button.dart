import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
            ),
          )
        : Text(label);

    return switch (variant) {
      AppButtonVariant.primary =>
        icon == null
            ? FilledButton(
                onPressed: isLoading ? null : onPressed,
                child: child,
              )
            : FilledButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: icon!,
                label: child,
              ),
      AppButtonVariant.secondary =>
        icon == null
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                child: child,
              )
            : OutlinedButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: icon!,
                label: child,
              ),
      AppButtonVariant.text =>
        icon == null
            ? TextButton(onPressed: isLoading ? null : onPressed, child: child)
            : TextButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: icon!,
                label: child,
              ),
    };
  }
}
