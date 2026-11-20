import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../i18n/strings.g.dart';
import '../../auth/providers/auth_notifier.dart';
import '../domain/soul.dart';
import '../providers/soul_providers.dart';

class SoulPage extends ConsumerWidget {
  const SoulPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.soul;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final soul = ref.watch(soulProvider);

    return AppScaffold(
      key: const Key('me.page'),
      title: t.title,
      centerBody: false,
      actions: [
        IconButton(
          key: const Key('me.settings'),
          tooltip: context.t.settings.title,
          onPressed: () => unawaited(context.pushNamed(AppRouteNames.settings)),
          icon: const AppLineIcon(AppLineGlyph.settings),
        ),
      ],
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s8,
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s32,
      ),
      body: AppAsyncView(
        value: soul,
        data: (value) => ListView(
          children: [
            Text(
              t.eyebrow,
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(t.headline, style: textTheme.displayMedium),
            const SizedBox(height: AppSpacing.s10),
            Text(
              t.subtitle,
              style: textTheme.bodyLarge?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _RoundIcon(icon: AppLineGlyph.person),
                      const SizedBox(width: AppSpacing.s14),
                      Expanded(
                        child: Text(t.profile, style: textTheme.headlineMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    _metadata(t.years, value),
                    style: textTheme.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppSectionHeader(title: t.items),
            const SizedBox(height: AppSpacing.s12),
            if (value.items.isEmpty)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: Text(
                  t.noItems,
                  style: textTheme.bodyMedium?.copyWith(color: palette.muted),
                ),
              )
            else
              Column(
                children: [
                  for (final item in value.items) ...[
                    _SoulItemTile(
                      item: item,
                      onEdit: () => _editItem(context, ref, item),
                      onDelete: () => _deleteItem(context, ref, item),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                  ],
                ],
              ),
            const SizedBox(height: AppSpacing.s12),
            AppButton(
              key: const Key('soul.addItem'),
              label: t.addItem,
              variant: AppButtonVariant.secondary,
              onPressed: () => _addItem(context, ref),
            ),
            const SizedBox(height: AppSpacing.s32),
            AppSectionHeader(title: t.rhythm),
            const SizedBox(height: AppSpacing.s12),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.s16),
              onTap: () =>
                  unawaited(context.pushNamed(AppRouteNames.challenges)),
              child: Row(
                children: [
                  const _RoundIcon(icon: AppLineGlyph.flag),
                  const SizedBox(width: AppSpacing.s14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t.challenge.title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.rhythmBody,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppLineIcon(AppLineGlyph.chevronRight, color: palette.muted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s32),
            AppSectionHeader(title: t.library),
            const SizedBox(height: AppSpacing.s12),
            _LibraryCard(
              icon: AppLineGlyph.headphones,
              title: context.t.daily.title,
              body: context.t.daily.body,
              onTap: () => unawaited(context.pushNamed(AppRouteNames.daily)),
            ),
            const SizedBox(height: AppSpacing.s8),
            _LibraryCard(
              icon: AppLineGlyph.book,
              title: context.t.words.title,
              body: t.wordsBody,
              onTap: () => unawaited(context.pushNamed(AppRouteNames.words)),
            ),
            const SizedBox(height: AppSpacing.s8),
            _LibraryCard(
              icon: AppLineGlyph.book,
              title: context.t.history.title,
              body: t.historyBody,
              onTap: () => unawaited(context.pushNamed(AppRouteNames.history)),
            ),
            const SizedBox(height: AppSpacing.s32),
            AppButton(
              key: const Key('soul.editPrimary'),
              label: t.edit,
              onPressed: () => _edit(context, ref, value),
            ),
            const SizedBox(height: AppSpacing.s8),
            AppButton(
              key: const Key('me.signOut'),
              label: context.t.auth.signOut,
              variant: AppButtonVariant.text,
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }

  String _metadata(String years, Soul soul) {
    final parts = <String>[
      if (soul.age != null) '${soul.age} $years',
      if (soul.gender != null && soul.gender!.isNotEmpty) soul.gender!,
      soul.nativeLanguage,
    ];
    return parts.join(' · ');
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final created = await showAppBottomSheet<SoulItem>(
      context: context,
      builder: (context) => const _SoulItemSheet(),
    );
    if (created == null || !context.mounted) {
      return;
    }
    ref.invalidate(soulProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t.soul.saved)));
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    SoulItem item,
  ) async {
    final updated = await showAppBottomSheet<SoulItem>(
      context: context,
      builder: (context) => _SoulItemSheet(initial: item),
    );
    if (updated == null || !context.mounted) {
      return;
    }
    ref.invalidate(soulProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t.soul.saved)));
  }

  Future<void> _deleteItem(
    BuildContext context,
    WidgetRef ref,
    SoulItem item,
  ) async {
    final t = context.t.soul;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteConfirmTitle),
        content: Text(t.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.deleteItem),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(soulRepositoryProvider).deleteItem(item.id);
      ref.invalidate(soulProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.deleted)));
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Soul soul) async {
    final updated = await showAppBottomSheet<bool>(
      context: context,
      builder: (context) => _EditSoulSheet(initial: soul),
    );
    if (updated == true && context.mounted) {
      ref.invalidate(soulProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.soul.saved)));
    }
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final AppLineGlyph icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      onTap: onTap,
      child: Row(
        children: [
          _RoundIcon(icon: icon),
          const SizedBox(width: AppSpacing.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          AppLineIcon(AppLineGlyph.chevronRight, color: palette.muted),
        ],
      ),
    );
  }
}

class _SoulItemTile extends StatelessWidget {
  const _SoulItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final SoulItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.soul;

    return AppCard(
      key: Key('soul.item.${item.id}'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s12,
      ),
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.text, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  _sourceLabel(t, item.source),
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('soul.delete.${item.id}'),
            tooltip: t.deleteItem,
            onPressed: onDelete,
            icon: AppLineIcon(
              AppLineGlyph.trash,
              size: AppSize.size20,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(Translations$soul$en t, String source) {
    return switch (source) {
      'onboarding' => t.sourceOnboarding,
      'user_edit' => t.sourceUser,
      'ai_extracted' || 'extracted' => t.sourceAi,
      _ => t.sourceAi,
    };
  }
}

class _SoulItemSheet extends ConsumerStatefulWidget {
  const _SoulItemSheet({this.initial});

  final SoulItem? initial;

  @override
  ConsumerState<_SoulItemSheet> createState() => _SoulItemSheetState();
}

class _SoulItemSheetState extends ConsumerState<_SoulItemSheet> {
  late final TextEditingController _textController;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initial?.text ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t.soul;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = t.itemRequired);
      return;
    }
    setState(() {
      _error = null;
      _isSaving = true;
    });
    try {
      final repository = ref.read(soulRepositoryProvider);
      final initial = widget.initial;
      final item = initial == null
          ? await repository.createItem(kind: 'note', text: text)
          : await repository.updateItem(
              id: initial.id,
              kind: initial.kind,
              text: text,
            );
      if (mounted) {
        Navigator.of(context).pop(item);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.soul;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? t.addItem : t.editItemTitle,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.s16),
          AppTextField(
            key: const Key('soul.itemText'),
            controller: _textController,
            labelText: t.itemText,
            errorText: _error,
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: AppSpacing.s20),
          AppButton(
            key: const Key('soul.itemSave'),
            label: _isSaving ? t.saving : t.save,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});

  final AppLineGlyph icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      width: AppSize.size40,
      height: AppSize.size40,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AppLineIcon(icon, color: palette.primary, size: AppSize.size20),
    );
  }
}

class _EditSoulSheet extends ConsumerStatefulWidget {
  const _EditSoulSheet({required this.initial});

  final Soul initial;

  @override
  ConsumerState<_EditSoulSheet> createState() => _EditSoulSheetState();
}

class _EditSoulSheetState extends ConsumerState<_EditSoulSheet> {
  late final TextEditingController _nativeLanguageController;
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;

  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nativeLanguageController = TextEditingController(
      text: widget.initial.nativeLanguage,
    );
    _ageController = TextEditingController(
      text: widget.initial.age?.toString() ?? '',
    );
    _genderController = TextEditingController(
      text: widget.initial.gender ?? '',
    );
  }

  @override
  void dispose() {
    _nativeLanguageController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t.soul;
    final nativeLanguage = _nativeLanguageController.text.trim();
    if (nativeLanguage.isEmpty) {
      setState(() => _error = t.nativeLanguageRequired);
      return;
    }

    final rawAge = _ageController.text.trim();
    final age = rawAge.isEmpty ? null : int.tryParse(rawAge);
    if (rawAge.isNotEmpty && (age == null || age < 0 || age > 120)) {
      setState(() => _error = t.invalidAge);
      return;
    }

    final gender = _genderController.text.trim();
    setState(() {
      _error = null;
      _isSaving = true;
    });

    try {
      await ref
          .read(soulRepositoryProvider)
          .updateSoul(
            nativeLanguage: nativeLanguage,
            age: age,
            gender: gender.isEmpty ? null : gender,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.soul;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.editTitle, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.s8),
          Text(
            t.editSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s20),
          AppTextField(
            key: const Key('soul.nativeLanguage'),
            controller: _nativeLanguageController,
            labelText: t.nativeLanguage,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppTextField(
            key: const Key('soul.age'),
            controller: _ageController,
            labelText: t.age,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppTextField(
            key: const Key('soul.gender'),
            controller: _genderController,
            labelText: t.gender,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) async {
              if (!_isSaving) {
                await _save();
              }
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              _error!,
              style: textTheme.bodySmall?.copyWith(color: palette.error),
            ),
          ],
          const SizedBox(height: AppSpacing.s20),
          AppButton(
            key: const Key('soul.save'),
            label: t.save,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(height: AppSpacing.s8),
          AppButton(
            label: t.cancel,
            variant: AppButtonVariant.text,
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
