import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Horizontal divider with centered text, e.g. `──────── OR ────────`.
class AppTextDivider extends StatelessWidget {
  const AppTextDivider({
    super.key,
    required this.text,
    this.lineColor = AppColors.dividerLine,
    this.textColor = AppColors.textSecondary,
    this.thickness = 0.5,
    this.gap = AppSpacing.s12,
  });

  final String text;
  final Color lineColor;
  final Color textColor;
  final double thickness;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Divider(color: lineColor, thickness: thickness),
        ),
        SizedBox(width: gap),
        Text(text, style: textTheme.labelSmall?.copyWith(color: textColor)),
        SizedBox(width: gap),
        Expanded(
          child: Divider(color: lineColor, thickness: thickness),
        ),
      ],
    );
  }
}
