import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/i18n/app_locale_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale =
        ref.watch(appLocaleControllerProvider).value ??
        LocaleSettings.currentLocale;
    final t = context.t.settings;

    return AppScaffold(
      title: t.languageTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageOption(
            title: t.english,
            selected: currentLocale == AppLocale.en,
            onTap: () => ref
                .read(appLocaleControllerProvider.notifier)
                .setLocale(AppLocale.en),
          ),
          const SizedBox(height: AppSpacing.s12),
          _LanguageOption(
            title: t.chinese,
            selected: currentLocale == AppLocale.zh,
            onTap: () => ref
                .read(appLocaleControllerProvider.notifier)
                .setLocale(AppLocale.zh),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        onTap: selected ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s16,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppSpacing.r12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 20, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
