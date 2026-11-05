import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';

class NamedComposer extends StatelessWidget {
  const NamedComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.sendTooltip,
    required this.menuTooltip,
    required this.isSubmitting,
    required this.onSend,
    required this.onOpenMenu,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final String sendTooltip;
  final String menuTooltip;
  final bool isSubmitting;
  final VoidCallback onSend;
  final VoidCallback onOpenMenu;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AppTextField(
              key: const Key('timeline.composer'),
              controller: controller,
              hintText: hintText,
              textInputAction: TextInputAction.send,
              onChanged: onChanged,
              onSubmitted: (_) async => onSend(),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          IconButton.filled(
            key: const Key('timeline.send'),
            onPressed: isSubmitting ? null : onSend,
            tooltip: sendTooltip,
            icon: isSubmitting
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onPrimary,
                    ),
                  )
                : const Icon(Icons.arrow_upward),
          ),
          const SizedBox(width: AppSpacing.s4),
          IconButton.outlined(
            key: const Key('timeline.menu'),
            onPressed: onOpenMenu,
            tooltip: menuTooltip,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
