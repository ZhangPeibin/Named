import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../i18n/strings.g.dart';
import 'companion_avatar.dart';

class CompanionGreetingDialog extends StatelessWidget {
  const CompanionGreetingDialog({
    super.key,
    required this.name,
    required this.text,
  });

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.companion.greeting;
    final companionName = name.trim();

    return Dialog(
      key: const Key('companion.greeting'),
      backgroundColor: palette.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            AppSpacing.s32,
            AppSpacing.s24,
            AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CompanionAvatar(size: 76),
              const SizedBox(height: AppSpacing.s16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s14,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.r8),
                    topRight: Radius.circular(AppRadius.r18),
                    bottomLeft: Radius.circular(AppRadius.r18),
                    bottomRight: Radius.circular(AppRadius.r18),
                  ),
                  border: Border.all(color: palette.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (companionName.isNotEmpty) ...[
                      Text(
                        companionName,
                        style: AppTextStyles.caption.copyWith(
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                    ],
                    Text(
                      text,
                      style: AppTextStyles.body.copyWith(color: palette.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('companion.greeting.dismiss'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.buttonHeight),
                    textStyle: AppTextStyles.button,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.dismiss),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
