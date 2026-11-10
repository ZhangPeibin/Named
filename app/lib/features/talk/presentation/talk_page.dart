import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/audio/audio_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../words/providers/words_providers.dart';
import '../domain/talk.dart';
import '../providers/talk_providers.dart';
import 'widgets/help_sheet.dart';
import 'widgets/talk_avatar.dart';

class TalkPage extends ConsumerStatefulWidget {
  const TalkPage({super.key, required this.conversationId, this.title});

  final String conversationId;
  final String? title;

  @override
  ConsumerState<TalkPage> createState() => _TalkPageState();
}

class _TalkPageState extends ConsumerState<TalkPage> {
  final _controller = TextEditingController();
  final _composerFocusNode = FocusNode();
  final _scrollController = ScrollController();
  List<TalkMessage> _messages = const [];
  String? _title;
  String? _focusType;
  String? _error;
  bool _isLoading = true;
  bool _isSending = false;
  TalkMessage? _pendingMessage;
  final _hiddenNativeMessageIds = <String>{};
  double _playbackRate = 1.0;
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<void> _playerCompleteSub;
  final _audioCache = <String, Uint8List>{};
  String? _playingMessageId;
  String? _loadingMessageId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playingMessageId = null;
        });
      }
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_playerStateSub.cancel());
    unawaited(_playerCompleteSub.cancel());
    unawaited(_player.stop());
    unawaited(_player.dispose());
    _controller.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final conversation = await ref
          .read(talkRepositoryProvider)
          .fetch(widget.conversationId);
      if (mounted) {
        setState(() {
          _title = conversation.title;
          _focusType = conversation.focusType;
          _messages = conversation.messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    final clientMessageId = DateTime.now().microsecondsSinceEpoch.toString();
    final pending = TalkMessage(
      id: 'pending-$clientMessageId',
      role: 'user',
      text: text,
      corrections: const [],
      annotations: const [],
    );
    setState(() {
      _error = null;
      _isSending = true;
      _pendingMessage = pending;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final turn = await ref
          .read(talkRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            text: text,
            clientMessageId: clientMessageId,
          );
      if (mounted) {
        final assistant = turn.assistantMessage;
        setState(() {
          _messages = [..._messages, turn.userMessage, assistant];
          _pendingMessage = null;
        });
        _scrollToBottom();
        if (assistant.audio?.isReady == true) {
          unawaited(_playAudio(assistant));
        }
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _pendingMessage = null;
          _controller.text = text;
          _controller.selection = TextSelection.collapsed(offset: text.length);
          _error = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _playAudio(TalkMessage message) async {
    final audio = message.audio;
    final url = audio?.url;
    if (audio?.isReady != true || url == null) {
      return;
    }

    if (_playingMessageId == message.id && _isPlaying) {
      await _player.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playingMessageId = null;
        });
      }
      return;
    }

    final requestId = message.id;
    setState(() {
      _loadingMessageId = requestId;
      _playingMessageId = null;
      _isPlaying = false;
    });
    try {
      final bytes = await _loadAudio(url);
      if (!mounted || _loadingMessageId != requestId) {
        return;
      }
      await _player.stop();
      await _player.setPlaybackRate(_playbackRate);
      await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
      if (mounted && _loadingMessageId == requestId) {
        setState(() {
          _loadingMessageId = null;
          _playingMessageId = requestId;
        });
      }
    } catch (_) {
      if (mounted && _loadingMessageId == requestId) {
        setState(() => _loadingMessageId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.talk.audioUnavailable)),
        );
      }
    }
  }

  Future<void> _setPlaybackRate(double rate) async {
    setState(() => _playbackRate = rate);
    if (_isPlaying) {
      await _player.setPlaybackRate(rate);
    }
  }

  void _useSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    _composerFocusNode.requestFocus();
    setState(() => _error = null);
  }

  Future<void> _openHelp() async {
    final suggestion = await showAppBottomSheet<HelpSuggestion>(
      context: context,
      builder: (context) => HelpSheet(
        conversationId: widget.conversationId,
        initialText: _controller.text.trim(),
      ),
    );
    if (!mounted || suggestion == null) {
      return;
    }
    _useSuggestion(suggestion.naturalEnglish);
  }

  Future<void> _showAnnotation(
    MessageAnnotation annotation,
    String sentence,
  ) async {
    await showAppBottomSheet<void>(
      context: context,
      builder: (context) => _AnnotationSheet(
        annotation: annotation,
        onAddToWords: annotation.isWord || annotation.isGrammar
            ? () => _addToWords(annotation, sentence)
            : null,
      ),
    );
  }

  Future<void> _addToWords(
    MessageAnnotation annotation,
    String sentence,
  ) async {
    await ref
        .read(wordsRepositoryProvider)
        .saveFromTalk(
          label: annotation.text,
          meaningZh: annotation.meaningZh,
          partOfSpeech: annotation.partOfSpeech,
          grammar: annotation.grammar,
          exampleEn: sentence,
          ipa: annotation.ipa,
          syllables: annotation.syllables,
          vowels: annotation.vowels,
          consonants: annotation.consonants,
          phonics: annotation.phonics,
        );
    ref.invalidate(wordShelfProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.talk.addedToWords)));
    }
  }

  Future<Uint8List> _loadAudio(String url) async {
    final cached = _audioCache[url];
    if (cached != null) {
      return cached;
    }
    final data = await ref.read(audioBytesApiProvider).fetch(url);
    final bytes = Uint8List.fromList(data);
    _audioCache[url] = bytes;
    return bytes;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.talk;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final title = _title ?? widget.title ?? t.titleFallback;
    final visibleMessages = <TalkMessage>[..._messages, ?_pendingMessage];
    final showTyping = _isSending && _pendingMessage != null;

    return AppScaffold(
      title: '',
      showAppBar: false,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          _TalkHeader(
            title: title,
            isTyping: showTyping,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _messages.isEmpty
                ? Center(
                    child: AppErrorView(
                      title: title,
                      message: _error!,
                      onRetry: _load,
                    ),
                  )
                : visibleMessages.isEmpty
                ? Center(
                    child: Text(
                      _focusType == 'scene' ? t.emptyScene : t.empty,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  )
                : ListView.separated(
                    key: const Key('talk.list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                    ),
                    itemCount: visibleMessages.length + (showTyping ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.s12),
                    itemBuilder: (context, index) {
                      if (index == visibleMessages.length) {
                        return const _TypingMessage();
                      }
                      final message = visibleMessages[index];
                      return _MessageBubble(
                        message: message,
                        showNative: !_hiddenNativeMessageIds.contains(
                          message.id,
                        ),
                        playbackRate: _playbackRate,
                        isPlaying:
                            _playingMessageId == message.id && _isPlaying,
                        isLoading: _loadingMessageId == message.id,
                        onPlay: message.audio?.isReady == true
                            ? () => _playAudio(message)
                            : null,
                        onPlaybackRateChanged: (rate) {
                          unawaited(_setPlaybackRate(rate));
                        },
                        onToggleNative: () {
                          setState(() {
                            if (!_hiddenNativeMessageIds.add(message.id)) {
                              _hiddenNativeMessageIds.remove(message.id);
                            }
                          });
                        },
                        onUseSuggestion: _useSuggestion,
                        onAnnotationTap: _showAnnotation,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null && _messages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s8,
                      AppSpacing.pageHorizontalPadding,
                      0,
                    ),
                    child: Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.error,
                      ),
                    ),
                  ),
                _TalkComposer(
                  controller: _controller,
                  focusNode: _composerFocusNode,
                  hintText: t.inputHint,
                  sendTooltip: t.send,
                  helpTooltip: t.helpMeSayIt,
                  isSending: _isSending,
                  onSend: _send,
                  onOpenHelp: _openHelp,
                  onChanged: (_) => setState(() => _error = null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessageText extends StatelessWidget {
  const _InlineMessageText({
    required this.message,
    required this.style,
    required this.onAnnotationTap,
  });

  final TalkMessage message;
  final TextStyle? style;
  final void Function(MessageAnnotation, String) onAnnotationTap;

  @override
  Widget build(BuildContext context) {
    final annotations = message.annotations.where(
      (annotation) => annotation.text.trim().isNotEmpty,
    );
    if (annotations.isEmpty) {
      return Text(message.text, style: style);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    var inserted = false;
    for (final annotation in annotations) {
      final index = message.text.indexOf(annotation.text, cursor);
      if (index < 0) {
        continue;
      }
      if (index > cursor) {
        spans.add(TextSpan(text: message.text.substring(cursor, index)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _AnnotationWord(
            annotation: annotation,
            style: style,
            onTap: () => onAnnotationTap(annotation, message.text),
          ),
        ),
      );
      cursor = index + annotation.text.length;
      inserted = true;
    }
    if (!inserted) {
      return Text(message.text, style: style);
    }
    if (cursor < message.text.length) {
      spans.add(TextSpan(text: message.text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _AnnotationWord extends StatelessWidget {
  const _AnnotationWord({
    required this.annotation,
    required this.style,
    required this.onTap,
  });

  final MessageAnnotation annotation;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textStyle = (style ?? Theme.of(context).textTheme.bodyLarge)
        ?.copyWith(color: palette.accent, fontWeight: FontWeight.w600);

    return Semantics(
      button: true,
      label: '${annotation.text}: ${annotation.meaningZh}',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('talk.annotation.${annotation.text}'),
          onTap: onTap,
          child: Text(annotation.text, style: textStyle),
        ),
      ),
    );
  }
}

class _AnnotationSheet extends StatefulWidget {
  const _AnnotationSheet({required this.annotation, this.onAddToWords});

  final MessageAnnotation annotation;
  final Future<void> Function()? onAddToWords;

  @override
  State<_AnnotationSheet> createState() => _AnnotationSheetState();
}

class _AnnotationSheetState extends State<_AnnotationSheet> {
  var _saving = false;
  String? _error;

  String _title(Translations$talk$en t) {
    if (widget.annotation.isGrammar) {
      return t.grammarSheetTitle;
    }
    if (widget.annotation.isWord) {
      return t.wordSheetTitle;
    }
    return t.expressionSheetTitle;
  }

  Future<void> _save() async {
    final onAddToWords = widget.onAddToWords;
    if (onAddToWords == null || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await onAddToWords();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.t.talk.addFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool _hasPronunciation(MessageAnnotation annotation) {
    return annotation.ipa?.trim().isNotEmpty == true ||
        annotation.syllables?.trim().isNotEmpty == true ||
        annotation.vowels.isNotEmpty ||
        annotation.consonants.isNotEmpty ||
        annotation.phonics?.trim().isNotEmpty == true;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appPalette.muted),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  Widget _soundRow(String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.appPalette.muted),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.s4,
              runSpacing: AppSpacing.s4,
              children: [
                for (final value in values)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.appPalette.warm,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.talk;
    final annotation = widget.annotation;
    final partOfSpeech = annotation.partOfSpeech?.trim();
    final grammar = annotation.grammar?.trim();

    return Column(
      key: const Key('talk.annotationSheet'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _title(t).toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(annotation.text, style: textTheme.displayMedium),
        if (_hasPronunciation(annotation)) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            t.pronunciation.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s6),
          if (annotation.ipa?.trim().isNotEmpty == true)
            _detailRow(t.ipa, annotation.ipa!.trim()),
          if (annotation.syllables?.trim().isNotEmpty == true)
            _detailRow(t.syllables, annotation.syllables!.trim()),
          if (annotation.vowels.isNotEmpty)
            _soundRow(t.vowels, annotation.vowels),
          if (annotation.consonants.isNotEmpty)
            _soundRow(t.consonants, annotation.consonants),
          if (annotation.phonics?.trim().isNotEmpty == true)
            _detailRow(t.phonics, annotation.phonics!.trim()),
        ],
        if (partOfSpeech != null && partOfSpeech.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s6),
          Text(
            '${t.partOfSpeech}: $partOfSpeech',
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
        if (grammar != null && grammar.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: palette.warm,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.grammarPattern.toUpperCase(),
                  style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(grammar, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        Text(annotation.meaningZh, style: textTheme.bodyLarge),
        if (widget.onAddToWords != null) ...[
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const Key('talk.annotationAdd'),
              label: t.addToWords,
              icon: const Icon(Icons.add, size: 18),
              isLoading: _saving,
              onPressed: _save,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            _error!,
            style: textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ],
        const SizedBox(height: AppSpacing.s8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('talk.annotationClose'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.gotIt),
          ),
        ),
      ],
    );
  }
}

class _TalkHeader extends StatelessWidget {
  const _TalkHeader({
    required this.title,
    required this.isTyping,
    required this.onBack,
  });

  final String title;
  final bool isTyping;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.talk;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('talk.back'),
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(40),
              maximumSize: const Size.square(40),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          const SizedBox(width: AppSpacing.s4),
          const TalkAvatar(
            key: Key('talk.header.avatar'),
            isUser: false,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.miloName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  isTyping ? t.typing : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TalkComposer extends StatelessWidget {
  const _TalkComposer({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.sendTooltip,
    required this.helpTooltip,
    required this.isSending,
    required this.onSend,
    required this.onOpenHelp,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String sendTooltip;
  final String helpTooltip;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onOpenHelp;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s8,
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.r18),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.s6),
            SizedBox.square(
              dimension: 34,
              child: IconButton.filledTonal(
                key: const Key('talk.help'),
                onPressed: onOpenHelp,
                tooltip: helpTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: palette.surfaceMuted,
                  foregroundColor: palette.primary,
                  minimumSize: const Size.square(34),
                  maximumSize: const Size.square(34),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.translate, size: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: TextField(
                key: const Key('talk.input'),
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                style: textTheme.bodyLarge,
                cursorColor: palette.primary,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final enabled = value.text.trim().isNotEmpty && !isSending;
                return SizedBox.square(
                  dimension: 38,
                  child: IconButton.filled(
                    key: const Key('talk.send'),
                    onPressed: enabled ? onSend : null,
                    tooltip: sendTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      disabledBackgroundColor: palette.surfaceMuted,
                      disabledForegroundColor: palette.muted,
                      minimumSize: const Size.square(38),
                      maximumSize: const Size.square(38),
                      padding: EdgeInsets.zero,
                    ),
                    icon: isSending
                        ? SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.onPrimary,
                            ),
                          )
                        : const Icon(Icons.arrow_upward, size: 18),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showNative,
    required this.playbackRate,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlay,
    required this.onPlaybackRateChanged,
    required this.onToggleNative,
    required this.onUseSuggestion,
    required this.onAnnotationTap,
  });

  final TalkMessage message;
  final bool showNative;
  final double playbackRate;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback? onPlay;
  final ValueChanged<double> onPlaybackRateChanged;
  final VoidCallback onToggleNative;
  final ValueChanged<String> onUseSuggestion;
  final void Function(MessageAnnotation, String) onAnnotationTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final isUser = message.isUser;
    final onPlay = this.onPlay;
    final hasNative =
        message.nativeText != null && message.nativeText!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              TalkAvatar(
                key: Key('talk.avatar.${message.id}'),
                isUser: false,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.s8),
            ],
            Flexible(
              child: Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.all(AppSpacing.s14),
                  decoration: BoxDecoration(
                    color: isUser ? palette.warm : palette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                    border: isUser ? null : Border.all(color: palette.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InlineMessageText(
                        message: message,
                        style: textTheme.bodyLarge,
                        onAnnotationTap: onAnnotationTap,
                      ),
                      if (hasNative)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topLeft,
                          child: showNative
                              ? Padding(
                                  key: Key('talk.native.${message.id}'),
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.s8,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                      left: AppSpacing.s10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: palette.accent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      message.nativeText!,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: palette.muted,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      if (onPlay != null || hasNative) ...[
                        const SizedBox(height: AppSpacing.s8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: AppSpacing.s6,
                            runSpacing: AppSpacing.s6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (hasNative)
                                _NativeToggle(
                                  messageId: message.id,
                                  selected: showNative,
                                  onTap: onToggleNative,
                                ),
                              if (onPlay != null)
                                _MessageAudioButton(
                                  messageId: message.id,
                                  playbackRate: playbackRate,
                                  isPlaying: isPlaying,
                                  isLoading: isLoading,
                                  onTap: onPlay,
                                  onPlaybackRateChanged: onPlaybackRateChanged,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: AppSpacing.s8),
              TalkAvatar(
                key: Key('talk.avatar.${message.id}'),
                isUser: true,
                size: 32,
              ),
            ],
          ],
        ),
        if (message.corrections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          for (var index = 0; index < message.corrections.length; index++)
            Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == message.corrections.length - 1
                        ? 0
                        : AppSpacing.s6,
                  ),
                  child: _CorrectionCard(
                    messageId: message.id,
                    index: index,
                    correction: message.corrections[index],
                    onUse: () =>
                        onUseSuggestion(message.corrections[index].suggestion),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TypingMessage extends StatelessWidget {
  const _TypingMessage();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.talk;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TalkAvatar(
          key: Key('talk.typing.avatar'),
          isUser: false,
          size: 32,
        ),
        const SizedBox(width: AppSpacing.s8),
        Container(
          key: const Key('talk.typing'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: palette.line),
          ),
          child: Semantics(
            liveRegion: true,
            label: t.typing,
            child: const _TypingDots(),
          ),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.s4),
              _dot(palette.primary, reduceMotion ? 0.5 : _phase(index)),
            ],
          ],
        );
      },
    );
  }

  double _phase(int index) {
    final phase = (_controller.value - index * 0.18) % 1.0;
    return 0.25 + 0.75 * (0.5 + 0.5 * math.sin(2 * math.pi * phase));
  }

  Widget _dot(Color color, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({
    required this.messageId,
    required this.index,
    required this.correction,
    required this.onUse,
  });

  final String messageId;
  final int index;
  final MessageCorrection correction;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.talk;

    return Container(
      key: Key('talk.correction.$messageId.$index'),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high_outlined,
                size: 16,
                color: palette.accent,
              ),
              const SizedBox(width: AppSpacing.s6),
              Text(
                t.naturalWay.toUpperCase(),
                style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            correction.suggestion,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          if (correction.note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              correction.note,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t.youWrote}: ${correction.original}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: palette.muted),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              TextButton(
                key: Key('talk.correction.use.$messageId.$index'),
                onPressed: onUse,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s10,
                  ),
                  foregroundColor: palette.primary,
                  textStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(t.useThis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NativeToggle extends StatelessWidget {
  const _NativeToggle({
    required this.messageId,
    required this.selected,
    required this.onTap,
  });

  final String messageId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.talk;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: selected ? t.hideNative : t.showNative,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.primary : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('talk.native.toggle.$messageId'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s10,
              vertical: AppSpacing.s6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate,
                  size: 16,
                  color: selected ? palette.onPrimary : palette.primary,
                ),
                const SizedBox(width: AppSpacing.s6),
                Text(
                  t.nativeShort,
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? palette.onPrimary : palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageAudioButton extends StatelessWidget {
  const _MessageAudioButton({
    required this.messageId,
    required this.playbackRate,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
    required this.onPlaybackRateChanged,
  });

  static const _rates = [0.5, 0.75, 1.0, 1.25, 1.5];

  final String messageId;
  final double playbackRate;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final ValueChanged<double> onPlaybackRateChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.talk;

    return Material(
      color: palette.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            button: true,
            label: isPlaying ? t.pauseReply : t.playReply,
            onTap: isLoading ? null : onTap,
            excludeSemantics: true,
            child: InkWell(
              key: Key('talk.audio.$messageId'),
              onTap: isLoading ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s10,
                  vertical: AppSpacing.s6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.primary,
                        ),
                      )
                    else
                      Icon(
                        isPlaying ? Icons.pause : Icons.volume_up_outlined,
                        size: 16,
                        color: palette.primary,
                      ),
                    const SizedBox(width: AppSpacing.s6),
                    Text(
                      isPlaying ? t.pauseReply : t.playReply,
                      style: AppTextStyles.caption.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 18, color: palette.line),
          PopupMenuButton<double>(
            key: Key('talk.audio.speed.$messageId'),
            tooltip: t.speed,
            initialValue: playbackRate,
            onSelected: onPlaybackRateChanged,
            itemBuilder: (context) => [
              for (final rate in _rates)
                CheckedPopupMenuItem<double>(
                  value: rate,
                  checked: rate == playbackRate,
                  child: Text(_rateLabel(rate)),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _rateLabel(playbackRate),
                    style: AppTextStyles.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 16, color: palette.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _rateLabel(double rate) {
  return rate == rate.roundToDouble()
      ? '${rate.toInt()}×'
      : '${rate.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}×';
}
