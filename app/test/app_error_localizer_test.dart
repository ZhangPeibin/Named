import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/errors/app_error_localizer.dart';
import 'package:named/core/network/api_exception.dart';
import 'package:named/i18n/strings.g.dart';

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  group('AppErrorLocalizer', () {
    test('maps transport failures to slang messages', () {
      final translations = LocaleSettings.instance.currentTranslations;

      expect(
        AppErrorLocalizer.transportMessageFromTranslations(
          translations,
          const ApiException(
            type: ApiExceptionType.network,
            message: 'Network connection failed',
          ),
        ),
        translations.error.network,
      );
      expect(
        AppErrorLocalizer.transportMessageFromTranslations(
          translations,
          const ApiException(
            type: ApiExceptionType.timeout,
            message: 'Request timeout',
          ),
        ),
        translations.error.timeout,
      );
      expect(
        AppErrorLocalizer.transportMessageFromTranslations(
          translations,
          const ApiException(
            type: ApiExceptionType.server,
            message: 'Server error',
          ),
        ),
        translations.error.serverError,
      );
    });

    test('falls back to unknown for non-transport failures', () {
      final translations = LocaleSettings.instance.currentTranslations;

      expect(
        AppErrorLocalizer.transportMessageFromTranslations(
          translations,
          const ApiException(
            type: ApiExceptionType.notFound,
            message: 'Not found',
          ),
        ),
        translations.error.unknown,
      );
    });
  });
}
