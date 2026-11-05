/// Host allowlist for in-app WebView navigation.
class WebViewHostPolicy {
  const WebViewHostPolicy({required this.allowedHosts});

  /// Defaults used when config does not provide hosts.
  static const defaultAllowedHosts = {'example.com', 'www.example.com'};

  final Set<String> allowedHosts;

  bool isAllowed(Uri uri) {
    final host = uri.host.toLowerCase();
    return (uri.isScheme('http') || uri.isScheme('https')) &&
        allowedHosts.map((h) => h.toLowerCase()).contains(host);
  }
}
