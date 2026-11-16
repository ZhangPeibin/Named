import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  const QuestionPage({super.key});

  @override
  ConsumerState<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<QuestionPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  var _questions = <Question>[];
  var _loading = true;
  var _asking = false;
  String? _error;
  String? _pendingQuestion;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(questionRepositoryProvider).fetchHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        _questions = items.reversed.toList();
        _loading = false;
      });
      _scrollToBottom();
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
      _pendingQuestion = text;
      _error = null;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final answer = await ref.read(questionRepositoryProvider).ask(text);
      if (!mounted) {
        return;
      }
      setState(() {
        _questions = [..._questions, answer];
        _pendingQuestion = null;
        _asking = false;
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingQuestion = null;
        _asking = false;
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
        _error = error.message;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.ask.error)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
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
                : _error != null && _questions.isEmpty
                ? AppErrorView(title: t.title, message: _error!, onRetry: _load)
                : _questions.isEmpty && _pendingQuestion == null
                ? _EmptyAsk(t: t, palette: palette)
                : ListView(
                    key: const Key('ask.list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                      AppSpacing.pageHorizontalPadding,
                      AppSpacing.s16,
                    ),
                    children: [
                      for (final question in _questions) ...[
                        _QuestionAnswer(question: question),
                        const SizedBox(height: AppSpacing.s20),
                      ],
                      if (_pendingQuestion != null)
                        _PendingQuestion(
                          question: _pendingQuestion!,
                          thinking: t.thinking,
                        ),
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

class _QuestionAnswer extends StatelessWidget {
  const _QuestionAnswer({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.ask;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
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
            child: Text(question.question, style: textTheme.bodyLarge),
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Container(
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
                    style: textTheme.labelLarge?.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s10),
              Text(question.answer, style: textTheme.bodyLarge),
              if (question.nativeExplanation.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Divider(color: palette.line, height: 1),
                const SizedBox(height: AppSpacing.s10),
                Text(
                  t.native.toUpperCase(),
                  style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  question.nativeExplanation,
                  style: textTheme.bodyMedium?.copyWith(color: palette.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingQuestion extends StatelessWidget {
  const _PendingQuestion({required this.question, required this.thinking});

  final String question;
  final String thinking;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
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
            child: Text(question, style: textTheme.bodyLarge),
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              thinking,
              style: textTheme.bodySmall?.copyWith(color: palette.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyAsk extends StatelessWidget {
  const _EmptyAsk({required this.t, required this.palette});

  final Translations$ask$en t;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
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
