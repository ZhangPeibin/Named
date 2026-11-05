import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/config/app_config.dart';
import 'package:named/core/config/app_flavor_guard.dart';

void main() {
  for (final environment in AppEnvironment.values) {
    test('${environment.name} flavor matches its Dart environment', () {
      expect(
        () => AppFlavorGuard.validate(
          nativeFlavor: environment.name,
          environment: environment,
        ),
        returnsNormally,
      );
    });
  }

  test('rejects a native flavor and APP_ENV mismatch', () {
    expect(
      () => AppFlavorGuard.validate(
        nativeFlavor: 'dev',
        environment: AppEnvironment.prod,
      ),
      throwsA(
        isA<AppFlavorException>().having(
          (error) => error.message,
          'message',
          contains('does not match'),
        ),
      ),
    );
  });

  test('rejects a missing native flavor', () {
    expect(
      () => AppFlavorGuard.validate(
        nativeFlavor: null,
        environment: AppEnvironment.dev,
      ),
      throwsA(isA<AppFlavorException>()),
    );
  });

  test('rejects an unknown APP_ENV instead of falling back to dev', () {
    expect(
      () => AppEnvironment.parse('production'),
      throwsA(isA<FormatException>()),
    );
    expect(() => AppEnvironment.parse(''), throwsA(isA<FormatException>()));
  });
}
