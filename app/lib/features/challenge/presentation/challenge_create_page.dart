import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../i18n/strings.g.dart';
import '../../timeline/domain/timeline_item.dart' as timeline;
import '../../timeline/providers/timeline_providers.dart';
import '../providers/challenge_providers.dart';

class ChallengeCreatePage extends ConsumerStatefulWidget {
  const ChallengeCreatePage({super.key});

  @override
  ConsumerState<ChallengeCreatePage> createState() =>
      _ChallengeCreatePageState();
}

class _ChallengeCreatePageState extends ConsumerState<ChallengeCreatePage> {
  final _nameController = TextEditingController();
  final _customDaysController = TextEditingController(text: '14');
  final _selected = <String>{};
  var _days = 2;
  var _customDays = false;
  var _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  int get _plannedDays {
    if (!_customDays) {
      return _days;
    }
    return int.tryParse(_customDaysController.text) ?? 0;
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final days = _plannedDays;
    if (name.isEmpty || days < 1 || _selected.isEmpty || _isCreating) {
      return;
    }
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(challengeActionsProvider)
          .create(
            name: name,
            plannedDays: days,
            discoveryIds: _selected.toList(),
          );
      if (mounted) {
        context.pushReplacementNamed(
          AppRouteNames.challengeDetail,
          pathParameters: {'challengeId': challenge.id},
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.t.challenge.createFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.challenge;
    final timelineAsync = ref.watch(timelineControllerProvider);

    return AppScaffold(
      title: t.start,
      centerBody: false,
      body: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: AppErrorView(
            title: t.loadFailed,
            message: error is ApiException
                ? error.message
                : context.t.common.somethingWentWrong,
            onRetry: () => ref.invalidate(timelineControllerProvider),
          ),
        ),
        data: (state) {
          final candidates = state.items
              .whereType<timeline.TimelineWordItem>()
              .map(_Candidate.word)
              .followedBy(
                state.items.whereType<timeline.TimelineSceneItem>().map(
                  _Candidate.scene,
                ),
              )
              .toList();
          if (candidates.isEmpty) {
            return Center(child: AppEmptyView(title: t.noContent));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s24),
            children: [
              AppTextField(
                key: const Key('challenge.name'),
                controller: _nameController,
                labelText: t.name,
                hintText: t.nameHint,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                t.duration.toUpperCase(),
                style: AppTextStyles.eyebrow.copyWith(
                  color: context.appPalette.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Wrap(
                spacing: AppSpacing.s8,
                children: [
                  _DurationChip(
                    label: t.twoDays,
                    selected: !_customDays && _days == 2,
                    onTap: () => setState(() => _days = 2),
                  ),
                  _DurationChip(
                    label: t.oneWeek,
                    selected: !_customDays && _days == 7,
                    onTap: () => setState(() => _days = 7),
                  ),
                  _DurationChip(
                    label: t.custom,
                    selected: _customDays,
                    onTap: () => setState(() => _customDays = true),
                  ),
                ],
              ),
              if (_customDays) ...[
                const SizedBox(height: AppSpacing.s12),
                AppTextField(
                  key: const Key('challenge.customDays'),
                  controller: _customDaysController,
                  labelText: t.days,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.chooseContent.toUpperCase(),
                      style: AppTextStyles.eyebrow.copyWith(
                        color: context.appPalette.muted,
                      ),
                    ),
                  ),
                  Text(
                    t.selectedCount.replaceFirst(
                      '{count}',
                      '${_selected.length}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appPalette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              for (final candidate in candidates)
                _CandidateRow(
                  candidate: candidate,
                  selected: _selected.contains(candidate.id),
                  onTap: () {
                    setState(() {
                      if (!_selected.add(candidate.id)) {
                        _selected.remove(candidate.id);
                      }
                      _error = null;
                    });
                  },
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appPalette.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s20),
              AppButton(
                key: const Key('challenge.create'),
                label: t.create,
                isLoading: _isCreating,
                onPressed:
                    _nameController.text.trim().isEmpty ||
                        _selected.isEmpty ||
                        _plannedDays < 1
                    ? null
                    : _create,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Candidate {
  const _Candidate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isWord,
  });

  factory _Candidate.word(timeline.TimelineWordItem item) {
    return _Candidate(
      id: item.id,
      title: item.word?.spelling ?? item.inputText ?? 'Word',
      subtitle: item.inputText,
      isWord: true,
    );
  }

  factory _Candidate.scene(timeline.TimelineSceneItem item) {
    return _Candidate(
      id: item.id,
      title: item.scene.naturalEnglish,
      subtitle: item.inputText,
      isWord: false,
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final bool isWord;
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final _Candidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.s12),
        color: selected ? palette.warm : null,
        child: Row(
          children: [
            Icon(
              candidate.isWord
                  ? Icons.menu_book_outlined
                  : Icons.photo_outlined,
              color: palette.primary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.title),
                  if (candidate.subtitle != null &&
                      candidate.subtitle!.trim().isNotEmpty)
                    Text(
                      candidate.subtitle!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.muted),
                    ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? palette.accent : palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: palette.primary,
      labelStyle: TextStyle(
        color: selected ? palette.onPrimary : palette.primary,
      ),
    );
  }
}
