import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../i18n/strings.g.dart';
import '../../providers/companion_providers.dart';
import 'companion_avatar.dart';
import 'companion_setup_sheet.dart';
import 'companion_text_action.dart';

class CompanionTalkGate extends ConsumerWidget {
  const CompanionTalkGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.companion;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      key: const Key('companion.gate'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s16,
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s16,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CompanionAvatar(size: 32),
            const SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s14),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: palette.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.gateTitle, style: textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      t.gateBody,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Wrap(
                      spacing: AppSpacing.s12,
                      runSpacing: AppSpacing.s4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CompanionTextAction(
                          key: const Key('companion.gate.name'),
                          label: t.gateName,
                          primary: true,
                          onPressed: () => showCompanionSetupSheet(context),
                        ),
                        Text(
                          '·',
                          style: AppTextStyles.caption.copyWith(
                            color: palette.muted,
                          ),
                        ),
                        CompanionTextAction(
                          key: const Key('companion.gate.random'),
                          label: t.gateRandom,
                          onPressed: () => _useRandomName(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _useRandomName(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(companionControllerProvider).useRandomName();
    } on ApiException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.companion.randomFailed)),
        );
      }
    }
  }
}
