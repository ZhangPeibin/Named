import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../core/config/app_config.dart';
import '../core/i18n/app_locale_controller.dart';
import '../core/providers/app_config_provider.dart';
import '../i18n/strings.g.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';
import 'theme/app_theme_family.dart';

class TemplateApp extends ConsumerWidget {
  const TemplateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    ref.watch(appLocaleControllerProvider);
    final themeFamily =
        ref.watch(appThemeControllerProvider).value ?? defaultAppThemeFamily;
    final locale = TranslationProvider.of(context).flutterLocale;

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: config.appName,
        debugShowCheckedModeBanner: config.environment != AppEnvironment.prod,
        theme: AppTheme.light(family: themeFamily),
        darkTheme: AppTheme.dark(family: themeFamily),
        locale: locale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
