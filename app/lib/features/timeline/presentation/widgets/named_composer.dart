import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import 'spot_mark.dart';

class NamedComposer extends StatelessWidget {
  const NamedComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.sendTooltip,
    required this.meTooltip,
    required this.askTooltip,
    required this.isSubmitting,
    required this.onSend,
    required this.onOpenMe,
    required this.onOpenAsk,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final String sendTooltip;
  final String meTooltip;
  final String askTooltip;
  final bool isSubmitting;
  final VoidCallback onSend;
  final VoidCallback onOpenMe;
  final VoidCallback onOpenAsk;
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
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.r18),
                  border: Border.all(color: palette.line),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.s4),
                    Tooltip(
                      message: meTooltip,
                      child: InkWell(
                        key: const Key('timeline.me'),
                        onTap: onOpenMe,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: const UserMark(size: 34),
                      ),
                    ),
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
                    SizedBox.square(
                      dimension: 38,
                      child: IconButton(
                        key: const Key('timeline.ask'),
                        onPressed: onOpenAsk,
                        tooltip: askTooltip,
                        style: IconButton.styleFrom(
                          foregroundColor: palette.primary,
                          minimumSize: const Size.square(38),
                          maximumSize: const Size.square(38),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(
                          Icons.question_answer_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, child) {
                        final enabled =
                            value.text.trim().isNotEmpty && !isSubmitting;
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
            ),
          ],
        ),
      ),
    );
  }
}
