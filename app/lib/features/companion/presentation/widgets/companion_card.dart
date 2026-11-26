import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../i18n/strings.g.dart';
import 'companion_avatar.dart';
import 'companion_text_action.dart';

class CompanionFirstRunCard extends StatelessWidget {
  const CompanionFirstRunCard({
    super.key,
    required this.onName,
    required this.onLater,
  });

  final VoidCallback onName;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final t = context.t.companion;
    final palette = context.appPalette;

    return Row(
      key: const Key('companion.firstRun'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CompanionAvatar(size: 32),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.r8),
                topRight: Radius.circular(AppRadius.r16),
                bottomLeft: Radius.circular(AppRadius.r16),
                bottomRight: Radius.circular(AppRadius.r16),
              ),
              border: Border.all(color: palette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.firstRunTitle,
                  style: AppTextStyles.label.copyWith(color: palette.ink),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  t.firstRunBody,
                  style: AppTextStyles.bodySmall.copyWith(color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CompanionTextAction(
                      key: const Key('companion.nameMe'),
                      label: t.nameMe,
                      primary: true,
                      onPressed: onName,
                    ),
                    Text(
                      '·',
                      style: AppTextStyles.caption.copyWith(
                        color: palette.muted,
                      ),
                    ),
                    CompanionTextAction(
                      key: const Key('companion.maybeLater'),
                      label: t.maybeLater,
                      onPressed: onLater,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CompanionInviteRow extends StatelessWidget {
  const CompanionInviteRow({
    super.key,
    required this.onName,
    required this.onHide,
  });

  final VoidCallback onName;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final t = context.t.companion;
    final palette = context.appPalette;

    return Row(
      key: const Key('companion.invite'),
      children: [
        const CompanionAvatar(size: 28),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s12,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.r8),
                topRight: Radius.circular(AppRadius.r16),
                bottomLeft: Radius.circular(AppRadius.r16),
                bottomRight: Radius.circular(AppRadius.r16),
              ),
              border: Border.all(color: palette.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.invite,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: palette.muted,
                    ),
                  ),
                ),
                CompanionTextAction(
                  key: const Key('companion.invite.name'),
                  label: t.nameMe,
                  primary: true,
                  onPressed: onName,
                ),
                IconButton(
                  key: const Key('companion.invite.hide'),
                  tooltip: t.hideForNow,
                  onPressed: onHide,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const AppLineIcon(AppLineGlyph.close, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
