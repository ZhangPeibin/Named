import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_line_icon.dart';
import 'companion_avatar.dart';

class CompanionPresenceRow extends StatelessWidget {
  const CompanionPresenceRow({
    super.key,
    required this.line,
    required this.onTap,
  });

  final String line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      key: const Key('companion.presence'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            const BreathingCompanionAvatar(size: 28),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Text(
                  line,
                  key: ValueKey(line),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ),
            ),
            AppLineIcon(
              AppLineGlyph.chevronRight,
              size: 16,
              color: palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}
