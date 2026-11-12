import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class NamedComposer extends StatelessWidget {
  const NamedComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.sendTooltip,
    required this.isSubmitting,
    required this.onSend,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final String sendTooltip;
  final bool isSubmitting;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.r18),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.s6),
            Expanded(
              child: TextField(
                key: const Key('timeline.composer'),
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                style: textTheme.bodyLarge,
                cursorColor: palette.primary,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final enabled = value.text.trim().isNotEmpty && !isSubmitting;
                return SizedBox.square(
                  dimension: 38,
                  child: IconButton.filled(
                    key: const Key('timeline.send'),
                    onPressed: enabled ? onSend : null,
                    tooltip: sendTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      disabledBackgroundColor: palette.surfaceMuted,
                      disabledForegroundColor: palette.muted,
                      minimumSize: const Size.square(38),
                      maximumSize: const Size.square(38),
                      padding: EdgeInsets.zero,
                    ),
                    icon: isSubmitting
                        ? SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.onPrimary,
                            ),
                          )
                        : const Icon(Icons.arrow_upward, size: 18),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
