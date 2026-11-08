import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class TalkAction extends StatelessWidget {
  const TalkAction({
    super.key,
    required this.itemId,
    required this.label,
    required this.isStartingTalk,
    required this.onTap,
  });

  final String itemId;
  final String label;
  final bool isStartingTalk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('timeline.talk.$itemId'),
        onTap: isStartingTalk ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s6,
          ),
          child: isStartingTalk
              ? SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.primary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.s6),
                    Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Icon(Icons.arrow_forward, size: 12, color: palette.primary),
                  ],
                ),
        ),
      ),
    );
  }
}
