import 'package:flutter_test/flutter_test.dart';
import 'package:named/core/logging/sensitive_data_redactor.dart';

void main() {
  test('redacts credentials from URLs while retaining safe query values', () {
    final uri = Uri.parse(
      'https://user:pass@example.com/items?page=2&access_token=secret&otp=1234',
    );

    final redacted = SensitiveDataRedactor.uri(uri).toString();

    expect(redacted, contains('page=2'));
    expect(redacted, isNot(contains('secret')));
    expect(redacted, isNot(contains('1234')));
    expect(redacted, isNot(contains('user:pass')));
  });
}
