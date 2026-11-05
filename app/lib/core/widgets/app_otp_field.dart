import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppOtpField extends StatelessWidget {
  const AppOtpField({
    super.key,
    this.controller,
    this.length = 6,
    this.autofocus = false,
    this.obscureText = false,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.inputFormatters,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController? controller;
  final int length;
  final bool autofocus;
  final bool obscureText;
  final MainAxisAlignment mainAxisAlignment;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseTextStyle = textTheme.titleMedium?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );

    final defaultPinTheme = PinTheme(
      width: 46,
      height: 46,
      textStyle: baseTextStyle,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
    );

    return Pinput(
      controller: controller,
      length: length,
      autofocus: autofocus,
      mainAxisAlignment: mainAxisAlignment,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: defaultPinTheme.copyDecorationWith(
        border: Border.all(color: AppColors.brand, width: 1.4),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      submittedPinTheme: defaultPinTheme.copyDecorationWith(
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      keyboardType: TextInputType.number,
      obscureText: obscureText,
      obscuringCharacter: '•',
      inputFormatters: inputFormatters ?? const [],
      onChanged: onChanged,
      onCompleted: onCompleted,
    );
  }
}
