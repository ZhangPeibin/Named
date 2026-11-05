import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = Text(label);

    return switch (variant) {
      AppButtonVariant.primary =>
        icon == null
            ? FilledButton(onPressed: onPressed, child: child)
            : FilledButton.icon(
                onPressed: onPressed,
                icon: icon!,
                label: child,
              ),
      AppButtonVariant.secondary =>
        icon == null
            ? FilledButton.tonal(onPressed: onPressed, child: child)
            : FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: icon!,
                label: child,
              ),
      AppButtonVariant.text =>
        icon == null
            ? TextButton(onPressed: onPressed, child: child)
            : TextButton.icon(onPressed: onPressed, icon: icon!, label: child),
    };
  }
}
