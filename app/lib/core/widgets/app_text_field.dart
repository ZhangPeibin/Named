import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.error,
  });

  final String label;
  final Widget child;
  final String? description;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.titleSmall?.copyWith(color: palette.ink)),
        if (description != null && description!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            description!,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        child,
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            error!,
            style: textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ],
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.enabled,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.minLines,
    this.maxLines = 1,
    this.style,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final bool? enabled;
  final bool readOnly;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final int? minLines;
  final int? maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      minLines: minLines,
      maxLines: maxLines,
      style: style,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        suffixText: suffixText,
      ),
    );
  }
}
