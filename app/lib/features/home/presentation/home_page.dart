import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/feedback/app_toast.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../app_update/presentation/app_update_dialog.dart';
import '../../app_update/providers/app_version_providers.dart';
import '../../auth/providers/auth_notifier.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t;

    return AppScaffold(
      key: const Key('home.page'),
      title: config.appName,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flutter_dash, size: 72, color: colorScheme.primary),
            const SizedBox(height: AppSpacing.s24),
            Text(
              config.appName,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              t.app.subtitle,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            _InfoTile(
              label: t.common.environment,
              value: config.environment.name,
            ),
            _InfoTile(label: t.common.apiBaseUrl, value: config.apiBaseUrl),
            const SizedBox(height: AppSpacing.s24),
            Wrap(
              spacing: AppSpacing.s12,
              runSpacing: AppSpacing.s12,
              alignment: WrapAlignment.center,
              children: [
                AppButton(
                  label: t.app.openApiDemo,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.pushNamed(AppRouteNames.todoDemo),
                ),
                AppButton(
                  label: t.app.languageSettings,
                  variant: AppButtonVariant.text,
                  onPressed: () => context.pushNamed(AppRouteNames.language),
                ),
                AppButton(
                  label: t.webView.openDemo,
                  variant: AppButtonVariant.text,
                  onPressed: () => context.pushNamed(
                    AppRouteNames.webView,
                    queryParameters: {'url': 'https://example.com/'},
                  ),
                ),
                AppButton(
                  label: t.appUpdate.checkOptional,
                  variant: AppButtonVariant.text,
                  onPressed: () => _checkForUpdate(context, ref, force: false),
                ),
                AppButton(
                  label: t.appUpdate.checkForce,
                  variant: AppButtonVariant.text,
                  onPressed: () => _checkForUpdate(context, ref, force: true),
                ),
                AppButton(
                  label: t.auth.signOut,
                  variant: AppButtonVariant.text,
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForUpdate(
    BuildContext context,
    WidgetRef ref, {
    required bool force,
  }) async {
    try {
      final version = await ref.read(appVersionCheckProvider(force).future);
      if (!context.mounted) {
        return;
      }
      await showAppUpdateDialog(context: context, version: version);
    } catch (error) {
      AppToast.error(error.toString());
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: textTheme.labelLarge),
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
