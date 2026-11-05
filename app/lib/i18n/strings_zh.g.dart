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
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key);

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
			'settings.languageTitle' => '语言',
			'settings.english' => 'English',
			'settings.chinese' => '中文',
			'auth.signInTitle' => '登录',
			'auth.devSignIn' => '开发登录',
			'auth.devSignInHint' => '写入假 token，用于本地验证登录态骨架。',
			'auth.signOut' => '退出登录',
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
			_ => null,
		};
	}
}
