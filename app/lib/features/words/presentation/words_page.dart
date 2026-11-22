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
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../../timeline/domain/timeline_item.dart';
import '../../timeline/presentation/widgets/word_audio_button.dart';
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
    final palette = context.appPalette;
    final async = ref.watch(wordShelfProvider);

    return AppScaffold(
      title: '',
      showAppBar: false,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: Container(
        color: palette.surface,
        child: async.when(
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
            final attempted = shelf.words
                .where((item) => item.status == WordShelfStatus.attempted)
                .toList();
            final known = shelf.words
                .where((item) => item.status == WordShelfStatus.known)
                .toList();

            var cursor = 0;
            final needsReviewStart = cursor;
            cursor += needsReview.length;
            final attemptedStart = cursor;
            cursor += attempted.length;
            final knownStart = cursor;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s8,
                AppSpacing.s20,
                AppSpacing.s32,
              ),
              children: [
                _NotebookHeader(shelf: shelf),
                if (needsReview.isNotEmpty)
                  _WordSection(
                    label: t.needsReview,
                    color: palette.accent,
                    items: needsReview,
                    startIndex: needsReviewStart,
                    onTap: _openDetails,
                    onTalk: _openTalk,
                  ),
                if (attempted.isNotEmpty)
                  _WordSection(
                    label: t.attempted,
                    color: palette.primary,
                    items: attempted,
                    startIndex: attemptedStart,
                    onTap: _openDetails,
                    onTalk: _openTalk,
                  ),
                if (known.isNotEmpty) ...[
                  _SectionHeader(
                    label: t.known,
                    count: known.length,
                    color: palette.muted,
                    trailing: AppLineIcon(
                      _showKnown
                          ? AppLineGlyph.chevronUp
                          : AppLineGlyph.chevronDown,
                      color: palette.muted,
                      size: AppSize.size18,
                    ),
                    onTap: () => setState(() => _showKnown = !_showKnown),
                  ),
                  if (_showKnown)
                    for (var index = 0; index < known.length; index++)
                      _NotebookWordRow(
                        number: knownStart + index + 1,
                        item: known[index],
                        onTap: () => _openDetails(known[index]),
                        onTalk: () => _openTalk(known[index]),
                      ),
                ],
              ],
            );
          },
        ),
      ),
    );
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

class _NotebookHeader extends StatelessWidget {
  const _NotebookHeader({required this.shelf});

  final WordShelf shelf;

  @override
  Widget build(BuildContext context) {
    final t = context.t.words;
    final palette = context.appPalette;
    final stats = shelf.stats;
    final summary = [
      t.totalWords(count: stats.total),
      t.newThisWeek(count: stats.newThisWeek),
      t.usedInTalkThisWeek(count: stats.usedInTalkThisWeek),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s6,
        bottom: AppSpacing.s10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.s4,
                              top: 1,
                            ),
                            child: InkResponse(
                              key: const Key('words.back'),
                              onTap: () => Navigator.of(context).maybePop(),
                              radius: 18,
                              child: AppLineIcon(
                                AppLineGlyph.arrowLeft,
                                size: AppSize.size18,
                                color: palette.primary,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            t.notebookEyebrow.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.eyebrow.copyWith(
                              color: palette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      t.title,
                      style: AppTextStyles.editorial.copyWith(
                        fontSize: 29,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            summary,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _WordSection extends StatelessWidget {
  const _WordSection({
    required this.label,
    required this.color,
    required this.items,
    required this.startIndex,
    required this.onTap,
    required this.onTalk,
  });

  final String label;
  final Color color;
  final List<WordShelfItem> items;
  final int startIndex;
  final void Function(WordShelfItem) onTap;
  final void Function(WordShelfItem) onTalk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(label: label, count: items.length, color: color),
        for (var index = 0; index < items.length; index++)
          _NotebookWordRow(
            number: startIndex + index + 1,
            item: items[index],
            onTap: () => onTap(items[index]),
            onTalk: () => onTalk(items[index]),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    this.trailing,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final content = Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '$count',
          style: AppTextStyles.caption.copyWith(color: palette.muted),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(child: Container(height: 1, color: palette.line)),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.s8),
          trailing!,
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: 0),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _NotebookWordRow extends StatelessWidget {
  const _NotebookWordRow({
    required this.number,
    required this.item,
    required this.onTap,
    required this.onTalk,
  });

  final int number;
  final WordShelfItem item;
  final VoidCallback onTap;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.words;
    final word = item.word;

    final ipa = word == null
        ? ''
        : word.ipa.values
              .where((value) => value.isNotEmpty)
              .toSet()
              .join(' / ');
    final pos = word?.pos.join(', ') ?? '';
    final definition = word?.primarySense?.definitionZh;
    final chunk = word == null || word.chunks.isEmpty
        ? null
        : word.chunks.first;
    final statusColor = switch (item.status) {
      WordShelfStatus.needsReview => palette.accent,
      WordShelfStatus.attempted => palette.primary,
      WordShelfStatus.known => palette.muted,
    };
    return InkWell(
      key: Key('words.word.${item.id}'),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppSpacing.s24,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: AppTextStyles.caption.copyWith(color: palette.muted),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: palette.accent.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: AppSpacing.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: item.label,
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontFamilyFallback:
                                        AppTextStyles.editorialFallback,
                                    fontSize: 20,
                                    height: 1.05,
                                    fontWeight: FontWeight.w600,
                                    fontVariations: [
                                      FontVariation('wght', 600),
                                    ],
                                  ).copyWith(color: palette.ink),
                                ),
                                if (ipa.isNotEmpty)
                                  TextSpan(
                                    text: '  $ipa',
                                    style: AppTextStyles.caption.copyWith(
                                      color: palette.muted,
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        WordAudioButton(
                          audio: item.audio,
                          dimension: 24,
                          iconSize: 11,
                        ),
                        IconButton(
                          key: Key('words.talk.${item.id}'),
                          onPressed: onTalk,
                          tooltip: context.t.timeline.talkAboutIt,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: AppSpacing.s24,
                            minHeight: AppSpacing.s24,
                          ),
                          icon: AppLineIcon(
                            AppLineGlyph.chat,
                            size: AppSize.size16,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                    if (pos.isNotEmpty)
                      Transform.translate(
                        offset: const Offset(0, -1),
                        child: Text(
                          pos,
                          style: AppTextStyles.caption.copyWith(
                            color: palette.muted,
                            height: 1.15,
                          ),
                        ),
                      ),
                    if (definition != null && definition.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        definition,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.ink.withValues(alpha: 0.78),
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (chunk != null) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        chunk.phrase,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.ink,
                        ),
                      ),
                    ],
                    if (item.discoveryCount > 1) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s6),
                          Text(
                            t.seenTimes(count: item.discoveryCount),
                            style: AppTextStyles.caption.copyWith(
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
