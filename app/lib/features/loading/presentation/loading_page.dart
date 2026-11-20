import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_line_icon.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Named',
                  style: AppTextStyles.display.copyWith(fontSize: 34),
                ),
                const SizedBox(width: AppSpacing.s6),
                AppLineIcon(
                  AppLineGlyph.leaf,
                  color: palette.primary,
                  size: 18,
                ),
              ],
            ),
            const Spacer(flex: 3),
            SizedBox(
              width: 96,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: palette.accent,
                backgroundColor: palette.line,
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
