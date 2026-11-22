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
	@override late final _Translations$history$zh history = _Translations$history$zh._(_root);
	@override late final _Translations$challenge$zh challenge = _Translations$challenge$zh._(_root);
	@override late final _Translations$daily$zh daily = _Translations$daily$zh._(_root);
	@override late final _Translations$ask$zh ask = _Translations$ask$zh._(_root);
}

// Path: app
class _Translations$app$zh implements Translations$app$en {
	_Translations$app$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get name => 'Named';
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
	@override String get theme => '主题';
	@override String get themeTitle => '主题';
	@override String get themeCobalt => '墨蓝';
	@override String get themeCobaltDescription => '干净、现代';
	@override String get themeParchment => '墨色纸张';
	@override String get themeParchmentDescription => '温暖、编辑感';
	@override String get themePlum => '梅子与沙';
	@override String get themePlumDescription => '有个性、温暖';
	@override String get themeSky => '墨与亚麻';
	@override String get themeSkyDescription => '素净、明亮';
	@override String get defaultLabel => '默认';
	@override String get signOut => '退出登录';
	@override String get languageTitle => '语言';
	@override String get english => 'English';
	@override String get chinese => '中文';
	@override String get reminder => '每日提醒';
	@override String get reminderHint => '故事准备好时，轻轻提醒你。';
	@override String get reminderTime => '提醒时间';
	@override String get notificationsDenied => '通知权限未开启，请在系统设置中允许通知。';
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
	@override String get codeSentTo => '验证码已发送至 {email}';
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
	@override String get headline => '你的世界正在生长。';
	@override String get subtitle => '关于你注意到、说出口的事，慢慢留在这里。';
	@override String get profileTitle => '资料';
	@override String get notes => 'Soul 笔记';
	@override String get add => '添加';
	@override String get nativeLanguageShort => '母语';
	@override String get nativeLanguage => '母语';
	@override String get age => '年龄';
	@override String get gender => '性别';
	@override String get years => '岁';
	@override String get notSet => '未填写';
	@override String get noItems => '还没有笔记。';
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
	@override String get rhythmBody => '挑战会出现在这里。';
	@override String get library => '你的收藏';
	@override String get wordsBody => '从经历里留下的词语。';
	@override String get historyBody => '值得回看的经历。';
	@override String get addItem => '添加一条';
	@override String get itemText => '想让我记住什么？';
	@override String get itemRequired => '请先填写内容。';
	@override String get editItemTitle => '编辑这一条';
	@override String get deleteItem => '删除';
	@override String get deleteConfirmTitle => '删除这一条？';
	@override String get deleteConfirmBody => '它不再影响之后的交流。';
	@override String get deleted => '已删除。';
	@override String get sourceOnboarding => '初始引导';
	@override String get sourceUser => '你填写的';
	@override String get sourceAi => 'AI 提炼';
	@override String get memoryLabel => '使用我的 Soul';
	@override String get memoryHint => '关闭后，这次对话不使用已保存的背景。';
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
	@override String get challenge => '挑战';
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
	@override String get emptyScene => '围绕这个场景说一句吧。';
	@override String get empty => '从这个词说一句话开始。';
	@override String get inputHint => '说点什么...';
	@override String get send => '发送';
	@override String get failed => '发送失败，请重试。';
	@override String get playReply => '听语音';
	@override String get pauseReply => '暂停';
	@override String get helpMeSayIt => '帮我表达';
	@override String get helpTitle => '帮我表达';
	@override String get helpSubtitle => '用中文或还不完整的英文说出来，我帮你整理成自然的英文。';
	@override String get helpInputLabel => '你想说什么？';
	@override String get helpInputHint => '例如：我想说这棵树很漂亮';
	@override String get helpAsk => '帮我找词';
	@override String get helpThinking => '正在组织表达...';
	@override String get helpResultTitle => '可以这样说';
	@override String get helpUseThis => '用这句';
	@override String get helpAnotherWay => '换一种说法';
	@override String get helpFailed => '暂时没能帮你组织这句话，请重试。';
	@override String get helpEmptyInput => '先写一句想说的话。';
	@override String get audioUnavailable => '音频暂时不可用。';
	@override String get titleFallback => '对话';
	@override String get miloName => 'Milo';
	@override String get miloAvatar => 'Milo';
	@override String get youAvatar => '你';
	@override String get typing => 'Milo 正在输入...';
	@override String get wordSheetTitle => '词义';
	@override String get expressionSheetTitle => '表达';
	@override String get grammarSheetTitle => '语法提示';
	@override String get partOfSpeech => '词性';
	@override String get pronunciation => '发音';
	@override String get ipa => '音标';
	@override String get syllables => '音节';
	@override String get vowels => '元音';
	@override String get consonants => '辅音';
	@override String get phonics => '自然拼读';
	@override String get playPronunciation => '听发音';
	@override String get pausePronunciation => '暂停';
	@override String get speak => '说话';
	@override String get listening => '正在听你说...';
	@override String get transcribing => '正在转写...';
	@override String get stopRecording => '停止录音';
	@override String get microphoneDenied => '需要麦克风权限。';
	@override String get grammarPattern => '结构';
	@override String get addToWords => '加入词语';
	@override String get addedToWords => '已加入词语';
	@override String get addFailed => '加入失败，请重试。';
	@override String get nativeShort => '中';
	@override String get showNative => '显示中文';
	@override String get hideNative => '隐藏中文';
	@override String get englishHint => '更准确的英文';
	@override String get speed => '播放速度';
	@override String get naturalWay => '更自然的说法';
	@override String get youWrote => '你写的是';
	@override String get useThis => '用这句';
	@override String get copy => '复制';
	@override String get copied => '已复制';
	@override String get sentenceDetails => '句子详情';
	@override String get sentenceLoadFailed => '暂时无法加载这句话。';
	@override String get explanation => '说明';
	@override String get grammarNotes => '结构';
	@override String get chunks => '表达片段';
	@override String get keyWords => '关键词';
	@override String get copyEnglish => '复制英文';
	@override String get memoryLabel => '使用我的记忆';
	@override String get memoryHint => '关闭后，这次对话不使用已保存的背景。';
}

// Path: timeline
class _Translations$timeline$zh implements Translations$timeline$en {
	_Translations$timeline$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get today => '今天';
	@override String get yesterday => '昨天';
	@override String get emptyTitle => '今天看到了什么？';
	@override String get emptyCopy => '在下面命名一个东西，它会成为你时间线里的第一张卡片。';
	@override String get emptyHint => '一个词或一句话就够了。';
	@override String get composerHint => '你看到了什么？';
	@override String get send => '发送';
	@override String get nameFailed => '命名失败，请重试。';
	@override String get commonUsage => '常用用法';
	@override String get example => '例句';
	@override String get loadFailed => '时间线加载失败。';
	@override String get talkFailed => '无法开始对话，请重试。';
	@override String get chunks => '自然搭配';
	@override String get talkAboutIt => '聊聊它';
	@override String get sceneExtensions => '同一场景';
	@override String get usUk => '美式 / 英式';
	@override String get grammar => '语法';
	@override String get moreDetails => '更多内容';
	@override String get wordDetails => '词语详情';
	@override String get playMoment => '播放句子';
	@override String get pauseMoment => '暂停句子';
	@override String get play => '播放发音';
	@override String get pause => '暂停播放';
	@override String get speed => '播放速度';
	@override String get audioUnavailable => '音频暂时不可用。';
	@override String get commandHint => '试试说“复习单词”或“开始一个挑战”。';
	@override String get composerHintStartChallenge => '试试“开始一个挑战”';
	@override String get composerHintViewChallenges => '试试“看看我的挑战”';
	@override String get composerHintWords => '试试“我的单词”';
	@override String get progressTitle => '足迹';
	@override String get progressWords => '单词';
	@override String get progressConversations => '对话';
	@override String get progressReads => '阅读';
}

// Path: words
class _Translations$words$zh implements Translations$words$en {
	_Translations$words$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '词语';
	@override String get notebookEyebrow => '词汇本';
	@override String get attempted => '试过了';
	@override String get yourWords => '你的词汇';
	@override String totalWords({required Object count}) => '${count} 个词';
	@override String newThisWeek({required Object count}) => '本周 +${count}';
	@override String usedInTalkThisWeek({required Object count}) => '在 Talk 用过 ${count} 个';
	@override String get needsReview => '需要回看';
	@override String get known => '已经会了';
	@override String get showKnown => '展开会的词';
	@override String get hideKnown => '收起会的词';
	@override String get knowThis => '这个我会';
	@override String get stillLearning => '还要再学';
	@override String seenTimes({required Object count}) => '出现 ${count} 次';
	@override String get loadFailed => '词汇加载失败。';
	@override String get empty => '命名过的词会出现在这里。';
}

// Path: history
class _Translations$history$zh implements Translations$history$en {
	_Translations$history$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '回忆';
	@override String get empty => '还没有可回看的经历。';
	@override String get emptyHint => '一段有意义的对话会在 Milo 整理后出现在这里。';
	@override String get loadFailed => '暂时无法加载回忆。';
	@override String get detailFailed => '暂时无法加载这段经历。';
	@override String get life => '生活经历';
	@override String get learning => '学习经历';
	@override String get fromConversation => '来自对话';
	@override String get openConversation => '打开对话';
	@override String get evidence => '来源';
	@override String get expressions => '表达';
	@override String get detailTitle => '经历';
	@override String get openFocus => '打开来源';
}

// Path: challenge
class _Translations$challenge$zh implements Translations$challenge$en {
	_Translations$challenge$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '挑战';
	@override String get eyebrow => '你的节奏';
	@override String get active => '进行中';
	@override String get ended => '过去的探索';
	@override String get empty => '还没有挑战。';
	@override String get start => '开始一轮挑战';
	@override String get startShort => '开始挑战';
	@override String get kContinue => '继续探索';
	@override String get end => '结束这一轮';
	@override String get endConfirm => '结束这一轮？Word、场景和对话都会继续保留。';
	@override String get name => '名称';
	@override String get nameHint => '例如：身边的小小发现';
	@override String get theme => '意图（可选）';
	@override String get themeHint => '例如：把这些词用在工作中';
	@override String get duration => '计划';
	@override String get twoDays => '2 天';
	@override String get oneWeek => '一周';
	@override String get custom => '自定义';
	@override String get days => '天';
	@override String get chooseContent => '选择你的发现';
	@override String get selectedCount => '已选 {count} 项';
	@override String get searchHint => '搜索你的发现';
	@override String get filterAll => '全部';
	@override String get filterWords => '词语';
	@override String get filterMoments => '场景';
	@override String get chooseHint => '建议 3–7 个';
	@override String get noMatches => '没有匹配的内容。';
	@override String get planPreview => '{count} 个内容 · {days} 天';
	@override String get planPreviewHint => '你的计划';
	@override String get noContent => '先去发现一个词语或场景。';
	@override String get addManual => '手动添加';
	@override String get addManualHint => '输入一个词或一句短句';
	@override String get addManualAction => '添加';
	@override String get addFailed => '添加失败，请重试。';
	@override String get create => '开始这轮挑战';
	@override String get createFailed => '暂时无法开始挑战。';
	@override String get activeExists => '请先结束当前挑战。';
	@override String get progress => '已练过';
	@override String get visitedOf => '已练过 {visited} / {total}';
	@override String get markPracticed => '标记练过';
	@override String get due => '计划时间到了，可以继续，也可以随时结束。';
	@override String get daysLeft => '还剩 {count} 天';
	@override String get dayLeft => '还剩 {count} 天';
	@override String get dueToday => '今天到期';
	@override String get practiceStart => '开始练习';
	@override String get practiceToday => '开始今天的练习';
	@override String get journey => '第 {day} 天 · 共 {total} 天';
	@override String get toPractice => '今天还有 {count} 个';
	@override String get todayDone => '今天练完了';
	@override String get allPracticed => '全部练过了';
	@override String get today => '今天';
	@override String get otherPlans => '其他计划';
	@override String get finishRound => '结束这一轮';
	@override String get roundRecap => '这一轮你练了 {visited} / {total}。';
	@override String get seeAll => '查看全部';
	@override String get plansCount => '{count} 个计划';
	@override String get details => '详情';
	@override String get practiceTitle => '练习';
	@override String get practiceListenSay => '听并说一遍';
	@override String get practiceSayOk => '听起来对';
	@override String get practiceSayRetry => '再说一遍试试';
	@override String get practiceListen => '听';
	@override String get practiceSpeak => '说';
	@override String get practiceExercise => '练习';
	@override String get practiceNext => '下一步';
	@override String get practiceRecord => '录音';
	@override String get practiceStop => '停止';
	@override String get practicePlayback => '回放';
	@override String get practiceSkip => '跳过';
	@override String get practiceCheck => '检查';
	@override String get practiceCorrect => '对了';
	@override String get practiceIncorrect => '再想想';
	@override String get practiceAnswer => '答案：{answer}';
	@override String get practiceRecap => '今天练了 {count} 个';
	@override String get practiceDone => '完成';
	@override String get practicePlaceholder => '输入你的答案';
	@override String get practiceListenHint => '先听，再说一遍。';
	@override String get practiceSpeakHint => '大声说一遍，再回放听听。';
	@override String get practiceExerciseHint => '完成这题才算练过。';
	@override String get practiceMicDenied => '麦克风不可用，可跳过。';
	@override String get practiceSentenceHint => '听整句，再说一遍。';
	@override String get practiceDictation => '听句子，再打出来。';
	@override String get practiceCloze => '填空';
	@override String get practiceTranslate => '译成英文';
	@override String get practiceFreePrompt => '用「{word}」自己写一句话。';
	@override String get practiceModel => '参考：{answer}';
	@override String get content => '本轮发现';
	@override String get open => '打开';
	@override String get word => '词语';
	@override String get moment => '场景';
	@override String get loadFailed => '暂时无法加载挑战。';
	@override String get detailFailed => '暂时无法加载这轮挑战。';
	@override String get complete => '完成';
	@override String get challengeStart => '开始一轮挑战';
	@override String get challengeContinue => '继续你的挑战';
}

// Path: daily
class _Translations$daily$zh implements Translations$daily$en {
	_Translations$daily$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '每日听读';
	@override String get body => '用你的词语生成的短篇阅读。';
	@override String get today => '今日阅读';
	@override String get listen => '听读';
	@override String get pause => '暂停';
	@override String get audioUnavailable => '音频暂不可用';
	@override String get question => '想一想';
	@override String get targetWords => '这篇阅读里的词';
	@override String get back10 => '后退 10 秒';
	@override String get forward10 => '前进 10 秒';
	@override String get translate => '显示翻译';
	@override String get hideTranslation => '隐藏翻译';
	@override String get translationUnavailable => '翻译暂不可用';
	@override String get taskToday => '今日阅读';
	@override String get taskPast => '每日阅读';
	@override String get taskUnread => '2–3 分钟 · 用你的词写成';
	@override String get taskDone => '今日已读 · 连续 {streak} 天';
	@override String get read => '阅读';
	@override String get readAgain => '再读一次';
	@override String get finish => '我读完了';
	@override String get completeTitle => '今日阅读完成';
	@override String get completeStats => '{minutes} 分钟 · {words} 个词 · {targets} 个目标词';
	@override String get streakDays => '连续 {count} 天';
	@override String get newStoryTomorrow => '明天有新的故事。';
	@override String get madeWith => '用你保存的词写成';
	@override String get madeWithBody => '用你最近保存的词写成的短篇。';
	@override String get completeUnavailable => '暂时无法记录阅读完成。';
	@override String get completeTitlePast => '阅读完成';
	@override String get reminderTitle => '今天的阅读准备好了';
	@override String get reminderBody => '用你的词写成的一篇短读，2–3 分钟。';
	@override String get darkReading => '深色阅读';
	@override String get lightReading => '浅色阅读';
	@override String get completeSummary => '{minutes} 分钟 · {words} 个词';
	@override String get speed => '播放速度';
	@override String get preparing => '正在准备今天的阅读…';
	@override String get preparingBody => '正在写作并生成语音。';
	@override String get usefulEnglish => '实用英语';
	@override String get glossaryHint => '点按单词查看释义。';
}

// Path: ask
class _Translations$ask$zh implements Translations$ask$en {
	_Translations$ask$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '提问';
	@override String get entryTooltip => '问一个问题';
	@override String get placeholder => '想问什么？';
	@override String get emptyTitle => '你对什么感到好奇？';
	@override String get emptyBody => '可以问一个词、一句话，或任何你想弄明白的事。';
	@override String get thinking => '正在想…';
	@override String get error => '暂时无法回答，再试一次。';
	@override String get loadFailed => '暂时无法加载这个问题。';
	@override String get retry => '重试';
	@override String get named => 'Named';
	@override String get native => '中文解释';
	@override String get send => '发送问题';
	@override String get recent => '最近提问';
	@override String get thread => '问答';
	@override String get context => '来自这里';
	@override String get followUpHint => '继续追问…';
	@override String get followUp => '继续问';
	@override String get delete => '删除问答';
	@override String get deleteConfirm => '删除这个问答？';
	@override String get cancel => '取消';
	@override String get deleteAction => '删除';
	@override String get suggestions => '可以试试';
	@override String get suggestion1 => '这里是什么意思？';
	@override String get suggestion2 => '这里为什么用这个语法？';
	@override String get suggestion3 => '这句话怎么说更自然？';
	@override String get emptyHistory => '你的提问会出现在这里。';
	@override String get confidenceHigh => '确定';
	@override String get confidenceMedium => '比较确定';
	@override String get confidenceLow => '不太确定';
	@override String get helpful => '有帮助';
	@override String get notHelpful => '没帮助';
	@override String get feedbackError => '暂时无法保存反馈。';
	@override String get agentGreeting => '关于英语的任何问题都可以问我：一个词、一句话，或者某个表达为什么这样说。';
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
			'settings.theme' => '主题',
			'settings.themeTitle' => '主题',
			'settings.themeCobalt' => '墨蓝',
			'settings.themeCobaltDescription' => '干净、现代',
			'settings.themeParchment' => '墨色纸张',
			'settings.themeParchmentDescription' => '温暖、编辑感',
			'settings.themePlum' => '梅子与沙',
			'settings.themePlumDescription' => '有个性、温暖',
			'settings.themeSky' => '墨与亚麻',
			'settings.themeSkyDescription' => '素净、明亮',
			'settings.defaultLabel' => '默认',
			'settings.signOut' => '退出登录',
			'settings.languageTitle' => '语言',
			'settings.english' => 'English',
			'settings.chinese' => '中文',
			'settings.reminder' => '每日提醒',
			'settings.reminderHint' => '故事准备好时，轻轻提醒你。',
			'settings.reminderTime' => '提醒时间',
			'settings.notificationsDenied' => '通知权限未开启，请在系统设置中允许通知。',
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
			'auth.codeSentTo' => '验证码已发送至 {email}',
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
			'soul.headline' => '你的世界正在生长。',
			'soul.subtitle' => '关于你注意到、说出口的事，慢慢留在这里。',
			'soul.profileTitle' => '资料',
			'soul.notes' => 'Soul 笔记',
			'soul.add' => '添加',
			'soul.nativeLanguageShort' => '母语',
			'soul.nativeLanguage' => '母语',
			'soul.age' => '年龄',
			'soul.gender' => '性别',
			'soul.years' => '岁',
			'soul.notSet' => '未填写',
			'soul.noItems' => '还没有笔记。',
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
			'soul.rhythmBody' => '挑战会出现在这里。',
			'soul.library' => '你的收藏',
			'soul.wordsBody' => '从经历里留下的词语。',
			'soul.historyBody' => '值得回看的经历。',
			'soul.addItem' => '添加一条',
			'soul.itemText' => '想让我记住什么？',
			'soul.itemRequired' => '请先填写内容。',
			'soul.editItemTitle' => '编辑这一条',
			'soul.deleteItem' => '删除',
			'soul.deleteConfirmTitle' => '删除这一条？',
			'soul.deleteConfirmBody' => '它不再影响之后的交流。',
			'soul.deleted' => '已删除。',
			'soul.sourceOnboarding' => '初始引导',
			'soul.sourceUser' => '你填写的',
			'soul.sourceAi' => 'AI 提炼',
			'soul.memoryLabel' => '使用我的 Soul',
			'soul.memoryHint' => '关闭后，这次对话不使用已保存的背景。',
			'navigation.explore' => '探索',
			'navigation.words' => '词语',
			'navigation.history' => '回忆',
			'navigation.me' => '我',
			'navigation.challenge' => '挑战',
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
			'understand.related' => '相关',
			'understand.talk' => '聊聊它',
			'understand.talkScene' => '聊聊这个场景',
			'understand.talkFailed' => '无法开始对话，请重试。',
			'understand.sceneTitle' => '一个小场景',
			'talk.title' => '聊聊',
			'talk.emptyScene' => '围绕这个场景说一句吧。',
			'talk.empty' => '从这个词说一句话开始。',
			'talk.inputHint' => '说点什么...',
			'talk.send' => '发送',
			'talk.failed' => '发送失败，请重试。',
			'talk.playReply' => '听语音',
			'talk.pauseReply' => '暂停',
			'talk.helpMeSayIt' => '帮我表达',
			'talk.helpTitle' => '帮我表达',
			'talk.helpSubtitle' => '用中文或还不完整的英文说出来，我帮你整理成自然的英文。',
			'talk.helpInputLabel' => '你想说什么？',
			'talk.helpInputHint' => '例如：我想说这棵树很漂亮',
			'talk.helpAsk' => '帮我找词',
			'talk.helpThinking' => '正在组织表达...',
			'talk.helpResultTitle' => '可以这样说',
			'talk.helpUseThis' => '用这句',
			'talk.helpAnotherWay' => '换一种说法',
			'talk.helpFailed' => '暂时没能帮你组织这句话，请重试。',
			'talk.helpEmptyInput' => '先写一句想说的话。',
			'talk.audioUnavailable' => '音频暂时不可用。',
			'talk.titleFallback' => '对话',
			'talk.miloName' => 'Milo',
			'talk.miloAvatar' => 'Milo',
			'talk.youAvatar' => '你',
			'talk.typing' => 'Milo 正在输入...',
			'talk.wordSheetTitle' => '词义',
			'talk.expressionSheetTitle' => '表达',
			'talk.grammarSheetTitle' => '语法提示',
			'talk.partOfSpeech' => '词性',
			'talk.pronunciation' => '发音',
			'talk.ipa' => '音标',
			'talk.syllables' => '音节',
			'talk.vowels' => '元音',
			'talk.consonants' => '辅音',
			'talk.phonics' => '自然拼读',
			'talk.playPronunciation' => '听发音',
			'talk.pausePronunciation' => '暂停',
			'talk.speak' => '说话',
			'talk.listening' => '正在听你说...',
			'talk.transcribing' => '正在转写...',
			'talk.stopRecording' => '停止录音',
			'talk.microphoneDenied' => '需要麦克风权限。',
			'talk.grammarPattern' => '结构',
			'talk.addToWords' => '加入词语',
			'talk.addedToWords' => '已加入词语',
			'talk.addFailed' => '加入失败，请重试。',
			'talk.nativeShort' => '中',
			'talk.showNative' => '显示中文',
			'talk.hideNative' => '隐藏中文',
			'talk.englishHint' => '更准确的英文',
			'talk.speed' => '播放速度',
			'talk.naturalWay' => '更自然的说法',
			'talk.youWrote' => '你写的是',
			'talk.useThis' => '用这句',
			'talk.copy' => '复制',
			'talk.copied' => '已复制',
			'talk.sentenceDetails' => '句子详情',
			'talk.sentenceLoadFailed' => '暂时无法加载这句话。',
			'talk.explanation' => '说明',
			'talk.grammarNotes' => '结构',
			'talk.chunks' => '表达片段',
			'talk.keyWords' => '关键词',
			'talk.copyEnglish' => '复制英文',
			'talk.memoryLabel' => '使用我的记忆',
			'talk.memoryHint' => '关闭后，这次对话不使用已保存的背景。',
			'timeline.today' => '今天',
			'timeline.yesterday' => '昨天',
			'timeline.emptyTitle' => '今天看到了什么？',
			'timeline.emptyCopy' => '在下面命名一个东西，它会成为你时间线里的第一张卡片。',
			'timeline.emptyHint' => '一个词或一句话就够了。',
			'timeline.composerHint' => '你看到了什么？',
			'timeline.send' => '发送',
			'timeline.nameFailed' => '命名失败，请重试。',
			'timeline.commonUsage' => '常用用法',
			'timeline.example' => '例句',
			'timeline.loadFailed' => '时间线加载失败。',
			'timeline.talkFailed' => '无法开始对话，请重试。',
			'timeline.chunks' => '自然搭配',
			'timeline.talkAboutIt' => '聊聊它',
			'timeline.sceneExtensions' => '同一场景',
			'timeline.usUk' => '美式 / 英式',
			'timeline.grammar' => '语法',
			'timeline.moreDetails' => '更多内容',
			'timeline.wordDetails' => '词语详情',
			'timeline.playMoment' => '播放句子',
			'timeline.pauseMoment' => '暂停句子',
			'timeline.play' => '播放发音',
			'timeline.pause' => '暂停播放',
			'timeline.speed' => '播放速度',
			'timeline.audioUnavailable' => '音频暂时不可用。',
			'timeline.commandHint' => '试试说“复习单词”或“开始一个挑战”。',
			'timeline.composerHintStartChallenge' => '试试“开始一个挑战”',
			'timeline.composerHintViewChallenges' => '试试“看看我的挑战”',
			'timeline.composerHintWords' => '试试“我的单词”',
			'timeline.progressTitle' => '足迹',
			'timeline.progressWords' => '单词',
			'timeline.progressConversations' => '对话',
			'timeline.progressReads' => '阅读',
			'words.title' => '词语',
			'words.notebookEyebrow' => '词汇本',
			'words.attempted' => '试过了',
			'words.yourWords' => '你的词汇',
			'words.totalWords' => ({required Object count}) => '${count} 个词',
			'words.newThisWeek' => ({required Object count}) => '本周 +${count}',
			'words.usedInTalkThisWeek' => ({required Object count}) => '在 Talk 用过 ${count} 个',
			'words.needsReview' => '需要回看',
			'words.known' => '已经会了',
			'words.showKnown' => '展开会的词',
			'words.hideKnown' => '收起会的词',
			'words.knowThis' => '这个我会',
			'words.stillLearning' => '还要再学',
			'words.seenTimes' => ({required Object count}) => '出现 ${count} 次',
			'words.loadFailed' => '词汇加载失败。',
			'words.empty' => '命名过的词会出现在这里。',
			'history.title' => '回忆',
			'history.empty' => '还没有可回看的经历。',
			'history.emptyHint' => '一段有意义的对话会在 Milo 整理后出现在这里。',
			'history.loadFailed' => '暂时无法加载回忆。',
			'history.detailFailed' => '暂时无法加载这段经历。',
			'history.life' => '生活经历',
			'history.learning' => '学习经历',
			'history.fromConversation' => '来自对话',
			'history.openConversation' => '打开对话',
			'history.evidence' => '来源',
			'history.expressions' => '表达',
			'history.detailTitle' => '经历',
			'history.openFocus' => '打开来源',
			'challenge.title' => '挑战',
			'challenge.eyebrow' => '你的节奏',
			'challenge.active' => '进行中',
			'challenge.ended' => '过去的探索',
			'challenge.empty' => '还没有挑战。',
			'challenge.start' => '开始一轮挑战',
			'challenge.startShort' => '开始挑战',
			'challenge.kContinue' => '继续探索',
			'challenge.end' => '结束这一轮',
			'challenge.endConfirm' => '结束这一轮？Word、场景和对话都会继续保留。',
			'challenge.name' => '名称',
			'challenge.nameHint' => '例如：身边的小小发现',
			'challenge.theme' => '意图（可选）',
			'challenge.themeHint' => '例如：把这些词用在工作中',
			'challenge.duration' => '计划',
			'challenge.twoDays' => '2 天',
			'challenge.oneWeek' => '一周',
			'challenge.custom' => '自定义',
			'challenge.days' => '天',
			'challenge.chooseContent' => '选择你的发现',
			'challenge.selectedCount' => '已选 {count} 项',
			'challenge.searchHint' => '搜索你的发现',
			'challenge.filterAll' => '全部',
			'challenge.filterWords' => '词语',
			'challenge.filterMoments' => '场景',
			'challenge.chooseHint' => '建议 3–7 个',
			'challenge.noMatches' => '没有匹配的内容。',
			'challenge.planPreview' => '{count} 个内容 · {days} 天',
			'challenge.planPreviewHint' => '你的计划',
			'challenge.noContent' => '先去发现一个词语或场景。',
			'challenge.addManual' => '手动添加',
			'challenge.addManualHint' => '输入一个词或一句短句',
			'challenge.addManualAction' => '添加',
			'challenge.addFailed' => '添加失败，请重试。',
			'challenge.create' => '开始这轮挑战',
			'challenge.createFailed' => '暂时无法开始挑战。',
			'challenge.activeExists' => '请先结束当前挑战。',
			'challenge.progress' => '已练过',
			'challenge.visitedOf' => '已练过 {visited} / {total}',
			'challenge.markPracticed' => '标记练过',
			'challenge.due' => '计划时间到了，可以继续，也可以随时结束。',
			'challenge.daysLeft' => '还剩 {count} 天',
			'challenge.dayLeft' => '还剩 {count} 天',
			'challenge.dueToday' => '今天到期',
			'challenge.practiceStart' => '开始练习',
			'challenge.practiceToday' => '开始今天的练习',
			'challenge.journey' => '第 {day} 天 · 共 {total} 天',
			'challenge.toPractice' => '今天还有 {count} 个',
			'challenge.todayDone' => '今天练完了',
			'challenge.allPracticed' => '全部练过了',
			'challenge.today' => '今天',
			'challenge.otherPlans' => '其他计划',
			'challenge.finishRound' => '结束这一轮',
			'challenge.roundRecap' => '这一轮你练了 {visited} / {total}。',
			'challenge.seeAll' => '查看全部',
			'challenge.plansCount' => '{count} 个计划',
			'challenge.details' => '详情',
			'challenge.practiceTitle' => '练习',
			'challenge.practiceListenSay' => '听并说一遍',
			'challenge.practiceSayOk' => '听起来对',
			'challenge.practiceSayRetry' => '再说一遍试试',
			'challenge.practiceListen' => '听',
			'challenge.practiceSpeak' => '说',
			'challenge.practiceExercise' => '练习',
			'challenge.practiceNext' => '下一步',
			'challenge.practiceRecord' => '录音',
			'challenge.practiceStop' => '停止',
			'challenge.practicePlayback' => '回放',
			'challenge.practiceSkip' => '跳过',
			'challenge.practiceCheck' => '检查',
			'challenge.practiceCorrect' => '对了',
			'challenge.practiceIncorrect' => '再想想',
			'challenge.practiceAnswer' => '答案：{answer}',
			'challenge.practiceRecap' => '今天练了 {count} 个',
			'challenge.practiceDone' => '完成',
			'challenge.practicePlaceholder' => '输入你的答案',
			'challenge.practiceListenHint' => '先听，再说一遍。',
			'challenge.practiceSpeakHint' => '大声说一遍，再回放听听。',
			'challenge.practiceExerciseHint' => '完成这题才算练过。',
			'challenge.practiceMicDenied' => '麦克风不可用，可跳过。',
			'challenge.practiceSentenceHint' => '听整句，再说一遍。',
			'challenge.practiceDictation' => '听句子，再打出来。',
			'challenge.practiceCloze' => '填空',
			'challenge.practiceTranslate' => '译成英文',
			'challenge.practiceFreePrompt' => '用「{word}」自己写一句话。',
			'challenge.practiceModel' => '参考：{answer}',
			'challenge.content' => '本轮发现',
			'challenge.open' => '打开',
			'challenge.word' => '词语',
			'challenge.moment' => '场景',
			'challenge.loadFailed' => '暂时无法加载挑战。',
			'challenge.detailFailed' => '暂时无法加载这轮挑战。',
			'challenge.complete' => '完成',
			'challenge.challengeStart' => '开始一轮挑战',
			'challenge.challengeContinue' => '继续你的挑战',
			'daily.title' => '每日听读',
			'daily.body' => '用你的词语生成的短篇阅读。',
			'daily.today' => '今日阅读',
			'daily.listen' => '听读',
			'daily.pause' => '暂停',
			'daily.audioUnavailable' => '音频暂不可用',
			'daily.question' => '想一想',
			'daily.targetWords' => '这篇阅读里的词',
			'daily.back10' => '后退 10 秒',
			'daily.forward10' => '前进 10 秒',
			'daily.translate' => '显示翻译',
			'daily.hideTranslation' => '隐藏翻译',
			'daily.translationUnavailable' => '翻译暂不可用',
			'daily.taskToday' => '今日阅读',
			'daily.taskPast' => '每日阅读',
			'daily.taskUnread' => '2–3 分钟 · 用你的词写成',
			'daily.taskDone' => '今日已读 · 连续 {streak} 天',
			'daily.read' => '阅读',
			'daily.readAgain' => '再读一次',
			'daily.finish' => '我读完了',
			'daily.completeTitle' => '今日阅读完成',
			'daily.completeStats' => '{minutes} 分钟 · {words} 个词 · {targets} 个目标词',
			'daily.streakDays' => '连续 {count} 天',
			'daily.newStoryTomorrow' => '明天有新的故事。',
			'daily.madeWith' => '用你保存的词写成',
			'daily.madeWithBody' => '用你最近保存的词写成的短篇。',
			'daily.completeUnavailable' => '暂时无法记录阅读完成。',
			'daily.completeTitlePast' => '阅读完成',
			'daily.reminderTitle' => '今天的阅读准备好了',
			'daily.reminderBody' => '用你的词写成的一篇短读，2–3 分钟。',
			'daily.darkReading' => '深色阅读',
			'daily.lightReading' => '浅色阅读',
			'daily.completeSummary' => '{minutes} 分钟 · {words} 个词',
			'daily.speed' => '播放速度',
			'daily.preparing' => '正在准备今天的阅读…',
			'daily.preparingBody' => '正在写作并生成语音。',
			'daily.usefulEnglish' => '实用英语',
			'daily.glossaryHint' => '点按单词查看释义。',
			'ask.title' => '提问',
			'ask.entryTooltip' => '问一个问题',
			'ask.placeholder' => '想问什么？',
			'ask.emptyTitle' => '你对什么感到好奇？',
			'ask.emptyBody' => '可以问一个词、一句话，或任何你想弄明白的事。',
			'ask.thinking' => '正在想…',
			'ask.error' => '暂时无法回答，再试一次。',
			'ask.loadFailed' => '暂时无法加载这个问题。',
			'ask.retry' => '重试',
			'ask.named' => 'Named',
			'ask.native' => '中文解释',
			'ask.send' => '发送问题',
			'ask.recent' => '最近提问',
			'ask.thread' => '问答',
			'ask.context' => '来自这里',
			'ask.followUpHint' => '继续追问…',
			'ask.followUp' => '继续问',
			'ask.delete' => '删除问答',
			'ask.deleteConfirm' => '删除这个问答？',
			'ask.cancel' => '取消',
			'ask.deleteAction' => '删除',
			'ask.suggestions' => '可以试试',
			'ask.suggestion1' => '这里是什么意思？',
			'ask.suggestion2' => '这里为什么用这个语法？',
			'ask.suggestion3' => '这句话怎么说更自然？',
			'ask.emptyHistory' => '你的提问会出现在这里。',
			'ask.confidenceHigh' => '确定',
			'ask.confidenceMedium' => '比较确定',
			'ask.confidenceLow' => '不太确定',
			'ask.helpful' => '有帮助',
			'ask.notHelpful' => '没帮助',
			'ask.feedbackError' => '暂时无法保存反馈。',
			'ask.agentGreeting' => '关于英语的任何问题都可以问我：一个词、一句话，或者某个表达为什么这样说。',
			_ => null,
		};
	}
}
