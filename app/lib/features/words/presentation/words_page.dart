import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../timeline/domain/timeline_item.dart';
import '../../timeline/presentation/widgets/word_details_sheet.dart';
import '../../timeline/providers/timeline_providers.dart';
import '../domain/word_shelf.dart';
import '../providers/words_providers.dart';

class WordsPage extends ConsumerStatefulWidget {
  const WordsPage({super.key, this.initialWordId});

  final String? initialWordId;

  @override
  ConsumerState<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends ConsumerState<WordsPage> {
  var _showKnown = false;
  var _didOpenInitialWord = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t.words;
    final async = ref.watch(wordShelfProvider);

    return AppScaffold(
      title: t.title,
      centerBody: false,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(wordShelfProvider),
          ),
        ),
        data: (shelf) {
          if (shelf.words.isEmpty) {
            return Center(child: AppEmptyView(title: t.empty));
          }
          final initialWordId = widget.initialWordId;
          if (!_didOpenInitialWord && initialWordId != null) {
            _didOpenInitialWord = true;
            final matches = shelf.words.where(
              (item) => item.id == initialWordId,
            );
            if (matches.isNotEmpty) {
              final target = matches.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  unawaited(_openDetails(target));
                }
              });
            }
          }

          final needsReview = shelf.words
              .where((item) => item.status == WordShelfStatus.needsReview)
              .toList();
          final growing = shelf.words
              .where((item) => item.status == WordShelfStatus.growing)
              .toList();
          final known = shelf.words
              .where((item) => item.status == WordShelfStatus.known)
              .toList();

          return ListView(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            children: [
              _WordsHeader(
                shelf: shelf,
                onReview: () {
                  unawaited(_openReview());
                },
              ),
              if (needsReview.isNotEmpty)
                _WordSection(
                  label: t.needsReview,
                  items: needsReview,
                  onTap: _openDetails,
                  onTalk: _openTalk,
                ),
              if (growing.isNotEmpty)
                _WordSection(
                  label: t.growing,
                  items: growing,
                  onTap: _openDetails,
                  onTalk: _openTalk,
                ),
              if (known.isNotEmpty) ...[
                _SectionHeader(
                  label: t.known,
                  count: known.length,
                  trailing: Icon(
                    _showKnown ? Icons.expand_less : Icons.expand_more,
                    color: context.appPalette.muted,
                  ),
                  onTap: () => setState(() => _showKnown = !_showKnown),
                ),
                if (_showKnown)
                  for (final item in known)
                    _WordRow(
                      item: item,
                      onTap: () => _openDetails(item),
                      onTalk: () => _openTalk(item),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openReview() async {
    await context.pushNamed(AppRouteNames.review);
    if (mounted) {
      ref.invalidate(wordShelfProvider);
    }
  }

  Future<void> _openDetails(WordShelfItem item) async {
    await showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => WordDetailsSheet(
        item: _asTimelineItem(item),
        known: item.status == WordShelfStatus.known,
        onToggleKnown: () {
          Navigator.of(sheetContext).pop();
          unawaited(_toggleKnown(item));
        },
      ),
    );
  }

  Future<void> _toggleKnown(WordShelfItem item) async {
    try {
      await ref
          .read(wordsRepositoryProvider)
          .setKnown(
            wordId: item.id,
            known: item.status != WordShelfStatus.known,
          );
      ref.invalidate(wordShelfProvider);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openTalk(WordShelfItem item) async {
    final adapter = _asTimelineItem(item);
    try {
      final controller = ref.read(timelineControllerProvider.notifier);
      final conversationId = await controller.ensureConversation(adapter);
      if (!mounted) {
        return;
      }
      await context.pushNamed(
        AppRouteNames.talk,
        pathParameters: {'conversationId': conversationId},
        queryParameters: {
          if (item.label.trim().isNotEmpty) 'title': item.label,
        },
      );
      if (!mounted) {
        return;
      }
      await controller.afterTalk(
        conversationId: conversationId,
        title: item.label,
      );
      ref.invalidate(wordShelfProvider);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  TimelineWordItem _asTimelineItem(WordShelfItem item) {
    return TimelineWordItem(
      id: item.id,
      createdAt: item.lastSeenAt,
      inputText: null,
      wordId: item.id,
      word: item.word,
      audio: item.audio,
      conversationId: null,
    );
  }
}

class _WordsHeader extends StatelessWidget {
  const _WordsHeader({required this.shelf, required this.onReview});

  final WordShelf shelf;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final t = context.t.words;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final stats = shelf.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.yourWords.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(t.totalWords(count: stats.total), style: textTheme.displayMedium),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s10,
          runSpacing: AppSpacing.s4,
          children: [
            _StatText(
              label: t.newThisWeek(count: stats.newThisWeek),
              color: palette.accent,
            ),
            _StatText(label: t.reviewedThisWeek(count: stats.reviewedThisWeek)),
            _StatText(
              label: t.usedInTalkThisWeek(count: stats.usedInTalkThisWeek),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        TextButton.icon(
          key: const Key('words.review'),
          onPressed: onReview,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(t.review3),
        ),
      ],
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: color ?? context.appPalette.muted),
    );
  }
}

class _WordSection extends StatelessWidget {
  const _WordSection({
    required this.label,
    required this.items,
    required this.onTap,
    required this.onTalk,
  });

  final String label;
  final List<WordShelfItem> items;
  final void Function(WordShelfItem) onTap;
  final void Function(WordShelfItem) onTalk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(label: label, count: items.length),
        for (final item in items)
          _WordRow(
            item: item,
            onTap: () => onTap(item),
            onTalk: () => onTalk(item),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    this.trailing,
    this.onTap,
  });

  final String label;
  final int count;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final content = Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '$count',
          style: AppTextStyles.caption.copyWith(color: palette.muted),
        ),
        const SizedBox(width: AppSpacing.s10),
        Expanded(child: Container(height: 1, color: palette.line)),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.s8),
          trailing!,
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s20,
        bottom: AppSpacing.s8,
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.item,
    required this.onTap,
    required this.onTalk,
  });

  final WordShelfItem item;
  final VoidCallback onTap;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final word = item.word;
    final definition = word?.primarySense?.definitionZh;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: AppCard(
        key: Key('words.word.${item.id}'),
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: textTheme.headlineMedium),
                  if (definition != null && definition.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      definition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                  if (item.discoveryCount > 1) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      context.t.words.seenTimes(count: item.discoveryCount),
                      style: AppTextStyles.caption.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              key: Key('words.talk.${item.id}'),
              onPressed: onTalk,
              tooltip: context.t.timeline.talkAboutIt,
              icon: Icon(
                Icons.chat_bubble_outline,
                size: AppSize.size18,
                color: palette.primary,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: palette.muted,
              size: AppSize.size18,
            ),
          ],
        ),
      ),
    );
  }
}
