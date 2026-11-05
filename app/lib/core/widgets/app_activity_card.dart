import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class AppActivityCard extends StatelessWidget {
  const AppActivityCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.meta,
    required this.onTap,
    this.icon = Icons.flag_outlined,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String meta;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: palette.warm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r24),
        side: BorderSide(color: palette.warm),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSize.size40,
                    height: AppSize.size40,
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Icon(
                      icon,
                      color: palette.primary,
                      size: AppSize.size20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: AppTextStyles.eyebrow.copyWith(
                        color: palette.warningText,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: palette.warningText,
                    size: AppSize.size18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(title, style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.s6),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                meta,
                style: AppTextStyles.caption.copyWith(color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
