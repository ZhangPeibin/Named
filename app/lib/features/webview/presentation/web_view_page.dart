import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../domain/webview_host_policy.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({
    super.key,
    required this.url,
    this.title,
    this.hostPolicy = const WebViewHostPolicy(
      allowedHosts: WebViewHostPolicy.defaultAllowedHosts,
    ),
  });

  final String url;
  final String? title;
  final WebViewHostPolicy hostPolicy;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController? _controller;
  var _progress = 0;
  WebResourceError? _error;

  Uri? get _uri => Uri.tryParse(widget.url);

  bool get _canLoadUrl {
    final uri = _uri;
    return uri != null && widget.hostPolicy.isAllowed(uri);
  }

  @override
  void initState() {
    super.initState();

    if (!_canLoadUrl) {
      _controller = null;
      return;
    }

    final controller = WebViewController();
    _controller = controller;
    unawaited(_configureController(controller));
  }

  Future<void> _configureController(WebViewController controller) async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || !widget.hostPolicy.isAllowed(uri)) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
        onPageStarted: (_) {
          setState(() {
            _error = null;
            _progress = 0;
          });
        },
        onPageFinished: (_) {
          setState(() {
            _progress = 100;
          });
        },
        onWebResourceError: (error) {
          setState(() {
            _error = error;
          });
        },
      ),
    );
    await controller.loadRequest(_uri!);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return AppScaffold(
      title: widget.title ?? context.t.webView.defaultTitle,
      centerBody: false,
      padding: EdgeInsets.zero,
      maxWidth: double.infinity,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          context.go('/');
        },
        icon: const Icon(Icons.arrow_back),
      ),
      body: switch ((_canLoadUrl, controller, _error)) {
        (false, _, _) => _InvalidUrlView(url: widget.url),
        (true, _, final error?) => _WebViewErrorView(
          error: error,
          onRetry: () {
            setState(() {
              _error = null;
            });
            if (controller != null) {
              unawaited(controller.reload());
            }
          },
        ),
        (true, final controller?, null) => Stack(
          children: [
            WebViewWidget(controller: controller),
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
          ],
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _InvalidUrlView extends StatelessWidget {
  const _InvalidUrlView({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.t.webView.linkNotAllowed(url: url),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _WebViewErrorView extends StatelessWidget {
  const _WebViewErrorView({required this.error, required this.onRetry});

  final WebResourceError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t.webView.loadFailed, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.description,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.t.common.retry),
            ),
          ],
        ),
      ),
    );
  }
}
