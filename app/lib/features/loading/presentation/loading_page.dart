import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isDark = context.isAppDark;
    final mark = Image.asset(
      isDark
          ? 'assets/branding/marks/symbol_dark.png'
          : 'assets/branding/marks/symbol_light.png',
      width: AppSize.splashMark,
      height: AppSize.splashMark,
      fit: BoxFit.contain,
      semanticLabel: 'Named',
    );

    return ColoredBox(
      color: context.appSplashGround,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: reduceMotion
                  ? mark
                  : TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) =>
                          Opacity(opacity: value, child: child),
                      child: mark,
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.s32,
              child: Center(
                child: SizedBox(
                  width: AppSize.splashProgressWidth,
                  height: AppSize.splashProgressHeight,
                  child: reduceMotion
                      ? ColoredBox(color: palette.line)
                      : LinearProgressIndicator(
                          minHeight: AppSize.splashProgressHeight,
                          color: palette.primary,
                          backgroundColor: palette.line,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
