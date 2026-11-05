import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// A tappable card row with leading, title/subtitle, and trailing chevron.
class AppOptionTile extends StatefulWidget {
  const AppOptionTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleFontSize,
    this.titleFontWeight,
    this.subtitleFontSize,
    this.subtitleColor,
    this.borderRadius,
    this.pressedColor,
  });

  final Widget leading;
  final String title;
  final String? subtitle;

  /// Defaults to a right chevron when null.
  final Widget? trailing;
  final VoidCallback? onTap;

  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final double? subtitleFontSize;
  final Color? subtitleColor;
  final double? borderRadius;

  /// Background while pressed. Defaults to white (no dim).
  final Color? pressedColor;

  @override
  State<AppOptionTile> createState() => _AppOptionTileState();
}

class _AppOptionTileState extends State<AppOptionTile> {
  var _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = widget.subtitle;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: _isPressed
                ? (widget.pressedColor ?? Colors.white)
                : Colors.white,
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppRadius.r16,
            ),
            border: Border.all(
              color: _isPressed
                  ? AppColors.brandSoft.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: AppSpacing.s4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: AppSpacing.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: widget.titleFontWeight ?? FontWeight.w700,
                        fontSize: widget.titleFontSize,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: widget.subtitleColor ?? AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                          fontSize: widget.subtitleFontSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              widget.trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: AppSize.size17,
                    color: AppColors.tileChevron,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
