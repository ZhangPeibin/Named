import '../../i18n/strings.g.dart';
import '../network/api_exception.dart';

/// Maps transport-layer failures to user-facing messages.
class AppErrorLocalizer {
  const AppErrorLocalizer._();

  static String messageFromCurrentLocale(Object error) {
    if (error is ApiException) {
      return transportMessageFromTranslations(t, error);
    }
    return t.error.unknown;
  }

  static String transportMessageFromTranslations(
    Translations translations,
    ApiException error,
  ) {
    final errorT = translations.error;
    return switch (error.type) {
      ApiExceptionType.network => errorT.network,
      ApiExceptionType.timeout => errorT.timeout,
      ApiExceptionType.server => errorT.serverError,
      ApiExceptionType.unauthorized => errorT.unauthorized,
      _ => errorT.unknown,
    };
  }
}
