///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZh with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsZh _root = this; // ignore: unused_field

	@override 
	TranslationsZh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZh(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$zh app = _Translations$app$zh._(_root);
	@override late final _Translations$common$zh common = _Translations$common$zh._(_root);
	@override late final _Translations$notFound$zh notFound = _Translations$notFound$zh._(_root);
	@override late final _Translations$error$zh error = _Translations$error$zh._(_root);
	@override late final _Translations$todoDemo$zh todoDemo = _Translations$todoDemo$zh._(_root);
	@override late final _Translations$settings$zh settings = _Translations$settings$zh._(_root);
	@override late final _Translations$auth$zh auth = _Translations$auth$zh._(_root);
	@override late final _Translations$appUpdate$zh appUpdate = _Translations$appUpdate$zh._(_root);
	@override late final _Translations$webView$zh webView = _Translations$webView$zh._(_root);
	@override late final _Translations$explore$zh explore = _Translations$explore$zh._(_root);
	@override late final _Translations$soul$zh soul = _Translations$soul$zh._(_root);
	@override late final _Translations$navigation$zh navigation = _Translations$navigation$zh._(_root);
	@override late final _Translations$write$zh write = _Translations$write$zh._(_root);
	@override late final _Translations$understand$zh understand = _Translations$understand$zh._(_root);
	@override late final _Translations$talk$zh talk = _Translations$talk$zh._(_root);
	@override late final _Translations$timeline$zh timeline = _Translations$timeline$zh._(_root);
	@override late final _Translations$words$zh words = _Translations$words$zh._(_root);
}

// Path: app
class _Translations$app$zh implements Translations$app$en {
	_Translations$app$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get name => 'Named';
	@override String get subtitle => '一个可复用的 Flutter 应用启动模板。';
	@override String get openApiDemo => '打开 API 示例';
	@override String get languageSettings => '语言';
}

// Path: common
class _Translations$common$zh implements Translations$common$en {
	_Translations$common$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get loadFailed => '加载失败，请重试。';
	@override String get retry => '重试';
	@override String get somethingWentWrong => '出了点问题';
	@override String get pleaseTryAgain => '请重试。';
	@override String get noDataHere => '暂无数据';
	@override String get tryAgain => '再试一次';
	@override String get environment => '环境';
	@override String get apiBaseUrl => 'API 地址';
	@override String get sendCode => '发送验证码';
	@override String get sendingCode => '发送中...';
	@override String get confirm => '确认';
	@override String get cancel => '取消';
	@override String get comingSoon => '下一步接入。';
}

// Path: notFound
class _Translations$notFound$zh implements Translations$notFound$en {
	_Translations$notFound$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '页面不存在';
	@override String get description => '你访问的页面不存在。';
	@override String noRoute({required Object location}) => '没有匹配 ${location} 的路由。';
}

// Path: error
class _Translations$error$zh implements Translations$error$en {
	_Translations$error$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get unknown => '出了点问题，请重试。';
	@override String get network => '网络连接失败，请检查网络后重试。';
	@override String get timeout => '请求超时，请重试。';
	@override String get cancelled => '请求已取消。';
	@override String get badRequest => '请求无效，请检查输入。';
	@override String get serverError => '服务器错误，请稍后再试。';
	@override String get unauthorized => '登录已过期，请重新登录。';
}

// Path: todoDemo
class _Translations$todoDemo$zh implements Translations$todoDemo$en {
	_Translations$todoDemo$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => 'Todo 示例';
	@override String get loading => '正在加载 todo...';
	@override String get completedYes => '是';
	@override String get completedNo => '否';
	@override String completedLabel({required Object value}) => '已完成：${value}';
	@override String todoNumber({required Object id}) => 'Todo #${id}';
	@override String get loadFailed => '加载 todo 失败';
	@override String get mockEnabled => 'USE_MOCK_API 已开启 — empty/error 场景走本地 mock。';
	@override String get mockDisabled => 'USE_MOCK_API 已关闭 — success 走远程 API；empty/error 仍用本地 mock。';
	@override String get scenarioSuccess => '成功';
	@override String get scenarioEmpty => '空状态';
	@override String get scenarioError => '错误';
	@override String get emptyTitle => '没有 Todo';
	@override String get emptyMessage => '这是 API 示例的空状态。';
}

// Path: settings
class _Translations$settings$zh implements Translations$settings$en {
	_Translations$settings$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get language => '语言';
	@override String get signOut => '退出登录';
	@override String get languageTitle => '语言';
	@override String get english => 'English';
	@override String get chinese => '中文';
}

// Path: auth
class _Translations$auth$zh implements Translations$auth$en {
	_Translations$auth$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get signInTitle => '登录';
	@override String get devSignIn => '开发登录';
	@override String get devSignInHint => '写入假 token，用于本地验证登录态骨架。';
	@override String get signOut => '退出登录';
	@override String get nativeLanguageIntro => '选择你希望用来理解内容的语言，之后可以修改。';
	@override String get emailIntro => '用邮箱登录，我们会发送 6 位验证码。';
	@override String get nativeLanguage => '母语';
	@override String get nativeLanguageHint => '例如 zh、en、es';
	@override String get continueLabel => '继续';
	@override String get alreadyHaveAccount => '我已有账号';
	@override String get email => '邮箱';
	@override String get emailHint => 'you@example.com';
	@override String get code => '验证码';
	@override String get verify => '验证';
	@override String get verifying => '验证中...';
	@override String get back => '返回';
	@override String get invalidEmail => '请输入有效邮箱。';
	@override String get invalidCode => '请输入 6 位验证码。';
	@override String get nativeLanguageRequired => '请选择母语。';
	@override String get brandEyebrow => '你的日常，用英语命名';
	@override String get languageTitle => '先认识一下你。';
	@override String get emailTitle => '把你的日常，带进英语。';
}

// Path: appUpdate
class _Translations$appUpdate$zh implements Translations$appUpdate$en {
	_Translations$appUpdate$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get checkOptional => '检查更新（可选）';
	@override String get checkForce => '检查更新（强制）';
	@override String get updateAvailableTitle => '发现新版本';
	@override String get forceUpdateTitle => '需要更新';
	@override String updateAvailableDescription({required Object version}) => '新版本 ${version} 已可用，建议立即更新以获得最新修复与改进。';
	@override String get later => '稍后';
	@override String get updateNow => '立即更新';
	@override String get storeUnavailable => '应用商店链接不可用。';
	@override String get upToDate => '已是最新版本。';
}

// Path: webView
class _Translations$webView$zh implements Translations$webView$en {
	_Translations$webView$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get defaultTitle => '网页';
	@override String get openDemo => '打开 WebView 示例';
	@override String linkNotAllowed({required Object url}) => '不允许打开此链接：${url}';
	@override String get loadFailed => '页面加载失败';
}

// Path: explore
class _Translations$explore$zh implements Translations$explore$en {
	_Translations$explore$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get headline => '探索你的世界。';
	@override String get prompt => '今天，什么吸引了你的注意？';
	@override String get capturePhoto => '拍一张';
	@override String get captureTalk => '聊一聊';
	@override String get captureWrite => '写点什么';
	@override String get comingSoon => '这个入口下一步接入。';
	@override String get capturePhotoHint => '今天注意到的一件小事。';
	@override String get recentlyLearned => '最近学到';
	@override String get learnedEmpty => '学过的词和表达会出现在这里。';
	@override String get learnedEmptyHint => '每一次发现，都会让你的世界多一点。';
}

// Path: soul
class _Translations$soul$zh implements Translations$soul$en {
	_Translations$soul$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '我';
	@override String get eyebrow => '我的 SOUL';
	@override String get headline => '你的世界正在生长。';
	@override String get subtitle => '关于你注意到、说出口的事，慢慢留在这里。';
	@override String get profile => '我的 Soul';
	@override String get nativeLanguage => '母语';
	@override String get age => '年龄';
	@override String get gender => '性别';
	@override String get years => '岁';
	@override String get notSet => '未填写';
	@override String get items => '兴趣与偏好';
	@override String get noItems => '编辑时添加几个兴趣。';
	@override String get edit => '修改';
	@override String get editTitle => '编辑你的 Soul';
	@override String get editSubtitle => '这些细节会影响解释的方式。';
	@override String get save => '保存';
	@override String get saving => '保存中...';
	@override String get cancel => '取消';
	@override String get nativeLanguageRequired => '请填写母语。';
	@override String get invalidAge => '请输入有效年龄。';
	@override String get saved => 'Soul 已更新。';
	@override String source({required Object source}) => '来源：${source}';
	@override String get rhythm => '我的节奏';
	@override String get rhythmBody => '挑战会出现在这里。';
}

// Path: navigation
class _Translations$navigation$zh implements Translations$navigation$en {
	_Translations$navigation$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get explore => '探索';
	@override String get words => '词语';
	@override String get history => '回忆';
	@override String get me => '我';
}

// Path: write
class _Translations$write$zh implements Translations$write$en {
	_Translations$write$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '写点什么';
	@override String get headline => '你想理解什么？';
	@override String get subtitle => '写下今天注意到的一个词或一句话。';
	@override String get inputLabel => '词或句子';
	@override String get inputHint => '例如：I noticed a small flower by the road.';
	@override String get submit => '理解';
	@override String get emptyInput => '先写点什么。';
}

// Path: understand
class _Translations$understand$zh implements Translations$understand$en {
	_Translations$understand$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '理解';
	@override String get chooseTitle => '你指的是哪一个？';
	@override String get translation => '意思';
	@override String get example => '例句';
	@override String get grammar => '语法';
	@override String get related => '相关';
	@override String get talk => '聊聊它';
	@override String get talkScene => '聊聊这个场景';
	@override String get talkFailed => '无法开始对话，请重试。';
	@override String get sceneTitle => '一个小场景';
}

// Path: talk
class _Translations$talk$zh implements Translations$talk$en {
	_Translations$talk$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '聊聊';
	@override String get empty => '围绕这个词说一句吧。';
	@override String get inputHint => '说点什么...';
	@override String get send => '发送';
	@override String get failed => '发送失败，请重试。';
}

// Path: timeline
class _Translations$timeline$zh implements Translations$timeline$en {
	_Translations$timeline$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get today => '今天';
	@override String get yesterday => '昨天';
	@override String get loadEarlier => '加载更早';
	@override String get emptyTitle => '今天看到了什么？';
	@override String get emptyCopy => '在下面命名一个东西，它会成为你时间线里的第一张卡片。';
	@override String get emptyHint => '一个词或一句话就够了。';
	@override String get composerHint => '你看到了什么？';
	@override String get send => '发送';
	@override String get nameFailed => '命名失败，请重试。';
	@override String get talk => '聊聊';
	@override String get commonUsage => '常用用法';
	@override String get example => '例句';
	@override String get loadFailed => '时间线加载失败。';
	@override String get talkFailed => '无法开始对话，请重试。';
	@override String get menuTitle => '前往';
	@override String get menuWords => '词语';
	@override String get menuMe => '我';
	@override String get menuSettings => '设置';
	@override String get chunks => '自然搭配';
	@override String get sceneExtensions => '同一场景';
	@override String get usUk => '美式 / 英式';
	@override String get grammar => '语法';
}

// Path: words
class _Translations$words$zh implements Translations$words$en {
	_Translations$words$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '词语';
	@override String get empty => '命名过的词会出现在这里。';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Named',
			'app.subtitle' => '一个可复用的 Flutter 应用启动模板。',
			'app.openApiDemo' => '打开 API 示例',
			'app.languageSettings' => '语言',
			'common.loadFailed' => '加载失败，请重试。',
			'common.retry' => '重试',
			'common.somethingWentWrong' => '出了点问题',
			'common.pleaseTryAgain' => '请重试。',
			'common.noDataHere' => '暂无数据',
			'common.tryAgain' => '再试一次',
			'common.environment' => '环境',
			'common.apiBaseUrl' => 'API 地址',
			'common.sendCode' => '发送验证码',
			'common.sendingCode' => '发送中...',
			'common.confirm' => '确认',
			'common.cancel' => '取消',
			'common.comingSoon' => '下一步接入。',
			'notFound.title' => '页面不存在',
			'notFound.description' => '你访问的页面不存在。',
			'notFound.noRoute' => ({required Object location}) => '没有匹配 ${location} 的路由。',
			'error.unknown' => '出了点问题，请重试。',
			'error.network' => '网络连接失败，请检查网络后重试。',
			'error.timeout' => '请求超时，请重试。',
			'error.cancelled' => '请求已取消。',
			'error.badRequest' => '请求无效，请检查输入。',
			'error.serverError' => '服务器错误，请稍后再试。',
			'error.unauthorized' => '登录已过期，请重新登录。',
			'todoDemo.title' => 'Todo 示例',
			'todoDemo.loading' => '正在加载 todo...',
			'todoDemo.completedYes' => '是',
			'todoDemo.completedNo' => '否',
			'todoDemo.completedLabel' => ({required Object value}) => '已完成：${value}',
			'todoDemo.todoNumber' => ({required Object id}) => 'Todo #${id}',
			'todoDemo.loadFailed' => '加载 todo 失败',
			'todoDemo.mockEnabled' => 'USE_MOCK_API 已开启 — empty/error 场景走本地 mock。',
			'todoDemo.mockDisabled' => 'USE_MOCK_API 已关闭 — success 走远程 API；empty/error 仍用本地 mock。',
			'todoDemo.scenarioSuccess' => '成功',
			'todoDemo.scenarioEmpty' => '空状态',
			'todoDemo.scenarioError' => '错误',
			'todoDemo.emptyTitle' => '没有 Todo',
			'todoDemo.emptyMessage' => '这是 API 示例的空状态。',
			'settings.title' => '设置',
			'settings.language' => '语言',
			'settings.signOut' => '退出登录',
			'settings.languageTitle' => '语言',
			'settings.english' => 'English',
			'settings.chinese' => '中文',
			'auth.signInTitle' => '登录',
			'auth.devSignIn' => '开发登录',
			'auth.devSignInHint' => '写入假 token，用于本地验证登录态骨架。',
			'auth.signOut' => '退出登录',
			'auth.nativeLanguageIntro' => '选择你希望用来理解内容的语言，之后可以修改。',
			'auth.emailIntro' => '用邮箱登录，我们会发送 6 位验证码。',
			'auth.nativeLanguage' => '母语',
			'auth.nativeLanguageHint' => '例如 zh、en、es',
			'auth.continueLabel' => '继续',
			'auth.alreadyHaveAccount' => '我已有账号',
			'auth.email' => '邮箱',
			'auth.emailHint' => 'you@example.com',
			'auth.code' => '验证码',
			'auth.verify' => '验证',
			'auth.verifying' => '验证中...',
			'auth.back' => '返回',
			'auth.invalidEmail' => '请输入有效邮箱。',
			'auth.invalidCode' => '请输入 6 位验证码。',
			'auth.nativeLanguageRequired' => '请选择母语。',
			'auth.brandEyebrow' => '你的日常，用英语命名',
			'auth.languageTitle' => '先认识一下你。',
			'auth.emailTitle' => '把你的日常，带进英语。',
			'appUpdate.checkOptional' => '检查更新（可选）',
			'appUpdate.checkForce' => '检查更新（强制）',
			'appUpdate.updateAvailableTitle' => '发现新版本',
			'appUpdate.forceUpdateTitle' => '需要更新',
			'appUpdate.updateAvailableDescription' => ({required Object version}) => '新版本 ${version} 已可用，建议立即更新以获得最新修复与改进。',
			'appUpdate.later' => '稍后',
			'appUpdate.updateNow' => '立即更新',
			'appUpdate.storeUnavailable' => '应用商店链接不可用。',
			'appUpdate.upToDate' => '已是最新版本。',
			'webView.defaultTitle' => '网页',
			'webView.openDemo' => '打开 WebView 示例',
			'webView.linkNotAllowed' => ({required Object url}) => '不允许打开此链接：${url}',
			'webView.loadFailed' => '页面加载失败',
			'explore.headline' => '探索你的世界。',
			'explore.prompt' => '今天，什么吸引了你的注意？',
			'explore.capturePhoto' => '拍一张',
			'explore.captureTalk' => '聊一聊',
			'explore.captureWrite' => '写点什么',
			'explore.comingSoon' => '这个入口下一步接入。',
			'explore.capturePhotoHint' => '今天注意到的一件小事。',
			'explore.recentlyLearned' => '最近学到',
			'explore.learnedEmpty' => '学过的词和表达会出现在这里。',
			'explore.learnedEmptyHint' => '每一次发现，都会让你的世界多一点。',
			'soul.title' => '我',
			'soul.eyebrow' => '我的 SOUL',
			'soul.headline' => '你的世界正在生长。',
			'soul.subtitle' => '关于你注意到、说出口的事，慢慢留在这里。',
			'soul.profile' => '我的 Soul',
			'soul.nativeLanguage' => '母语',
			'soul.age' => '年龄',
			'soul.gender' => '性别',
			'soul.years' => '岁',
			'soul.notSet' => '未填写',
			'soul.items' => '兴趣与偏好',
			'soul.noItems' => '编辑时添加几个兴趣。',
			'soul.edit' => '修改',
			'soul.editTitle' => '编辑你的 Soul',
			'soul.editSubtitle' => '这些细节会影响解释的方式。',
			'soul.save' => '保存',
			'soul.saving' => '保存中...',
			'soul.cancel' => '取消',
			'soul.nativeLanguageRequired' => '请填写母语。',
			'soul.invalidAge' => '请输入有效年龄。',
			'soul.saved' => 'Soul 已更新。',
			'soul.source' => ({required Object source}) => '来源：${source}',
			'soul.rhythm' => '我的节奏',
			'soul.rhythmBody' => '挑战会出现在这里。',
			'navigation.explore' => '探索',
			'navigation.words' => '词语',
			'navigation.history' => '回忆',
			'navigation.me' => '我',
			'write.title' => '写点什么',
			'write.headline' => '你想理解什么？',
			'write.subtitle' => '写下今天注意到的一个词或一句话。',
			'write.inputLabel' => '词或句子',
			'write.inputHint' => '例如：I noticed a small flower by the road.',
			'write.submit' => '理解',
			'write.emptyInput' => '先写点什么。',
			'understand.title' => '理解',
			'understand.chooseTitle' => '你指的是哪一个？',
			'understand.translation' => '意思',
			'understand.example' => '例句',
			'understand.grammar' => '语法',
			'understand.related' => '相关',
			'understand.talk' => '聊聊它',
			'understand.talkScene' => '聊聊这个场景',
			'understand.talkFailed' => '无法开始对话，请重试。',
			'understand.sceneTitle' => '一个小场景',
			'talk.title' => '聊聊',
			'talk.empty' => '围绕这个词说一句吧。',
			'talk.inputHint' => '说点什么...',
			'talk.send' => '发送',
			'talk.failed' => '发送失败，请重试。',
			'timeline.today' => '今天',
			'timeline.yesterday' => '昨天',
			'timeline.loadEarlier' => '加载更早',
			'timeline.emptyTitle' => '今天看到了什么？',
			'timeline.emptyCopy' => '在下面命名一个东西，它会成为你时间线里的第一张卡片。',
			'timeline.emptyHint' => '一个词或一句话就够了。',
			'timeline.composerHint' => '你看到了什么？',
			'timeline.send' => '发送',
			'timeline.nameFailed' => '命名失败，请重试。',
			'timeline.talk' => '聊聊',
			'timeline.commonUsage' => '常用用法',
			'timeline.example' => '例句',
			'timeline.loadFailed' => '时间线加载失败。',
			'timeline.talkFailed' => '无法开始对话，请重试。',
			'timeline.menuTitle' => '前往',
			'timeline.menuWords' => '词语',
			'timeline.menuMe' => '我',
			'timeline.menuSettings' => '设置',
			'timeline.chunks' => '自然搭配',
			'timeline.sceneExtensions' => '同一场景',
			'timeline.usUk' => '美式 / 英式',
			'timeline.grammar' => '语法',
			'words.title' => '词语',
			'words.empty' => '命名过的词会出现在这里。',
			_ => null,
		};
	}
}
