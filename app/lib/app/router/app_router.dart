import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_config_provider.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/loading/presentation/loading_page.dart';
import '../../features/not_found/presentation/not_found_page.dart';
import '../../features/settings/presentation/language_page.dart';
import '../../features/todo_demo/presentation/todo_demo_page.dart';
import '../../features/webview/domain/webview_host_policy.dart';
import '../../features/webview/presentation/web_view_page.dart';

class AppRoutePaths {
  const AppRoutePaths._();

  static const home = '/';
  static const loading = '/loading';
  static const signIn = '/sign-in';
  static const todoDemo = '/todo-demo';
  static const language = '/settings/language';
  static const webView = '/webview';
}

class AppRouteNames {
  const AppRouteNames._();
  static const home = 'home';
  static const loading = 'loading';
  static const signIn = 'signIn';
  static const todoDemo = 'todoDemo';
  static const language = 'language';
  static const webView = 'webView';
}

final _publicRoutePaths = <String>{AppRoutePaths.loading, AppRoutePaths.signIn};

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  final router = GoRouter(
    initialLocation: AppRoutePaths.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);

      if (auth.isLoading && !auth.hasValue) {
        return state.matchedLocation == AppRoutePaths.loading
            ? null
            : AppRoutePaths.loading;
      }

      final isSignedIn = auth.value == AuthStatus.signedIn;
      final goingToSignIn = state.matchedLocation == AppRoutePaths.signIn;
      final goingToPublic = _publicRoutePaths.contains(state.matchedLocation);

      if (state.matchedLocation == AppRoutePaths.loading) {
        return isSignedIn ? AppRoutePaths.home : AppRoutePaths.signIn;
      }

      if (!isSignedIn && !goingToPublic) {
        return AppRoutePaths.signIn;
      }
      if (isSignedIn && goingToSignIn) {
        return AppRoutePaths.home;
      }
      return null;
    },
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
    routes: [
      GoRoute(
        path: AppRoutePaths.loading,
        name: AppRouteNames.loading,
        builder: (context, state) => const LoadingPage(),
      ),
      GoRoute(
        path: AppRoutePaths.home,
        name: AppRouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutePaths.signIn,
        name: AppRouteNames.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutePaths.todoDemo,
        name: AppRouteNames.todoDemo,
        builder: (context, state) => const TodoDemoPage(),
      ),
      GoRoute(
        path: AppRoutePaths.language,
        name: AppRouteNames.language,
        builder: (context, state) => const LanguagePage(),
      ),
      GoRoute(
        path: AppRoutePaths.webView,
        name: AppRouteNames.webView,
        redirect: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final uri = Uri.tryParse(url);
          if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
            return AppRoutePaths.home;
          }
          return null;
        },
        builder: (context, state) {
          final config = ref.read(appConfigProvider);
          final url = state.uri.queryParameters['url']!;
          final title = state.uri.queryParameters['title'];
          return WebViewPage(
            url: url,
            title: title,
            hostPolicy: WebViewHostPolicy(
              allowedHosts: config.webViewAllowedHosts,
            ),
          );
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _sub = _ref.listen<AsyncValue<AuthStatus>>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthStatus>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
