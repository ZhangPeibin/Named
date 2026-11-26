import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/timeline_item.dart';

/// Shown immediately after a send while the discovery agent is running, so the
/// timeline never sits empty for the several seconds the model takes.
class PendingNamingCard extends StatelessWidget {
  const PendingNamingCard({super.key, required this.item});

  final TimelinePendingItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.timeline;

    return Container(
      key: Key('timeline.pending.${item.id}'),
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.inputText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            t.naming,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}
