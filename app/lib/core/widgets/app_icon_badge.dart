import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// A circular badge with a [symbol] letter or [icon].
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    this.symbol = '',
    required this.color,
    this.size = AppSize.assetIcon,
    this.icon,
    this.iconColor,
    this.borderColor,
  });

  final String symbol;
  final Color color;
  final double size;
  final IconData? icon;
  final Color? iconColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: icon == null
          ? Text(
              symbol,
              style: textTheme.labelLarge?.copyWith(
                color: iconColor ?? AppColors.lightSurface,
                fontWeight: FontWeight.w800,
              ),
            )
          : Icon(
              icon,
              color: iconColor ?? AppColors.lightSurface,
              size: size * 0.54,
            ),
    );
  }
}
