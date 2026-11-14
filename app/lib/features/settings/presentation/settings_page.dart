import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_controller.dart';
import '../../../app/theme/app_theme_family.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../daily/domain/daily_reminder.dart';
import '../../daily/providers/daily_reminder_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.settings;
    final palette = context.appPalette;
    final themeFamily =
        ref.watch(appThemeControllerProvider).value ?? defaultAppThemeFamily;
    final reminder =
        ref.watch(dailyReminderProvider).value ?? DailyReminder.defaults;

    return AppScaffold(
      title: t.title,
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.s16),
        children: [
          AppCard(
            onTap: () => context.pushNamed(AppRouteNames.theme),
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Icon(Icons.palette_outlined, color: palette.primary),
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: Text(t.theme)),
                Text(
                  _themeTitle(t, themeFamily),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
                const SizedBox(width: AppSpacing.s4),
                Icon(Icons.chevron_right, color: palette.muted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
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
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: palette.primary),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.reminder),
                          const SizedBox(height: 2),
                          Text(
                            t.reminderHint,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.muted),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      key: const Key('settings.reminder.switch'),
                      value: reminder.enabled,
                      onChanged: (enabled) =>
                          _setReminderEnabled(context, ref, enabled: enabled),
                    ),
                  ],
                ),
                if (reminder.enabled) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Divider(color: palette.line, height: 1),
                  InkWell(
                    key: const Key('settings.reminder.time'),
                    onTap: () => _pickReminderTime(context, ref, reminder),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s12,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(t.reminderTime)),
                          Text(
                            MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay(
                                hour: reminder.hour,
                                minute: reminder.minute,
                              ),
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.muted),
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Icon(Icons.chevron_right, color: palette.muted),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Future<void> _setReminderEnabled(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
  }) async {
    final granted = await ref
        .read(dailyReminderProvider.notifier)
        .setEnabled(enabled);
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.settings.notificationsDenied)),
      );
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    DailyReminder reminder,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (selected == null || !context.mounted) {
      return;
    }
    await ref
        .read(dailyReminderProvider.notifier)
        .setTime(selected.hour, selected.minute);
  }
}

String _themeTitle(Translations$settings$en t, AppThemeFamily family) {
  return switch (family) {
    AppThemeFamily.cobalt => t.themeCobalt,
    AppThemeFamily.parchment => t.themeParchment,
    AppThemeFamily.plum => t.themePlum,
  };
}
