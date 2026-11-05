import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppBarCloseButton extends StatelessWidget {
  const AppBarCloseButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          width: AppSize.size32,
          height: AppSize.size32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            size: AppSize.size18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
