import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/content_accent.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../timeline/providers/timeline_providers.dart';
import '../domain/question.dart';
import '../providers/question_providers.dart';

class QuestionPage extends ConsumerStatefulWidget {
  const QuestionPage({
    super.key,
    this.threadId,
    this.context,
    this.suggestedQuestion,
  });

  final String? threadId;
  final QuestionContext? context;
  final String? suggestedQuestion;

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<QuestionPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  var _threads = <QuestionThreadSummary>[];
  QuestionThread? _thread;
  late QuestionContext? _context = widget.context;
  var _threadLoading = false;
  var _asking = false;
  String? _error;
  String? _pendingFollowUp;
  String? _pendingQuestion;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedQuestion != null) {
      _controller.text = widget.suggestedQuestion!;
    }
    if (widget.threadId != null) {
      unawaited(_openThread(widget.threadId!));
    } else {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final threads = await ref.read(questionRepositoryProvider).fetchThreads();
      if (mounted) {
        setState(() => _threads = threads);
      }
    } on ApiException {
      // History is secondary; the composer remains usable.
    }
  }

  Future<void> _openThread(String threadId) async {
    setState(() {
      _threadLoading = true;
      _error = null;
    });
    try {
      final thread = await ref
          .read(questionRepositoryProvider)
          .fetchThread(threadId);
      if (!mounted) {
        return;
      }
      setState(() {
        _thread = thread;
        _context = null;
        _threadLoading = false;
      });
      _scrollToBottom(jump: true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _threadLoading = false;
        });
      }
    }
  }

  Future<void> _ask() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _asking || _thread != null) {
      return;
    }
    setState(() {
      _asking = true;
      _pendingQuestion = text;
      _error = null;
    });
    _controller.clear();
    _scrollToBottom(jump: true);
    try {
      final thread = await ref
          .read(questionRepositoryProvider)
          .ask(text, context: _context);
      if (!mounted) {
        return;
      }
      setState(() {
        _thread = thread;
        _context = null;
        _pendingQuestion = null;
        _asking = false;
      });
      ref.invalidate(timelineControllerProvider);
      unawaited(_load());
      _scrollToBottom(jump: true);
    } on ApiException {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingQuestion = null;
        _asking = false;
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.ask.error)));
    }
  }

  Future<void> _followUp() async {
    final thread = _thread;
    final text = _controller.text.trim();
    if (thread == null || text.isEmpty || _asking) {
      return;
    }
    setState(() {
      _asking = true;
      _pendingFollowUp = text;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final updated = await ref
          .read(questionRepositoryProvider)
          .followUp(thread.id, text);
      if (!mounted) {
        return;
      }
      setState(() {
        _thread = updated;
        _pendingFollowUp = null;
        _asking = false;
      });
      ref.invalidate(timelineControllerProvider);
      unawaited(_load());
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingFollowUp = null;
        _asking = false;
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openHistory() async {
    await _load();
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appPalette.canvas,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.68,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontalPadding,
              AppSpacing.s16,
              AppSpacing.pageHorizontalPadding,
              AppSpacing.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.t.ask.recent.toUpperCase(),
                  style: AppTextStyles.eyebrow.copyWith(
                    color: context.appPalette.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Expanded(
                  child: _threads.isEmpty
                      ? Center(
                          child: Text(
                            context.t.ask.emptyHistory,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: context.appPalette.muted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _threads.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.s8),
                          itemBuilder: (context, index) => _ThreadList(
                            threads: [_threads[index]],
                            onTap: (item) {
                              Navigator.of(context).pop();
                              unawaited(_openThread(item.id));
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearThread() {
    setState(() {
      _thread = null;
      _pendingFollowUp = null;
      _pendingQuestion = null;
      _context = null;
      _controller.clear();
    });
    unawaited(_load());
  }

  Future<void> _deleteThread() async {
    final thread = _thread;
    if (thread == null) {
      return;
    }
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
    await ref.read(questionRepositoryProvider).deleteThread(thread.id);
    if (mounted) {
      _clearThread();
    }
  }

  void _useSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    _focusNode.requestFocus();
  }

  Future<void> _sendFeedback(String messageId, String feedback) async {
    final thread = _thread;
    if (thread == null) {
      return;
    }
    try {
      await ref
          .read(questionRepositoryProvider)
          .setFeedback(
            threadId: thread.id,
            messageId: messageId,
            feedback: feedback,
          );
    } on ApiException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.t.ask.feedbackError)));
      }
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

  @override
  Widget build(BuildContext context) {
    final t = context.t.ask;
    final thread = _thread;

    return AppScaffold(
      key: const Key('ask.page'),
      title: t.title,
      centerBody: false,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          key: const Key('ask.history'),
          tooltip: t.recent,
          onPressed: _openHistory,
          icon: const AppLineIcon(AppLineGlyph.chat),
        ),
        if (thread != null)
          IconButton(
            key: const Key('ask.delete'),
            tooltip: t.delete,
            onPressed: _deleteThread,
            icon: const AppLineIcon(AppLineGlyph.trash),
          ),
      ],
      body: Column(
        children: [
          Expanded(
            child: _threadLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && thread == null
                ? AppErrorView(
                    title: t.loadFailed,
                    message: _error!,
                    onRetry: () {
                      final threadId = widget.threadId;
                      if (threadId != null) {
                        unawaited(_openThread(threadId));
                      } else {
                        setState(() => _error = null);
                      }
                    },
                  )
                : thread == null
                ? _buildIntro(t)
                : _buildThread(thread),
          ),
          _AskComposer(
            controller: _controller,
            focusNode: _focusNode,
            hintText: thread == null ? t.placeholder : t.followUpHint,
            sendTooltip: thread == null ? t.send : t.followUp,
            enabled: !_asking,
            onSend: thread == null ? _ask : _followUp,
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(Translations$ask$en t) {
    return ListView(
      controller: _scrollController,
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
        _AgentGreeting(text: t.agentGreeting),
        const SizedBox(height: AppSpacing.s16),
        _SuggestionList(t: t, onSelected: _useSuggestion),
        if (_pendingQuestion != null) ...[
          const SizedBox(height: AppSpacing.s20),
          _QuestionMessageView(
            message: QuestionMessage(
              id: 'pending',
              role: 'user',
              text: _pendingQuestion!,
              example: null,
              nativeExplanation: null,
              confidence: null,
              followUpSuggestions: const [],
              feedback: null,
              createdAt: DateTime.now(),
            ),
          ),
          const SizedBox(height: AppSpacing.s10),
          _ThinkingRow(text: t.thinking),
        ],
      ],
    );
  }

  Widget _buildThread(QuestionThread thread) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s16,
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s16,
      ),
      children: [
        if (thread.contextQuote != null) ...[
          _ContextCard(
            context: QuestionContext(
              type: thread.contextType ?? 'none',
              ref: thread.contextRef,
              quote: thread.contextQuote,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
        ],
        for (final message in thread.messages) ...[
          _QuestionMessageView(
            message: message,
            onSuggestion: _useSuggestion,
            onFeedback: message.isUser
                ? null
                : (feedback) => _sendFeedback(message.id, feedback),
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
              feedback: null,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appPalette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
        ],
      ],
    );
  }
}

class _AskAgentAvatar extends StatelessWidget {
  const _AskAgentAvatar({this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(color: palette.line),
      ),
      child: AppLineIcon(
        AppLineGlyph.chat,
        size: size * 0.5,
        color: palette.primary,
      ),
    );
  }
}

class _AgentGreeting extends StatelessWidget {
  const _AgentGreeting({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AskAgentAvatar(),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: palette.line),
            ),
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}

class _ThinkingRow extends StatelessWidget {
  const _ThinkingRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      children: [
        const _AskAgentAvatar(size: 24),
        const SizedBox(width: AppSpacing.s8),
        SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: palette.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

class _ThreadList extends StatelessWidget {
  const _ThreadList({required this.threads, required this.onTap});

  final List<QuestionThreadSummary> threads;
  final ValueChanged<QuestionThreadSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < threads.length; index++) ...[
            _ThreadRow(
              thread: threads[index],
              onTap: () => onTap(threads[index]),
            ),
            if (index < threads.length - 1)
              Divider(height: 1, indent: AppSpacing.s40, color: palette.line),
          ],
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              AppLineIcon(
                thread.contextType == null
                    ? AppLineGlyph.chat
                    : AppLineGlyph.bookmark,
                color: ContentAccents.ask(context),
                size: 18,
              ),
              const SizedBox(width: AppSpacing.s12),
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
              AppLineIcon(
                AppLineGlyph.chevronRight,
                color: palette.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionMessageView extends StatelessWidget {
  const _QuestionMessageView({
    required this.message,
    this.onSuggestion,
    this.onFeedback,
  });

  final QuestionMessage message;
  final ValueChanged<String>? onSuggestion;
  final Future<void> Function(String)? onFeedback;

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AskAgentAvatar(size: 28),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: palette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t.named,
                      style: textTheme.labelLarge?.copyWith(color: palette.ink),
                    ),
                    if (confidence != null) ...[
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        confidence,
                        style: AppTextStyles.caption.copyWith(
                          color: palette.muted,
                        ),
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
                    style: textTheme.bodyMedium?.copyWith(color: palette.ink),
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
                if (onFeedback != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  _FeedbackRow(
                    initial: message.feedback,
                    onFeedback: onFeedback!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackRow extends StatefulWidget {
  const _FeedbackRow({required this.initial, required this.onFeedback});

  final String? initial;
  final Future<void> Function(String) onFeedback;

  @override
  State<_FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends State<_FeedbackRow> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  void _select(String feedback) {
    if (_selected == feedback) {
      return;
    }
    setState(() => _selected = feedback);
    unawaited(widget.onFeedback(feedback));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.ask;
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s4,
      children: [
        _FeedbackButton(
          key: const Key('ask.helpful'),
          label: t.helpful,
          selected: _selected == 'helpful',
          up: true,
          onTap: () => _select('helpful'),
        ),
        _FeedbackButton(
          key: const Key('ask.notHelpful'),
          label: t.notHelpful,
          selected: _selected == 'not_helpful',
          up: false,
          onTap: () => _select('not_helpful'),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    super.key,
    required this.label,
    required this.selected,
    required this.up,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool up;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: selected ? palette.primary : palette.muted,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: AppLineIcon(
        up
            ? (selected ? AppLineGlyph.thumbUp : AppLineGlyph.thumbUp)
            : (selected ? AppLineGlyph.thumbDown : AppLineGlyph.thumbDown),
        size: 15,
      ),
      label: Text(label),
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
              icon: AppLineIcon(
                AppLineGlyph.close,
                size: 18,
                color: palette.muted,
              ),
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
    final palette = context.appPalette;
    final suggestions = [t.suggestion1, t.suggestion2, t.suggestion3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.suggestions.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.s8),
            itemBuilder: (context, index) => ActionChip(
              label: Text(suggestions[index]),
              labelStyle: AppTextStyles.caption.copyWith(color: palette.ink),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: palette.line),
              backgroundColor: palette.surface,
              onPressed: () => onSelected(suggestions[index]),
            ),
          ),
        ),
      ],
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
                        icon: AppLineIcon(
                          AppLineGlyph.arrowUp,
                          size: 18,
                          color: canSend ? palette.onPrimary : palette.muted,
                        ),
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
