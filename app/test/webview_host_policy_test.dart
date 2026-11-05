import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/webview/domain/webview_host_policy.dart';

void main() {
  const policy = WebViewHostPolicy(
    allowedHosts: {'example.com', 'www.example.com'},
  );

  test('allows https hosts on the allowlist', () {
    expect(policy.isAllowed(Uri.parse('https://example.com/help')), isTrue);
    expect(policy.isAllowed(Uri.parse('http://www.example.com')), isTrue);
  });

  test('rejects hosts outside the allowlist', () {
    expect(policy.isAllowed(Uri.parse('https://evil.example')), isFalse);
    expect(policy.isAllowed(Uri.parse('https://arvopay.com')), isFalse);
  });

  test('rejects non-http schemes', () {
    expect(policy.isAllowed(Uri.parse('file:///tmp/x')), isFalse);
  });
}
