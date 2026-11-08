import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_theme_controller.dart';
import '../../../app/theme/app_theme_family.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';

class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.settings;
    final selected =
        ref.watch(appThemeControllerProvider).value ?? defaultAppThemeFamily;

    return AppScaffold(
      title: t.themeTitle,
      centerBody: false,
      body: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.s16),
        children: [
          for (final family in AppThemeFamily.values) ...[
            _ThemeOption(
              family: family,
              title: _themeTitle(t, family),
              description: _themeDescription(t, family),
              selected: selected == family,
              isDefault: family == defaultAppThemeFamily,
              defaultLabel: t.defaultLabel,
              onTap: () => ref
                  .read(appThemeControllerProvider.notifier)
                  .setFamily(family),
            ),
            if (family != AppThemeFamily.values.last)
              const SizedBox(height: AppSpacing.s12),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.family,
    required this.title,
    required this.description,
    required this.selected,
    required this.isDefault,
    required this.defaultLabel,
    required this.onTap,
  });

  final AppThemeFamily family;
  final String title;
  final String description;
  final bool selected;
  final bool isDefault;
  final String defaultLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final preview = AppTheme.lightPaletteFor(family);
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      borderColor: selected ? palette.primary : palette.line,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: AppSpacing.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          defaultLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.s12),
                Row(
                  children: [
                    _Swatch(color: preview.primary),
                    const SizedBox(width: AppSpacing.s6),
                    _Swatch(color: preview.accent),
                    const SizedBox(width: AppSpacing.s6),
                    _Swatch(color: preview.surfaceMuted),
                    const SizedBox(width: AppSpacing.s6),
                    _Swatch(color: preview.canvas),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? palette.primary : palette.muted,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.appPalette.line),
      ),
    );
  }
}

String _themeTitle(Translations$settings$en t, AppThemeFamily family) {
  return switch (family) {
    AppThemeFamily.cobalt => t.themeCobalt,
    AppThemeFamily.parchment => t.themeParchment,
    AppThemeFamily.plum => t.themePlum,
  };
}

String _themeDescription(Translations$settings$en t, AppThemeFamily family) {
  return switch (family) {
    AppThemeFamily.cobalt => t.themeCobaltDescription,
    AppThemeFamily.parchment => t.themeParchmentDescription,
    AppThemeFamily.plum => t.themePlumDescription,
  };
}
