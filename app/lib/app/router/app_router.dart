import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_config_provider.dart';
import '../../features/auth/presentation/sign_in_page.dart';
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/challenge/presentation/challenge_create_page.dart';
import '../../features/challenge/presentation/challenge_detail_page.dart';
import '../../features/challenge/presentation/challenge_practice_page.dart';
import '../../features/challenge/presentation/challenges_page.dart';
import '../../features/daily/presentation/daily_read_page.dart';
import '../../features/history/presentation/experience_detail_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/loading/presentation/loading_page.dart';
import '../../features/not_found/presentation/not_found_page.dart';
import '../../features/practice/presentation/practice_page.dart';
import '../../features/question/domain/question.dart';
import '../../features/question/presentation/question_page.dart';
import '../../features/settings/presentation/language_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/settings/presentation/theme_page.dart';
import '../../features/soul/presentation/soul_page.dart';
import '../../features/talk/presentation/talk_page.dart';
import '../../features/timeline/presentation/timeline_feed_page.dart';
import '../../features/timeline/presentation/timeline_page.dart';
import '../../features/todo_demo/presentation/todo_demo_page.dart';
import '../../features/webview/domain/webview_host_policy.dart';
import '../../features/webview/presentation/web_view_page.dart';
import '../../features/words/presentation/words_page.dart';

class AppRoutePaths {
  const AppRoutePaths._();

  static const timeline = '/';
  static const loading = '/loading';
  static const signIn = '/sign-in';
  static const history = '/history';
  static const challenges = '/challenges';
  static const challengeNew = '/challenges/new';
  static const challengeDetail = '/challenges/:challengeId';
  static const challengePractice = '/challenges/:challengeId/practice';
  static const experience = '/history/:experienceId';
  static const words = '/words';
  static const talks = '/talks';
  static const reads = '/reads';
  static const practice = '/practice';
  static const daily = '/daily';
  static const ask = '/ask';
  static const me = '/me';
  static const settings = '/settings';
  static const theme = '/settings/theme';
  static const language = '/settings/language';
  static const talk = '/talk/:conversationId';
  static const todoDemo = '/todo-demo';
  static const webView = '/webview';
}

class AppRouteNames {
  const AppRouteNames._();
  static const timeline = 'timeline';
  static const loading = 'loading';
  static const signIn = 'signIn';
  static const history = 'history';
  static const challenges = 'challenges';
  static const challengeNew = 'challengeNew';
  static const challengeDetail = 'challengeDetail';
  static const challengePractice = 'challengePractice';
  static const experience = 'experience';
  static const words = 'words';
  static const talks = 'talks';
  static const reads = 'reads';
  static const practice = 'practice';
  static const daily = 'daily';
  static const ask = 'ask';
  static const me = 'me';
  static const settings = 'settings';
  static const theme = 'theme';
  static const language = 'language';
  static const talk = 'talk';
  static const todoDemo = 'todoDemo';
  static const webView = 'webView';
}

final _publicRoutePaths = <String>{AppRoutePaths.loading, AppRoutePaths.signIn};

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  final router = GoRouter(
    initialLocation: AppRoutePaths.timeline,
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
        return isSignedIn ? AppRoutePaths.timeline : AppRoutePaths.signIn;
      }

      if (!isSignedIn && !goingToPublic) {
        return AppRoutePaths.signIn;
      }
      if (isSignedIn && goingToSignIn) {
        return AppRoutePaths.timeline;
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
        path: AppRoutePaths.signIn,
        name: AppRouteNames.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutePaths.timeline,
        name: AppRouteNames.timeline,
        builder: (context, state) => const TimelinePage(),
      ),
      GoRoute(
        path: AppRoutePaths.history,
        name: AppRouteNames.history,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: AppRoutePaths.challenges,
        name: AppRouteNames.challenges,
        builder: (context, state) => const ChallengesPage(),
      ),
      GoRoute(
        path: AppRoutePaths.challengeNew,
        name: AppRouteNames.challengeNew,
        builder: (context, state) => const ChallengeCreatePage(),
      ),
      GoRoute(
        path: AppRoutePaths.challengeDetail,
        name: AppRouteNames.challengeDetail,
        builder: (context, state) => ChallengeDetailPage(
          challengeId: state.pathParameters['challengeId']!,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.challengePractice,
        name: AppRouteNames.challengePractice,
        builder: (context, state) => ChallengePracticePage(
          challengeId: state.pathParameters['challengeId']!,
          itemId: state.uri.queryParameters['item'],
        ),
      ),
      GoRoute(
        path: AppRoutePaths.experience,
        name: AppRouteNames.experience,
        builder: (context, state) => ExperienceDetailPage(
          experienceId: state.pathParameters['experienceId']!,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.words,
        name: AppRouteNames.words,
        builder: (context, state) =>
            WordsPage(initialWordId: state.uri.queryParameters['wordId']),
      ),
      GoRoute(
        path: AppRoutePaths.talks,
        name: AppRouteNames.talks,
        builder: (context, state) =>
            const TimelineFeedPage(kind: TimelineFeedKind.talks),
      ),
      GoRoute(
        path: AppRoutePaths.reads,
        name: AppRouteNames.reads,
        builder: (context, state) =>
            const TimelineFeedPage(kind: TimelineFeedKind.reads),
      ),
      GoRoute(
        path: AppRoutePaths.practice,
        name: AppRouteNames.practice,
        builder: (context, state) => const PracticePage(),
      ),
      GoRoute(
        path: AppRoutePaths.daily,
        name: AppRouteNames.daily,
        builder: (context, state) => DailyReadPage(
          date: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutePaths.ask,
        name: AppRouteNames.ask,
        builder: (context, state) {
          final type = state.uri.queryParameters['contextType'];
          final quote = state.uri.queryParameters['contextQuote'];
          return QuestionPage(
            threadId: state.uri.queryParameters['threadId'],
            context: type == null
                ? null
                : QuestionContext(
                    type: type,
                    ref: state.uri.queryParameters['contextRef'],
                    quote: quote,
                  ),
            suggestedQuestion: state.uri.queryParameters['suggested'],
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.me,
        name: AppRouteNames.me,
        builder: (context, state) => const SoulPage(),
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        name: AppRouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutePaths.theme,
        name: AppRouteNames.theme,
        builder: (context, state) => const ThemePage(),
      ),
      GoRoute(
        path: AppRoutePaths.language,
        name: AppRouteNames.language,
        builder: (context, state) => const LanguagePage(),
      ),
      GoRoute(
        path: AppRoutePaths.talk,
        name: AppRouteNames.talk,
        builder: (context, state) => TalkPage(
          conversationId: state.pathParameters['conversationId']!,
          title: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        path: AppRoutePaths.todoDemo,
        name: AppRouteNames.todoDemo,
        builder: (context, state) => const TodoDemoPage(),
      ),
      GoRoute(
        path: AppRoutePaths.webView,
        name: AppRouteNames.webView,
        redirect: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final uri = Uri.tryParse(url);
          if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
            return AppRoutePaths.timeline;
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
