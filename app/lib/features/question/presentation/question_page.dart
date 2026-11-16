import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../domain/question.dart';
import '../providers/question_providers.dart';

class QuestionPage extends ConsumerStatefulWidget {
  const QuestionPage({super.key, this.context, this.suggestedQuestion});

  final QuestionContext? context;
  final String? suggestedQuestion;

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<QuestionPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late QuestionContext? _context = widget.context;
  var _threads = <QuestionThreadSummary>[];
  var _loading = true;
  var _asking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedQuestion != null) {
      _controller.text = widget.suggestedQuestion!;
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final threads = await ref.read(questionRepositoryProvider).fetchThreads();
      if (!mounted) {
        return;
      }
      setState(() {
        _threads = threads;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _ask() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _asking) {
      return;
    }
    setState(() {
      _asking = true;
      _error = null;
    });
    try {
      final thread = await ref
          .read(questionRepositoryProvider)
          .ask(text, context: _context);
      if (!mounted) {
        return;
      }
      _controller.clear();
      _context = null;
      await context.pushNamed(
        AppRouteNames.questionThread,
        pathParameters: {'threadId': thread.id},
      );
      if (mounted) {
        await _load();
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.ask.error)));
    } finally {
      if (mounted) {
        setState(() => _asking = false);
      }
    }
  }

  void _useSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.ask;
    final palette = context.appPalette;

    return AppScaffold(
      key: const Key('ask.page'),
      title: t.title,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _threads.isEmpty
                ? AppErrorView(title: t.title, message: _error!, onRetry: _load)
                : _threads.isEmpty && _context == null
                ? _EmptyAsk(t: t, onSelected: _useSuggestion)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                    ),
                    children: [
                      if (_context != null) ...[
                        _ContextCard(
                          context: _context!,
                          onRemove: () => setState(() => _context = null),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                      ],
                      if (_threads.isEmpty) ...[
                        _SuggestionList(t: t, onSelected: _useSuggestion),
                        const SizedBox(height: AppSpacing.s20),
                      ] else ...[
                        Text(
                          t.suggestions.toUpperCase(),
                          style: AppTextStyles.eyebrow.copyWith(
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Wrap(
                          spacing: AppSpacing.s8,
                          runSpacing: AppSpacing.s8,
                          children: [
                            for (final suggestion in [
                              t.suggestion1,
                              t.suggestion2,
                              t.suggestion3,
                            ])
                              ActionChip(
                                label: Text(suggestion),
                                onPressed: () => _useSuggestion(suggestion),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        Text(
                          t.recent.toUpperCase(),
                          style: AppTextStyles.eyebrow.copyWith(
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        for (final thread in _threads) ...[
                          _ThreadRow(
                            thread: thread,
                            onTap: () async {
                              await context.pushNamed(
                                AppRouteNames.questionThread,
                                pathParameters: {'threadId': thread.id},
                              );
                              if (mounted) {
                                await _load();
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.s8),
                        ],
                      ],
                    ],
                  ),
          ),
          _AskComposer(
            controller: _controller,
            focusNode: _focusNode,
            hintText: t.placeholder,
            sendTooltip: t.send,
            enabled: !_asking,
            onSend: _ask,
          ),
        ],
      ),
    );
  }
}

class QuestionThreadPage extends ConsumerStatefulWidget {
  const QuestionThreadPage({super.key, required this.threadId});

  final String threadId;

  @override
  ConsumerState<QuestionThreadPage> createState() => _QuestionThreadPageState();
}

class _QuestionThreadPageState extends ConsumerState<QuestionThreadPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _followUpFocusNode = FocusNode();
  QuestionThread? _thread;
  var _loading = true;
  var _sending = false;
  String? _error;
  String? _pendingFollowUp;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _followUpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final thread = await ref
          .read(questionRepositoryProvider)
          .fetchThread(widget.threadId);
      if (!mounted) {
        return;
      }
      setState(() {
        _thread = thread;
        _loading = false;
      });
      _scrollToBottom(jump: true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _followUp() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() {
      _sending = true;
      _pendingFollowUp = text;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final thread = await ref
          .read(questionRepositoryProvider)
          .followUp(widget.threadId, text);
      if (!mounted) {
        return;
      }
      setState(() {
        _thread = thread;
        _pendingFollowUp = null;
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _pendingFollowUp = null;
          _controller.text = text;
          _controller.selection = TextSelection.collapsed(offset: text.length);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _delete() async {
    final t = context.t.ask;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(questionRepositoryProvider).deleteThread(widget.threadId);
    if (mounted) {
      context.pop();
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        unawaited(
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
  }

  void _useFollowUpSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    _followUpFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.ask;
    final thread = _thread;
    final messages = thread?.messages ?? const <QuestionMessage>[];

    return AppScaffold(
      key: const Key('ask.thread'),
      title: t.thread,
      centerBody: false,
      padding: EdgeInsets.zero,
      actions: [
        if (thread != null)
          IconButton(
            key: const Key('ask.delete'),
            tooltip: t.delete,
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? AppErrorView(
                    title: t.thread,
                    message: _error!,
                    onRetry: _load,
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                    ),
                    children: [
                      if (thread?.contextQuote != null) ...[
                        _ContextCard(
                          context: QuestionContext(
                            type: thread!.contextType ?? 'none',
                            ref: thread.contextRef,
                            quote: thread.contextQuote,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                      ],
                      for (final message in messages) ...[
                        _QuestionMessageView(
                          message: message,
                          onSuggestion: _useFollowUpSuggestion,
                        ),
                        const SizedBox(height: AppSpacing.s16),
                      ],
                      if (_pendingFollowUp != null) ...[
                        _QuestionMessageView(
                          message: QuestionMessage(
                            id: 'pending',
                            role: 'user',
                            text: _pendingFollowUp!,
                            example: null,
                            nativeExplanation: null,
                            confidence: null,
                            followUpSuggestions: const [],
                            createdAt: DateTime.now(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s10),
                        Row(
                          children: [
                            SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.appPalette.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Text(
                              context.t.ask.thinking,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: context.appPalette.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s16),
                      ],
                    ],
                  ),
          ),
          _AskComposer(
            controller: _controller,
            focusNode: _followUpFocusNode,
            hintText: t.followUpHint,
            sendTooltip: t.followUp,
            enabled: !_sending,
            onSend: _followUp,
          ),
        ],
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onTap});

  final QuestionThreadSummary thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s14),
          child: Row(
            children: [
              Icon(
                thread.contextType == null
                    ? Icons.question_answer_outlined
                    : Icons.bookmark_border_rounded,
                color: palette.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge,
                    ),
                    if (thread.lastText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        thread.lastText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Icon(Icons.chevron_right, color: palette.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionMessageView extends StatelessWidget {
  const _QuestionMessageView({required this.message, this.onSuggestion});

  final QuestionMessage message;
  final ValueChanged<String>? onSuggestion;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      final palette = context.appPalette;
      final textTheme = Theme.of(context).textTheme;
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s10,
          ),
          decoration: BoxDecoration(
            color: palette.warm,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Text(message.text, style: textTheme.bodyLarge),
        ),
      );
    }

    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.ask;
    final confidence = switch (message.confidence) {
      'low' => t.confidenceLow,
      'medium' => t.confidenceMedium,
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 14,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                t.named,
                style: textTheme.labelLarge?.copyWith(color: palette.primary),
              ),
              if (confidence != null) ...[
                const SizedBox(width: AppSpacing.s8),
                Text(
                  confidence,
                  style: AppTextStyles.caption.copyWith(color: palette.muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Text(message.text, style: textTheme.bodyLarge),
          if (message.example != null &&
              message.example!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              'EXAMPLE',
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              message.example!,
              style: textTheme.bodyMedium?.copyWith(color: palette.primary),
            ),
          ],
          if (message.nativeExplanation != null &&
              message.nativeExplanation!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Divider(color: palette.line, height: 1),
            const SizedBox(height: AppSpacing.s10),
            Text(
              t.native.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              message.nativeExplanation!,
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
          ],
          if (message.followUpSuggestions.isNotEmpty &&
              onSuggestion != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final suggestion in message.followUpSuggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestion!(suggestion),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.context, this.onRemove});

  final QuestionContext context;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final quote = this.context.quote?.trim();
    if (quote == null || quote.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: palette.warm,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.ask.context.toUpperCase(),
                  style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(quote, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close_rounded, size: 18, color: palette.muted),
            ),
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.t, required this.onSelected});

  final Translations$ask$en t;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.suggestions.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(
            color: context.appPalette.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final suggestion in [
              t.suggestion1,
              t.suggestion2,
              t.suggestion3,
            ])
              ActionChip(
                label: Text(suggestion),
                onPressed: () => onSelected(suggestion),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyAsk extends StatelessWidget {
  const _EmptyAsk({required this.t, required this.onSelected});

  final Translations$ask$en t;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: palette.warm,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.question_mark_rounded,
                color: palette.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              t.emptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              t.emptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s20),
            _SuggestionList(t: t, onSelected: onSelected),
          ],
        ),
      ),
    );
  }
}

class _AskComposer extends StatelessWidget {
  const _AskComposer({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.sendTooltip,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String sendTooltip;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.r18),
              border: Border.all(color: palette.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('ask.input'),
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: (_) => onSend(),
                    textInputAction: TextInputAction.send,
                    style: textTheme.bodyLarge,
                    cursorColor: palette.primary,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: palette.muted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                      ),
                      isCollapsed: true,
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    final canSend = enabled && value.text.trim().isNotEmpty;
                    return SizedBox.square(
                      dimension: 38,
                      child: IconButton.filled(
                        key: const Key('ask.send'),
                        onPressed: canSend ? onSend : null,
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
                        icon: const Icon(Icons.arrow_upward, size: 18),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
