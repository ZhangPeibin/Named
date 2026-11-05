import 'app_config.dart';

class AppFlavorGuard {
  const AppFlavorGuard._();

  static void validate({
    required String? nativeFlavor,
    required AppEnvironment environment,
  }) {
    final flavor = nativeFlavor?.trim();
    if (flavor == null || flavor.isEmpty) {
      throw const AppFlavorException(
        'No native flavor was provided. Start the app with '
        '--flavor dev, staging, or prod.',
      );
    }

    if (flavor != environment.name) {
      throw AppFlavorException(
        'Native flavor "$flavor" does not match APP_ENV '
        '"${environment.name}".',
      );
    }
  }
}

class AppFlavorException implements Exception {
  const AppFlavorException(this.message);

  final String message;

  @override
  String toString() => 'AppFlavorException: $message';
}
