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
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

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
	late final Translations$explore$en explore = Translations$explore$en._(_root);
	late final Translations$soul$en soul = Translations$soul$en._(_root);
	late final Translations$navigation$en navigation = Translations$navigation$en._(_root);
	late final Translations$write$en write = Translations$write$en._(_root);
	late final Translations$understand$en understand = Translations$understand$en._(_root);
	late final Translations$talk$en talk = Translations$talk$en._(_root);
	late final Translations$timeline$en timeline = Translations$timeline$en._(_root);
	late final Translations$words$en words = Translations$words$en._(_root);
	late final Translations$review$en review = Translations$review$en._(_root);
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

	/// en: 'Coming next.'
	String get comingSoon => 'Coming next.';
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

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Theme'
	String get themeTitle => 'Theme';

	/// en: 'Ink & Cobalt'
	String get themeCobalt => 'Ink & Cobalt';

	/// en: 'Clean and modern'
	String get themeCobaltDescription => 'Clean and modern';

	/// en: 'Ink & Parchment'
	String get themeParchment => 'Ink & Parchment';

	/// en: 'Warm and editorial'
	String get themeParchmentDescription => 'Warm and editorial';

	/// en: 'Plum & Sand'
	String get themePlum => 'Plum & Sand';

	/// en: 'Distinctive and warm'
	String get themePlumDescription => 'Distinctive and warm';

	/// en: 'Default'
	String get defaultLabel => 'Default';

	/// en: 'Sign out'
	String get signOut => 'Sign out';

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

	/// en: 'Choose the language you want explanations in. You can change it later.'
	String get nativeLanguageIntro => 'Choose the language you want explanations in. You can change it later.';

	/// en: 'Sign in with your email. We will send a 6-digit code.'
	String get emailIntro => 'Sign in with your email. We will send a 6-digit code.';

	/// en: 'Native language'
	String get nativeLanguage => 'Native language';

	/// en: 'e.g. zh, en, es'
	String get nativeLanguageHint => 'e.g. zh, en, es';

	/// en: 'Continue'
	String get continueLabel => 'Continue';

	/// en: 'I already have an account'
	String get alreadyHaveAccount => 'I already have an account';

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'you@example.com'
	String get emailHint => 'you@example.com';

	/// en: 'Verification code'
	String get code => 'Verification code';

	/// en: 'Verify'
	String get verify => 'Verify';

	/// en: 'Verifying...'
	String get verifying => 'Verifying...';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Enter a valid email.'
	String get invalidEmail => 'Enter a valid email.';

	/// en: 'Enter the 6-digit code.'
	String get invalidCode => 'Enter the 6-digit code.';

	/// en: 'Choose your native language.'
	String get nativeLanguageRequired => 'Choose your native language.';

	/// en: 'YOUR EVERYDAY, IN ENGLISH'
	String get brandEyebrow => 'YOUR EVERYDAY, IN ENGLISH';

	/// en: 'Let’s start with you.'
	String get languageTitle => 'Let’s start with you.';

	/// en: 'Your everyday, in English.'
	String get emailTitle => 'Your everyday, in English.';
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

// Path: explore
class Translations$explore$en {
	Translations$explore$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Explore your world.'
	String get headline => 'Explore your world.';

	/// en: 'What caught your attention today?'
	String get prompt => 'What caught your attention today?';

	/// en: 'Take a photo'
	String get capturePhoto => 'Take a photo';

	/// en: 'Talk'
	String get captureTalk => 'Talk';

	/// en: 'Write'
	String get captureWrite => 'Write';

	/// en: 'This step is coming next.'
	String get comingSoon => 'This step is coming next.';

	/// en: 'A small thing you noticed today.'
	String get capturePhotoHint => 'A small thing you noticed today.';

	/// en: 'Recently learned'
	String get recentlyLearned => 'Recently learned';

	/// en: 'Words and expressions you learn will appear here.'
	String get learnedEmpty => 'Words and expressions you learn will appear here.';

	/// en: 'Every discovery adds a little to your world.'
	String get learnedEmptyHint => 'Every discovery adds a little to your world.';
}

// Path: soul
class Translations$soul$en {
	Translations$soul$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Me'
	String get title => 'Me';

	/// en: 'MY SOUL'
	String get eyebrow => 'MY SOUL';

	/// en: 'Your world is growing.'
	String get headline => 'Your world is growing.';

	/// en: 'A quiet record of what you noticed and said.'
	String get subtitle => 'A quiet record of what you noticed and said.';

	/// en: 'My Soul'
	String get profile => 'My Soul';

	/// en: 'Native language'
	String get nativeLanguage => 'Native language';

	/// en: 'Age'
	String get age => 'Age';

	/// en: 'Gender'
	String get gender => 'Gender';

	/// en: 'years'
	String get years => 'years';

	/// en: 'Not set'
	String get notSet => 'Not set';

	/// en: 'Interests and preferences'
	String get items => 'Interests and preferences';

	/// en: 'Add a few interests when you edit.'
	String get noItems => 'Add a few interests when you edit.';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Edit your Soul'
	String get editTitle => 'Edit your Soul';

	/// en: 'These details shape how explanations sound.'
	String get editSubtitle => 'These details shape how explanations sound.';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Saving...'
	String get saving => 'Saving...';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Native language is required.'
	String get nativeLanguageRequired => 'Native language is required.';

	/// en: 'Enter a valid age.'
	String get invalidAge => 'Enter a valid age.';

	/// en: 'Soul updated.'
	String get saved => 'Soul updated.';

	/// en: 'Source: ${source}'
	String source({required Object source}) => 'Source: ${source}';

	/// en: 'My rhythm'
	String get rhythm => 'My rhythm';

	/// en: 'Challenges will appear here.'
	String get rhythmBody => 'Challenges will appear here.';
}

// Path: navigation
class Translations$navigation$en {
	Translations$navigation$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Explore'
	String get explore => 'Explore';

	/// en: 'Words'
	String get words => 'Words';

	/// en: 'History'
	String get history => 'History';

	/// en: 'Me'
	String get me => 'Me';
}

// Path: write
class Translations$write$en {
	Translations$write$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Write'
	String get title => 'Write';

	/// en: 'What do you want to understand?'
	String get headline => 'What do you want to understand?';

	/// en: 'Write a word or a sentence you noticed today.'
	String get subtitle => 'Write a word or a sentence you noticed today.';

	/// en: 'Word or sentence'
	String get inputLabel => 'Word or sentence';

	/// en: 'e.g. I noticed a small flower by the road.'
	String get inputHint => 'e.g. I noticed a small flower by the road.';

	/// en: 'Understand'
	String get submit => 'Understand';

	/// en: 'Write something first.'
	String get emptyInput => 'Write something first.';
}

// Path: understand
class Translations$understand$en {
	Translations$understand$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Understand'
	String get title => 'Understand';

	/// en: 'Which one did you mean?'
	String get chooseTitle => 'Which one did you mean?';

	/// en: 'Meaning'
	String get translation => 'Meaning';

	/// en: 'Example'
	String get example => 'Example';

	/// en: 'Related'
	String get related => 'Related';

	/// en: 'Talk about it'
	String get talk => 'Talk about it';

	/// en: 'Talk about this scene'
	String get talkScene => 'Talk about this scene';

	/// en: 'Could not start the conversation. Try again.'
	String get talkFailed => 'Could not start the conversation. Try again.';

	/// en: 'A small scene'
	String get sceneTitle => 'A small scene';
}

// Path: talk
class Translations$talk$en {
	Translations$talk$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Talk'
	String get title => 'Talk';

	/// en: 'Start with a sentence about this moment.'
	String get emptyScene => 'Start with a sentence about this moment.';

	/// en: 'Start with a sentence about this word.'
	String get empty => 'Start with a sentence about this word.';

	/// en: 'Say something...'
	String get inputHint => 'Say something...';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Could not send. Try again.'
	String get failed => 'Could not send. Try again.';

	/// en: 'Listen'
	String get playReply => 'Listen';

	/// en: 'Pause'
	String get pauseReply => 'Pause';

	/// en: 'Help me say it'
	String get helpMeSayIt => 'Help me say it';

	/// en: 'Help me say it'
	String get helpTitle => 'Help me say it';

	/// en: 'Say it in Chinese or rough English. I’ll help you put it into natural English.'
	String get helpSubtitle => 'Say it in Chinese or rough English. I’ll help you put it into natural English.';

	/// en: 'What do you want to say?'
	String get helpInputLabel => 'What do you want to say?';

	/// en: 'e.g. 我想说这棵树很漂亮'
	String get helpInputHint => 'e.g. 我想说这棵树很漂亮';

	/// en: 'Find the words'
	String get helpAsk => 'Find the words';

	/// en: 'Finding the words...'
	String get helpThinking => 'Finding the words...';

	/// en: 'You can say'
	String get helpResultTitle => 'You can say';

	/// en: 'Use this'
	String get helpUseThis => 'Use this';

	/// en: 'Another way'
	String get helpAnotherWay => 'Another way';

	/// en: 'Could not help with that. Try again.'
	String get helpFailed => 'Could not help with that. Try again.';

	/// en: 'Write something first.'
	String get helpEmptyInput => 'Write something first.';

	/// en: 'Audio is unavailable.'
	String get audioUnavailable => 'Audio is unavailable.';

	/// en: 'Conversation'
	String get titleFallback => 'Conversation';

	/// en: 'Milo'
	String get miloName => 'Milo';

	/// en: 'Milo'
	String get miloAvatar => 'Milo';

	/// en: 'You'
	String get youAvatar => 'You';

	/// en: 'Milo is typing...'
	String get typing => 'Milo is typing...';

	/// en: 'Word'
	String get wordSheetTitle => 'Word';

	/// en: 'Expression'
	String get expressionSheetTitle => 'Expression';

	/// en: 'Grammar note'
	String get grammarSheetTitle => 'Grammar note';

	/// en: 'Part of speech'
	String get partOfSpeech => 'Part of speech';

	/// en: 'Pattern'
	String get grammarPattern => 'Pattern';

	/// en: 'Add to Words'
	String get addToWords => 'Add to Words';

	/// en: 'Added to Words'
	String get addedToWords => 'Added to Words';

	/// en: 'Could not add. Try again.'
	String get addFailed => 'Could not add. Try again.';

	/// en: 'Got it'
	String get gotIt => 'Got it';

	/// en: '中'
	String get nativeShort => '中';

	/// en: 'Show Chinese'
	String get showNative => 'Show Chinese';

	/// en: 'Hide Chinese'
	String get hideNative => 'Hide Chinese';

	/// en: 'Playback speed'
	String get speed => 'Playback speed';

	/// en: 'A more natural way'
	String get naturalWay => 'A more natural way';

	/// en: 'You wrote'
	String get youWrote => 'You wrote';

	/// en: 'Use this'
	String get useThis => 'Use this';
}

// Path: timeline
class Translations$timeline$en {
	Translations$timeline$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Today'
	String get today => 'Today';

	/// en: 'Yesterday'
	String get yesterday => 'Yesterday';

	/// en: 'Load earlier'
	String get loadEarlier => 'Load earlier';

	/// en: 'What did you see today?'
	String get emptyTitle => 'What did you see today?';

	/// en: 'Name one thing below. It becomes the first card in your timeline.'
	String get emptyCopy => 'Name one thing below. It becomes the first card in your timeline.';

	/// en: 'A word or a short sentence is enough.'
	String get emptyHint => 'A word or a short sentence is enough.';

	/// en: 'What did you see?'
	String get composerHint => 'What did you see?';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Could not name that. Try again.'
	String get nameFailed => 'Could not name that. Try again.';

	/// en: 'Common usage'
	String get commonUsage => 'Common usage';

	/// en: 'Example'
	String get example => 'Example';

	/// en: 'Could not load your timeline.'
	String get loadFailed => 'Could not load your timeline.';

	/// en: 'Could not start the conversation. Try again.'
	String get talkFailed => 'Could not start the conversation. Try again.';

	/// en: 'Review 3'
	String get menuReview => 'Review 3';

	/// en: 'Go to'
	String get menuTitle => 'Go to';

	/// en: 'Words'
	String get menuWords => 'Words';

	/// en: 'Me'
	String get menuMe => 'Me';

	/// en: 'Settings'
	String get menuSettings => 'Settings';

	/// en: 'Natural chunks'
	String get chunks => 'Natural chunks';

	/// en: 'Talk about it'
	String get talkAboutIt => 'Talk about it';

	/// en: 'In this scene'
	String get sceneExtensions => 'In this scene';

	/// en: 'US / UK'
	String get usUk => 'US / UK';

	/// en: 'Grammar'
	String get grammar => 'Grammar';

	/// en: 'More details'
	String get moreDetails => 'More details';

	/// en: 'Word details'
	String get wordDetails => 'Word details';

	/// en: 'Play sentence'
	String get playMoment => 'Play sentence';

	/// en: 'Pause sentence'
	String get pauseMoment => 'Pause sentence';

	/// en: 'Play word'
	String get play => 'Play word';

	/// en: 'Pause word'
	String get pause => 'Pause word';

	/// en: 'Playback speed'
	String get speed => 'Playback speed';

	/// en: 'Audio is unavailable.'
	String get audioUnavailable => 'Audio is unavailable.';
}

// Path: words
class Translations$words$en {
	Translations$words$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Words'
	String get title => 'Words';

	/// en: 'Your words'
	String get yourWords => 'Your words';

	/// en: '${count} words'
	String totalWords({required Object count}) => '${count} words';

	/// en: '+${count} this week'
	String newThisWeek({required Object count}) => '+${count} this week';

	/// en: '${count} reviewed'
	String reviewedThisWeek({required Object count}) => '${count} reviewed';

	/// en: '${count} used in Talk'
	String usedInTalkThisWeek({required Object count}) => '${count} used in Talk';

	/// en: 'Needs a revisit'
	String get needsReview => 'Needs a revisit';

	/// en: 'Growing'
	String get growing => 'Growing';

	/// en: 'Known'
	String get known => 'Known';

	/// en: 'Show known'
	String get showKnown => 'Show known';

	/// en: 'Hide known'
	String get hideKnown => 'Hide known';

	/// en: 'Review 3'
	String get review3 => 'Review 3';

	/// en: 'I know this'
	String get knowThis => 'I know this';

	/// en: 'Still learning'
	String get stillLearning => 'Still learning';

	/// en: 'seen ${count}×'
	String seenTimes({required Object count}) => 'seen ${count}×';

	/// en: 'Could not load your words.'
	String get loadFailed => 'Could not load your words.';

	/// en: 'Named words will appear here.'
	String get empty => 'Named words will appear here.';
}

// Path: review
class Translations$review$en {
	Translations$review$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Review 3'
	String get title => 'Review 3';

	/// en: 'Do you remember?'
	String get prompt => 'Do you remember?';

	/// en: 'Show meaning'
	String get showMeaning => 'Show meaning';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Finish'
	String get finish => 'Finish';

	/// en: 'Review complete'
	String get completeTitle => 'Review complete';

	/// en: 'A small review is enough for today.'
	String get completeCopy => 'A small review is enough for today.';

	/// en: 'Back to timeline'
	String get backToTimeline => 'Back to timeline';

	/// en: 'Nothing to review yet'
	String get emptyTitle => 'Nothing to review yet';

	/// en: 'Name something first. Your words will appear here for review.'
	String get emptyCopy => 'Name something first. Your words will appear here for review.';

	/// en: 'Could not load your review.'
	String get loadFailed => 'Could not load your review.';
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
			'common.comingSoon' => 'Coming next.',
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
			'settings.title' => 'Settings',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.themeTitle' => 'Theme',
			'settings.themeCobalt' => 'Ink & Cobalt',
			'settings.themeCobaltDescription' => 'Clean and modern',
			'settings.themeParchment' => 'Ink & Parchment',
			'settings.themeParchmentDescription' => 'Warm and editorial',
			'settings.themePlum' => 'Plum & Sand',
			'settings.themePlumDescription' => 'Distinctive and warm',
			'settings.defaultLabel' => 'Default',
			'settings.signOut' => 'Sign out',
			'settings.languageTitle' => 'Language',
			'settings.english' => 'English',
			'settings.chinese' => 'Chinese',
			'auth.signInTitle' => 'Sign in',
			'auth.devSignIn' => 'Dev Sign In',
			'auth.devSignInHint' => 'Writes a fake token so you can verify the auth session skeleton locally.',
			'auth.signOut' => 'Sign out',
			'auth.nativeLanguageIntro' => 'Choose the language you want explanations in. You can change it later.',
			'auth.emailIntro' => 'Sign in with your email. We will send a 6-digit code.',
			'auth.nativeLanguage' => 'Native language',
			'auth.nativeLanguageHint' => 'e.g. zh, en, es',
			'auth.continueLabel' => 'Continue',
			'auth.alreadyHaveAccount' => 'I already have an account',
			'auth.email' => 'Email',
			'auth.emailHint' => 'you@example.com',
			'auth.code' => 'Verification code',
			'auth.verify' => 'Verify',
			'auth.verifying' => 'Verifying...',
			'auth.back' => 'Back',
			'auth.invalidEmail' => 'Enter a valid email.',
			'auth.invalidCode' => 'Enter the 6-digit code.',
			'auth.nativeLanguageRequired' => 'Choose your native language.',
			'auth.brandEyebrow' => 'YOUR EVERYDAY, IN ENGLISH',
			'auth.languageTitle' => 'Let’s start with you.',
			'auth.emailTitle' => 'Your everyday, in English.',
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
			'explore.headline' => 'Explore your world.',
			'explore.prompt' => 'What caught your attention today?',
			'explore.capturePhoto' => 'Take a photo',
			'explore.captureTalk' => 'Talk',
			'explore.captureWrite' => 'Write',
			'explore.comingSoon' => 'This step is coming next.',
			'explore.capturePhotoHint' => 'A small thing you noticed today.',
			'explore.recentlyLearned' => 'Recently learned',
			'explore.learnedEmpty' => 'Words and expressions you learn will appear here.',
			'explore.learnedEmptyHint' => 'Every discovery adds a little to your world.',
			'soul.title' => 'Me',
			'soul.eyebrow' => 'MY SOUL',
			'soul.headline' => 'Your world is growing.',
			'soul.subtitle' => 'A quiet record of what you noticed and said.',
			'soul.profile' => 'My Soul',
			'soul.nativeLanguage' => 'Native language',
			'soul.age' => 'Age',
			'soul.gender' => 'Gender',
			'soul.years' => 'years',
			'soul.notSet' => 'Not set',
			'soul.items' => 'Interests and preferences',
			'soul.noItems' => 'Add a few interests when you edit.',
			'soul.edit' => 'Edit',
			'soul.editTitle' => 'Edit your Soul',
			'soul.editSubtitle' => 'These details shape how explanations sound.',
			'soul.save' => 'Save',
			'soul.saving' => 'Saving...',
			'soul.cancel' => 'Cancel',
			'soul.nativeLanguageRequired' => 'Native language is required.',
			'soul.invalidAge' => 'Enter a valid age.',
			'soul.saved' => 'Soul updated.',
			'soul.source' => ({required Object source}) => 'Source: ${source}',
			'soul.rhythm' => 'My rhythm',
			'soul.rhythmBody' => 'Challenges will appear here.',
			'navigation.explore' => 'Explore',
			'navigation.words' => 'Words',
			'navigation.history' => 'History',
			'navigation.me' => 'Me',
			'write.title' => 'Write',
			'write.headline' => 'What do you want to understand?',
			'write.subtitle' => 'Write a word or a sentence you noticed today.',
			'write.inputLabel' => 'Word or sentence',
			'write.inputHint' => 'e.g. I noticed a small flower by the road.',
			'write.submit' => 'Understand',
			'write.emptyInput' => 'Write something first.',
			'understand.title' => 'Understand',
			'understand.chooseTitle' => 'Which one did you mean?',
			'understand.translation' => 'Meaning',
			'understand.example' => 'Example',
			'understand.related' => 'Related',
			'understand.talk' => 'Talk about it',
			'understand.talkScene' => 'Talk about this scene',
			'understand.talkFailed' => 'Could not start the conversation. Try again.',
			'understand.sceneTitle' => 'A small scene',
			'talk.title' => 'Talk',
			'talk.emptyScene' => 'Start with a sentence about this moment.',
			'talk.empty' => 'Start with a sentence about this word.',
			'talk.inputHint' => 'Say something...',
			'talk.send' => 'Send',
			'talk.failed' => 'Could not send. Try again.',
			'talk.playReply' => 'Listen',
			'talk.pauseReply' => 'Pause',
			'talk.helpMeSayIt' => 'Help me say it',
			'talk.helpTitle' => 'Help me say it',
			'talk.helpSubtitle' => 'Say it in Chinese or rough English. I’ll help you put it into natural English.',
			'talk.helpInputLabel' => 'What do you want to say?',
			'talk.helpInputHint' => 'e.g. 我想说这棵树很漂亮',
			'talk.helpAsk' => 'Find the words',
			'talk.helpThinking' => 'Finding the words...',
			'talk.helpResultTitle' => 'You can say',
			'talk.helpUseThis' => 'Use this',
			'talk.helpAnotherWay' => 'Another way',
			'talk.helpFailed' => 'Could not help with that. Try again.',
			'talk.helpEmptyInput' => 'Write something first.',
			'talk.audioUnavailable' => 'Audio is unavailable.',
			'talk.titleFallback' => 'Conversation',
			'talk.miloName' => 'Milo',
			'talk.miloAvatar' => 'Milo',
			'talk.youAvatar' => 'You',
			'talk.typing' => 'Milo is typing...',
			'talk.wordSheetTitle' => 'Word',
			'talk.expressionSheetTitle' => 'Expression',
			'talk.grammarSheetTitle' => 'Grammar note',
			'talk.partOfSpeech' => 'Part of speech',
			'talk.grammarPattern' => 'Pattern',
			'talk.addToWords' => 'Add to Words',
			'talk.addedToWords' => 'Added to Words',
			'talk.addFailed' => 'Could not add. Try again.',
			'talk.gotIt' => 'Got it',
			'talk.nativeShort' => '中',
			'talk.showNative' => 'Show Chinese',
			'talk.hideNative' => 'Hide Chinese',
			'talk.speed' => 'Playback speed',
			'talk.naturalWay' => 'A more natural way',
			'talk.youWrote' => 'You wrote',
			'talk.useThis' => 'Use this',
			'timeline.today' => 'Today',
			'timeline.yesterday' => 'Yesterday',
			'timeline.loadEarlier' => 'Load earlier',
			'timeline.emptyTitle' => 'What did you see today?',
			'timeline.emptyCopy' => 'Name one thing below. It becomes the first card in your timeline.',
			'timeline.emptyHint' => 'A word or a short sentence is enough.',
			'timeline.composerHint' => 'What did you see?',
			'timeline.send' => 'Send',
			'timeline.nameFailed' => 'Could not name that. Try again.',
			'timeline.commonUsage' => 'Common usage',
			'timeline.example' => 'Example',
			'timeline.loadFailed' => 'Could not load your timeline.',
			'timeline.talkFailed' => 'Could not start the conversation. Try again.',
			'timeline.menuReview' => 'Review 3',
			'timeline.menuTitle' => 'Go to',
			'timeline.menuWords' => 'Words',
			'timeline.menuMe' => 'Me',
			'timeline.menuSettings' => 'Settings',
			'timeline.chunks' => 'Natural chunks',
			'timeline.talkAboutIt' => 'Talk about it',
			'timeline.sceneExtensions' => 'In this scene',
			'timeline.usUk' => 'US / UK',
			'timeline.grammar' => 'Grammar',
			'timeline.moreDetails' => 'More details',
			'timeline.wordDetails' => 'Word details',
			'timeline.playMoment' => 'Play sentence',
			'timeline.pauseMoment' => 'Pause sentence',
			'timeline.play' => 'Play word',
			'timeline.pause' => 'Pause word',
			'timeline.speed' => 'Playback speed',
			'timeline.audioUnavailable' => 'Audio is unavailable.',
			'words.title' => 'Words',
			'words.yourWords' => 'Your words',
			'words.totalWords' => ({required Object count}) => '${count} words',
			'words.newThisWeek' => ({required Object count}) => '+${count} this week',
			'words.reviewedThisWeek' => ({required Object count}) => '${count} reviewed',
			'words.usedInTalkThisWeek' => ({required Object count}) => '${count} used in Talk',
			'words.needsReview' => 'Needs a revisit',
			'words.growing' => 'Growing',
			'words.known' => 'Known',
			'words.showKnown' => 'Show known',
			'words.hideKnown' => 'Hide known',
			'words.review3' => 'Review 3',
			'words.knowThis' => 'I know this',
			'words.stillLearning' => 'Still learning',
			'words.seenTimes' => ({required Object count}) => 'seen ${count}×',
			'words.loadFailed' => 'Could not load your words.',
			'words.empty' => 'Named words will appear here.',
			'review.title' => 'Review 3',
			'review.prompt' => 'Do you remember?',
			'review.showMeaning' => 'Show meaning',
			'review.next' => 'Next',
			'review.finish' => 'Finish',
			'review.completeTitle' => 'Review complete',
			'review.completeCopy' => 'A small review is enough for today.',
			'review.backToTimeline' => 'Back to timeline',
			'review.emptyTitle' => 'Nothing to review yet',
			'review.emptyCopy' => 'Name something first. Your words will appear here for review.',
			'review.loadFailed' => 'Could not load your review.',
			_ => null,
		};
	}
}
