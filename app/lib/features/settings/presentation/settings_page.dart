import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../auth/providers/auth_notifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.settings;
    final palette = context.appPalette;

    return AppScaffold(
      title: t.title,
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.s16),
        children: [
          AppCard(
            onTap: () => context.pushNamed(AppRouteNames.language),
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Icon(Icons.translate, color: palette.primary),
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: Text(t.language)),
                Icon(Icons.chevron_right, color: palette.muted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppCard(
            onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Icon(Icons.logout, color: palette.muted),
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: Text(t.signOut)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
