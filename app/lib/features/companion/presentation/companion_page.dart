import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../domain/companion_profile.dart';
import '../providers/companion_providers.dart';
import 'companion_presence_line.dart';
import 'widgets/companion_avatar.dart';
import 'widgets/companion_setup_sheet.dart';

class CompanionPage extends ConsumerWidget {
  const CompanionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.companion;
    final companion = ref.watch(companionProvider);
    final presence = ref.watch(companionPresenceProvider);
    final presenceLine = presence.hasValue
        ? companionPresenceLine(context, presence.value!)
        : context.t.companion.presence.fallback;

    return AppScaffold(
      key: const Key('companion.page'),
      title: t.title,
      body: AppAsyncView(
        value: companion,
        error: (error, stack) => AppErrorView(
          title: t.loadFailed,
          message: error is ApiException
              ? error.message
              : context.t.common.pleaseTryAgain,
          onRetry: () => ref.invalidate(companionProvider),
        ),
        data: (profile) =>
            _CompanionBody(profile: profile, presenceLine: presenceLine),
      ),
    );
  }
}

class _CompanionBody extends StatelessWidget {
  const _CompanionBody({required this.profile, required this.presenceLine});

  final CompanionProfile profile;
  final String presenceLine;

  @override
  Widget build(BuildContext context) {
    final t = context.t.companion;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.s16),
        const Center(child: CompanionAvatar(size: 88)),
        const SizedBox(height: AppSpacing.s16),
        Text(
          profile.isNamed ? profile.name! : t.unnamedSubtitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          t.today.toUpperCase(),
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: palette.muted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          presenceLine,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text(
          t.profile.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: palette.muted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        _ProfileRow(
          label: t.gender,
          value: profile.gender == null
              ? t.notSet
              : _genderLabel(context, profile.gender!),
        ),
        _ProfileRow(
          label: t.hobby,
          value: profile.hasHobby ? profile.hobby! : t.notSet,
        ),
        const SizedBox(height: AppSpacing.s24),
        if (profile.isNamed)
          AppButton(
            key: const Key('companion.page.edit'),
            label: t.edit,
            variant: AppButtonVariant.secondary,
            onPressed: () => showCompanionSetupSheet(context, initial: profile),
          )
        else
          AppButton(
            key: const Key('companion.page.name'),
            label: t.nameMe,
            onPressed: () => showCompanionSetupSheet(context),
          ),
      ],
    );
  }

  String _genderLabel(BuildContext context, CompanionGender gender) {
    final t = context.t.companion;
    return switch (gender) {
      CompanionGender.female => t.genderFemale,
      CompanionGender.male => t.genderMale,
      CompanionGender.preferNotToSay => t.genderPreferNotToSay,
    };
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
