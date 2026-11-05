import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../i18n/strings.g.dart';
import '../domain/talk.dart';
import '../providers/talk_providers.dart';

class TalkPage extends ConsumerStatefulWidget {
  const TalkPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<TalkPage> createState() => _TalkPageState();
}

class _TalkPageState extends ConsumerState<TalkPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<TalkMessage> _messages = const [];
  String? _error;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
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
    setState(() {
      _error = null;
      _isSending = true;
    });
    try {
      final turn = await ref
          .read(talkRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            text: text,
            clientMessageId: DateTime.now().microsecondsSinceEpoch.toString(),
          );
      if (mounted) {
        setState(() {
          _messages = [..._messages, turn.userMessage, turn.assistantMessage];
          _controller.clear();
        });
        _scrollToBottom();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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

    return AppScaffold(
      title: t.title,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _messages.isEmpty
                ? Center(
                    child: AppErrorView(
                      title: t.title,
                      message: _error!,
                      onRetry: _load,
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      t.empty,
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
                    itemCount: _messages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.s12),
                    itemBuilder: (context, index) =>
                        _MessageBubble(message: _messages[index]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontalPadding,
                AppSpacing.s8,
                AppSpacing.pageHorizontalPadding,
                AppSpacing.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null && _messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.error,
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          key: const Key('talk.input'),
                          controller: _controller,
                          hintText: t.inputHint,
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() => _error = null),
                          onSubmitted: (_) async => _send(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      IconButton.filled(
                        key: const Key('talk.send'),
                        onPressed: _isSending ? null : _send,
                        tooltip: t.send,
                        icon: _isSending
                            ? SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.onPrimary,
                                ),
                              )
                            : const Icon(Icons.arrow_upward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TalkMessage message;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(AppSpacing.s14),
        decoration: BoxDecoration(
          color: isUser ? palette.warm : palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: isUser ? null : Border.all(color: palette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: textTheme.bodyLarge),
            for (final annotation in message.annotations) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                '${annotation.text} · ${annotation.meaningZh}',
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
            for (final correction in message.corrections) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                '${correction.original} → ${correction.suggestion}',
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 2),
              Text(
                correction.note,
                style: AppTextStyles.caption.copyWith(color: palette.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
