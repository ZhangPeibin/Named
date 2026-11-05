import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class SplashWidget extends StatelessWidget {
  const SplashWidget({
    super.key,
    this.appName = 'Named',
    this.message = 'A reusable Flutter starter.',
    this.logo,
    this.showProgress = true,
    this.backgroundColor,
    this.brandColor = AppColors.brand,
    this.textColor = AppColors.brand,
    this.messageColor = AppColors.textSecondary,
    this.activeDotIndex = 2,
    this.dotCount = 3,
  });

  final String appName;
  final String? message;
  final Widget? logo;
  final bool showProgress;
  final Color? backgroundColor;
  final Color brandColor;
  final Color textColor;
  final Color messageColor;
  final int activeDotIndex;
  final int dotCount;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SplashLogo(color: brandColor, child: logo),
                        const SizedBox(width: 18),
                        Text(
                          appName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: TextStyle(
                          color: messageColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showProgress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 87,
                child: _SplashDots(
                  activeIndex: activeDotIndex,
                  count: dotCount,
                  color: brandColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SplashDots extends StatelessWidget {
  const _SplashDots({
    required this.activeIndex,
    required this.count,
    required this.color,
  });

  final int activeIndex;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: index == activeIndex ? 1 : 0.32),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 6, height: 6),
          ),
          if (index < count - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.color, this.child});

  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return child!;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Text(
        'F',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
