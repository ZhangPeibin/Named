///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en app = Translations$app$en._(_root);
	late final Translations$common$en common = Translations$common$en._(_root);
	late final Translations$notFound$en notFound = Translations$notFound$en._(_root);
	late final Translations$error$en error = Translations$error$en._(_root);
	late final Translations$todoDemo$en todoDemo = Translations$todoDemo$en._(_root);
	late final Translations$settings$en settings = Translations$settings$en._(_root);
	late final Translations$auth$en auth = Translations$auth$en._(_root);
	late final Translations$appUpdate$en appUpdate = Translations$appUpdate$en._(_root);
	late final Translations$webView$en webView = Translations$webView$en._(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Named'
	String get name => 'Named';

	/// en: 'A reusable starter project for Flutter apps.'
	String get subtitle => 'A reusable starter project for Flutter apps.';

	/// en: 'Open API demo'
	String get openApiDemo => 'Open API demo';

	/// en: 'Language'
	String get languageSettings => 'Language';
}

// Path: common
class Translations$common$en {
	Translations$common$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Couldn't load. Please try again.'
	String get loadFailed => 'Couldn\'t load. Please try again.';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Something went wrong'
	String get somethingWentWrong => 'Something went wrong';

	/// en: 'Please try again.'
	String get pleaseTryAgain => 'Please try again.';

	/// en: 'No data here'
	String get noDataHere => 'No data here';

	/// en: 'Try again'
	String get tryAgain => 'Try again';

	/// en: 'Environment'
	String get environment => 'Environment';

	/// en: 'API Base URL'
	String get apiBaseUrl => 'API Base URL';

	/// en: 'Send code'
	String get sendCode => 'Send code';

	/// en: 'Sending...'
	String get sendingCode => 'Sending...';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Cancel'
	String get cancel => 'Cancel';
}

// Path: notFound
class Translations$notFound$en {
	Translations$notFound$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Page not found'
	String get title => 'Page not found';

	/// en: 'The page you requested does not exist.'
	String get description => 'The page you requested does not exist.';

	/// en: 'No route matches ${location}.'
	String noRoute({required Object location}) => 'No route matches ${location}.';
}

// Path: error
class Translations$error$en {
	Translations$error$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Something went wrong. Please try again.'
	String get unknown => 'Something went wrong. Please try again.';

	/// en: 'Network connection failed. Please check your connection and try again.'
	String get network => 'Network connection failed. Please check your connection and try again.';

	/// en: 'Request timed out. Please try again.'
	String get timeout => 'Request timed out. Please try again.';

	/// en: 'Request was cancelled.'
	String get cancelled => 'Request was cancelled.';

	/// en: 'Invalid request. Please check your input.'
	String get badRequest => 'Invalid request. Please check your input.';

	/// en: 'Server error. Please try again later.'
	String get serverError => 'Server error. Please try again later.';

	/// en: 'Session expired. Please sign in again.'
	String get unauthorized => 'Session expired. Please sign in again.';
}

// Path: todoDemo
class Translations$todoDemo$en {
	Translations$todoDemo$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Todo Demo'
	String get title => 'Todo Demo';

	/// en: 'Loading todo...'
	String get loading => 'Loading todo...';

	/// en: 'yes'
	String get completedYes => 'yes';

	/// en: 'no'
	String get completedNo => 'no';

	/// en: 'Completed: ${value}'
	String completedLabel({required Object value}) => 'Completed: ${value}';

	/// en: 'Todo #${id}'
	String todoNumber({required Object id}) => 'Todo #${id}';

	/// en: 'Failed to load todo'
	String get loadFailed => 'Failed to load todo';

	/// en: 'USE_MOCK_API is on — empty/error scenarios run locally.'
	String get mockEnabled => 'USE_MOCK_API is on — empty/error scenarios run locally.';

	/// en: 'USE_MOCK_API is off — success uses the remote API; empty/error still use local mock.'
	String get mockDisabled => 'USE_MOCK_API is off — success uses the remote API; empty/error still use local mock.';

	/// en: 'Success'
	String get scenarioSuccess => 'Success';

	/// en: 'Empty'
	String get scenarioEmpty => 'Empty';

	/// en: 'Error'
	String get scenarioError => 'Error';

	/// en: 'No todo'
	String get emptyTitle => 'No todo';

	/// en: 'This is the empty state for the API demo.'
	String get emptyMessage => 'This is the empty state for the API demo.';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Language'
	String get languageTitle => 'Language';

	/// en: 'English'
	String get english => 'English';

	/// en: 'Chinese'
	String get chinese => 'Chinese';
}

// Path: auth
class Translations$auth$en {
	Translations$auth$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign in'
	String get signInTitle => 'Sign in';

	/// en: 'Dev Sign In'
	String get devSignIn => 'Dev Sign In';

	/// en: 'Writes a fake token so you can verify the auth session skeleton locally.'
	String get devSignInHint => 'Writes a fake token so you can verify the auth session skeleton locally.';

	/// en: 'Sign out'
	String get signOut => 'Sign out';
}

// Path: appUpdate
class Translations$appUpdate$en {
	Translations$appUpdate$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Check update (optional)'
	String get checkOptional => 'Check update (optional)';

	/// en: 'Check update (force)'
	String get checkForce => 'Check update (force)';

	/// en: 'New version available'
	String get updateAvailableTitle => 'New version available';

	/// en: 'Update required'
	String get forceUpdateTitle => 'Update required';

	/// en: 'Version ${version} is available. Update now for the latest fixes and improvements.'
	String updateAvailableDescription({required Object version}) => 'Version ${version} is available. Update now for the latest fixes and improvements.';

	/// en: 'Later'
	String get later => 'Later';

	/// en: 'Update now'
	String get updateNow => 'Update now';

	/// en: 'App store link is unavailable.'
	String get storeUnavailable => 'App store link is unavailable.';

	/// en: 'You're on the latest version.'
	String get upToDate => 'You\'re on the latest version.';
}

// Path: webView
class Translations$webView$en {
	Translations$webView$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Web'
	String get defaultTitle => 'Web';

	/// en: 'Open WebView demo'
	String get openDemo => 'Open WebView demo';

	/// en: 'This link is not allowed: ${url}'
	String linkNotAllowed({required Object url}) => 'This link is not allowed: ${url}';

	/// en: 'Failed to load page'
	String get loadFailed => 'Failed to load page';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Named',
			'app.subtitle' => 'A reusable starter project for Flutter apps.',
			'app.openApiDemo' => 'Open API demo',
			'app.languageSettings' => 'Language',
			'common.loadFailed' => 'Couldn\'t load. Please try again.',
			'common.retry' => 'Retry',
			'common.somethingWentWrong' => 'Something went wrong',
			'common.pleaseTryAgain' => 'Please try again.',
			'common.noDataHere' => 'No data here',
			'common.tryAgain' => 'Try again',
			'common.environment' => 'Environment',
			'common.apiBaseUrl' => 'API Base URL',
			'common.sendCode' => 'Send code',
			'common.sendingCode' => 'Sending...',
			'common.confirm' => 'Confirm',
			'common.cancel' => 'Cancel',
			'notFound.title' => 'Page not found',
			'notFound.description' => 'The page you requested does not exist.',
			'notFound.noRoute' => ({required Object location}) => 'No route matches ${location}.',
			'error.unknown' => 'Something went wrong. Please try again.',
			'error.network' => 'Network connection failed. Please check your connection and try again.',
			'error.timeout' => 'Request timed out. Please try again.',
			'error.cancelled' => 'Request was cancelled.',
			'error.badRequest' => 'Invalid request. Please check your input.',
			'error.serverError' => 'Server error. Please try again later.',
			'error.unauthorized' => 'Session expired. Please sign in again.',
			'todoDemo.title' => 'Todo Demo',
			'todoDemo.loading' => 'Loading todo...',
			'todoDemo.completedYes' => 'yes',
			'todoDemo.completedNo' => 'no',
			'todoDemo.completedLabel' => ({required Object value}) => 'Completed: ${value}',
			'todoDemo.todoNumber' => ({required Object id}) => 'Todo #${id}',
			'todoDemo.loadFailed' => 'Failed to load todo',
			'todoDemo.mockEnabled' => 'USE_MOCK_API is on — empty/error scenarios run locally.',
			'todoDemo.mockDisabled' => 'USE_MOCK_API is off — success uses the remote API; empty/error still use local mock.',
			'todoDemo.scenarioSuccess' => 'Success',
			'todoDemo.scenarioEmpty' => 'Empty',
			'todoDemo.scenarioError' => 'Error',
			'todoDemo.emptyTitle' => 'No todo',
			'todoDemo.emptyMessage' => 'This is the empty state for the API demo.',
			'settings.languageTitle' => 'Language',
			'settings.english' => 'English',
			'settings.chinese' => 'Chinese',
			'auth.signInTitle' => 'Sign in',
			'auth.devSignIn' => 'Dev Sign In',
			'auth.devSignInHint' => 'Writes a fake token so you can verify the auth session skeleton locally.',
			'auth.signOut' => 'Sign out',
			'appUpdate.checkOptional' => 'Check update (optional)',
			'appUpdate.checkForce' => 'Check update (force)',
			'appUpdate.updateAvailableTitle' => 'New version available',
			'appUpdate.forceUpdateTitle' => 'Update required',
			'appUpdate.updateAvailableDescription' => ({required Object version}) => 'Version ${version} is available. Update now for the latest fixes and improvements.',
			'appUpdate.later' => 'Later',
			'appUpdate.updateNow' => 'Update now',
			'appUpdate.storeUnavailable' => 'App store link is unavailable.',
			'appUpdate.upToDate' => 'You\'re on the latest version.',
			'webView.defaultTitle' => 'Web',
			'webView.openDemo' => 'Open WebView demo',
			'webView.linkNotAllowed' => ({required Object url}) => 'This link is not allowed: ${url}',
			'webView.loadFailed' => 'Failed to load page',
			_ => null,
		};
	}
}
