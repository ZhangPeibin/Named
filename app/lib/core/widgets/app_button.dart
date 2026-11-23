import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.expand = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final height = switch (size) {
      AppButtonSize.sm => 36.0,
      AppButtonSize.md => 44.0,
      AppButtonSize.lg => 52.0,
    };
    final horizontalPadding = switch (size) {
      AppButtonSize.sm => AppSpacing.s12,
      AppButtonSize.md => AppSpacing.s20,
      AppButtonSize.lg => AppSpacing.s24,
    };
    final minimumSize = Size(expand ? double.infinity : 0, height);
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

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(minimumSize),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
    );

    return switch (variant) {
      AppButtonVariant.primary =>
        icon == null
            ? FilledButton(
                onPressed: isLoading ? null : onPressed,
                style: style,
                child: child,
              )
            : FilledButton.icon(
                onPressed: isLoading ? null : onPressed,
                style: style,
                icon: icon!,
                label: child,
              ),
      AppButtonVariant.secondary =>
        icon == null
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: style,
                child: child,
              )
            : OutlinedButton.icon(
                onPressed: isLoading ? null : onPressed,
                style: style,
                icon: icon!,
                label: child,
              ),
      AppButtonVariant.text =>
        icon == null
            ? TextButton(
                onPressed: isLoading ? null : onPressed,
                style: style,
                child: child,
              )
            : TextButton.icon(
                onPressed: isLoading ? null : onPressed,
                style: style,
                icon: icon!,
                label: child,
              ),
    };
  }
}
