import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

enum AppMessageSide { incoming, outgoing }

class AppMessageBubble extends StatelessWidget {
  const AppMessageBubble({
    super.key,
    required this.text,
    required this.side,
    this.firstInGroup = true,
    this.secondaryLabel,
    this.secondaryText,
    this.maxWidthFactor = 0.82,
  });

  final String text;
  final AppMessageSide side;
  final bool firstInGroup;
  final String? secondaryLabel;
  final String? secondaryText;
  final double maxWidthFactor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final outgoing = side == AppMessageSide.outgoing;
    final secondary = secondaryText?.trim() ?? '';

    return Padding(
      padding: EdgeInsets.only(
        top: firstInGroup ? AppSpacing.s12 : AppSpacing.s4,
      ),
      child: Align(
        alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * maxWidthFactor,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s14),
            decoration: BoxDecoration(
              color: outgoing ? palette.warm : palette.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.r16),
                topRight: const Radius.circular(AppRadius.r16),
                bottomLeft: Radius.circular(
                  outgoing ? AppRadius.r16 : AppRadius.r8,
                ),
                bottomRight: Radius.circular(
                  outgoing ? AppRadius.r8 : AppRadius.r16,
                ),
              ),
              border: outgoing ? null : Border.all(color: palette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: textTheme.bodyLarge),
                if (secondary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: AppSpacing.s10),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: palette.accent, width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (secondaryLabel != null &&
                            secondaryLabel!.trim().isNotEmpty) ...[
                          Text(
                            secondaryLabel!.toUpperCase(),
                            style: AppTextStyles.eyebrow.copyWith(
                              color: palette.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          secondary,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
