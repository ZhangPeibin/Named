import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_flavor_guard.dart';
import 'core/errors/console_error_reporter.dart';
import 'core/errors/error_reporter.dart';
import 'core/i18n/app_locale_controller.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/console_app_logger.dart';
import 'core/providers/app_config_provider.dart';
import 'core/providers/error_reporter_provider.dart';
import 'core/providers/key_value_storage_provider.dart';
import 'core/providers/logger_provider.dart';
import 'core/startup/app_install_guard.dart';
import 'core/startup/configuration_error_app.dart';
import 'core/startup/startup_logger.dart';
import 'core/storage/flutter_secure_storage_adapter.dart';
import 'core/storage/shared_preferences_key_value_storage.dart';
import 'i18n/strings.g.dart';

Future<void> main() => bootstrapApp();

Future<void> bootstrapApp({
  AppLogger? appLogger,
  ErrorReporter? appErrorReporter,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrapLogger =
      appLogger ?? ConsoleAppLogger(enableDebugLogs: !kReleaseMode);
  final bootstrapReporter =
      appErrorReporter ?? ConsoleErrorReporter(bootstrapLogger);

  late final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
    AppFlavorGuard.validate(
      nativeFlavor: appFlavor,
      environment: config.environment,
    );
  } catch (error, stackTrace) {
    await Future.sync(
      () => bootstrapReporter.report(
        error,
        stackTrace,
        reason: 'Invalid application configuration',
        fatal: true,
      ),
    );
    if (kReleaseMode) {
      runApp(const ConfigurationErrorApp());
      return;
    }
    Error.throwWithStackTrace(error, stackTrace);
  }

  final logger =
      appLogger ?? ConsoleAppLogger(enableDebugLogs: !config.isProduction);
  final errorReporter = appErrorReporter ?? ConsoleErrorReporter(logger);

  await runZonedGuarded(
    () async {
      StartupLogger.mark('main() entered');
      StartupLogger.mark('WidgetsFlutterBinding initialized');

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(
          Future.sync(
            () => errorReporter.report(
              details.exception,
              details.stack ?? StackTrace.current,
              reason: details.context?.toDescription(),
              fatal: true,
            ),
          ),
        );
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(
          Future.sync(
            () => errorReporter.report(
              error,
              stackTrace,
              reason: 'Platform dispatcher',
              fatal: true,
            ),
          ),
        );
        return true;
      };

      final prefs = await SharedPreferences.getInstance();
      final keyValueStorage = SharedPreferencesKeyValueStorage(prefs);
      final savedLocale = await loadSavedAppLocale(keyValueStorage);
      await LocaleSettings.setLocale(savedLocale);
      StartupLogger.mark('Locale initialized: ${savedLocale.languageCode}');

      final secureStorage = FlutterSecureStorageAdapter();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        StartupLogger.mark('AppInstallGuard start');
        await AppInstallGuard(
          keyValueStorage: keyValueStorage,
          secureStorage: secureStorage,
        ).ensureCurrentInstall();
        StartupLogger.mark('AppInstallGuard finished');
      } else {
        StartupLogger.mark('AppInstallGuard skipped on $defaultTargetPlatform');
      }

      runApp(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(config),
              sharedPreferencesProvider.overrideWithValue(prefs),
              loggerProvider.overrideWithValue(logger),
              errorReporterProvider.overrideWithValue(errorReporter),
            ],
            child: const TemplateApp(),
          ),
        ),
      );
      StartupLogger.mark('runApp() returned');
    },
    (error, stackTrace) {
      unawaited(
        Future.sync(
          () => errorReporter.report(
            error,
            stackTrace,
            reason: 'Uncaught zone error',
            fatal: true,
          ),
        ),
      );
    },
  );
}
