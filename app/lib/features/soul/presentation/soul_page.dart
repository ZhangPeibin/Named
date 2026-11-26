import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/content_accent.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_async_view.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../i18n/strings.g.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../companion/presentation/widgets/companion_setup_sheet.dart';
import '../../companion/providers/companion_providers.dart';
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
    final companion = ref.watch(companionProvider).value;

    return AppScaffold(
      key: const Key('me.page'),
      title: '',
      showAppBar: false,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: AppAsyncView(
        value: soul,
        data: (value) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontalPadding,
            AppSpacing.s8,
            AppSpacing.pageHorizontalPadding,
            AppSpacing.s32,
          ),
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop())
                  Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.s8,
                      top: 1,
                    ),
                    child: InkResponse(
                      key: const Key('me.back'),
                      onTap: () => Navigator.of(context).maybePop(),
                      radius: 18,
                      child: AppLineIcon(
                        AppLineGlyph.arrowLeft,
                        size: AppSize.size18,
                        color: palette.primary,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Text(
                    t.title,
                    style: AppTextStyles.editorial.copyWith(
                      fontSize: 22,
                      height: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('me.settings'),
                  tooltip: context.t.settings.title,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      unawaited(context.pushNamed(AppRouteNames.settings)),
                  icon: AppLineIcon(
                    AppLineGlyph.settings,
                    size: AppSize.size18,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            _ProfileSection(
              soul: value,
              years: t.years,
              notSet: t.notSet,
              onEdit: () => _edit(context, ref, value),
            ),
            const SizedBox(height: AppSpacing.s24),
            _LinkRow(
              icon: AppLineGlyph.chat,
              color: ContentAccents.ask(context),
              title: context.t.companion.title,
              body: companion?.isNamed == true
                  ? context.t.companion.namedSubtitle(name: companion!.name!)
                  : context.t.companion.unnamedSubtitle,
              onTap: () {
                if (companion?.isNamed == true) {
                  unawaited(context.pushNamed(AppRouteNames.companion));
                } else {
                  unawaited(showCompanionSetupSheet(context));
                }
              },
            ),
            const SizedBox(height: AppSpacing.s24),
            _SectionHeader(
              label: t.notes,
              count: value.items.length,
              action: TextButton(
                key: const Key('soul.addItem'),
                onPressed: () => _addItem(context, ref),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  t.add,
                  style: AppTextStyles.label.copyWith(color: palette.accent),
                ),
              ),
            ),
            if (value.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                child: Text(
                  t.noItems,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              )
            else
              for (final item in value.items)
                _SoulItemTile(
                  item: item,
                  onEdit: () => _editItem(context, ref, item),
                  onDelete: () => _deleteItem(context, ref, item),
                ),
            const SizedBox(height: AppSpacing.s16),
            _SectionHeader(label: t.library),
            _LinkRow(
              icon: AppLineGlyph.flag,
              color: ContentAccents.challenges(context),
              title: context.t.challenge.title,
              body: t.rhythmBody,
              onTap: () =>
                  unawaited(context.pushNamed(AppRouteNames.challenges)),
            ),
            _LinkRow(
              icon: AppLineGlyph.headphones,
              color: ContentAccents.reads(context),
              title: context.t.daily.title,
              body: context.t.daily.body,
              onTap: () => unawaited(context.pushNamed(AppRouteNames.daily)),
            ),
            _LinkRow(
              icon: AppLineGlyph.bookmark,
              color: ContentAccents.words(context),
              title: context.t.words.title,
              body: t.wordsBody,
              onTap: () => unawaited(context.pushNamed(AppRouteNames.words)),
            ),
            _LinkRow(
              icon: AppLineGlyph.replay,
              color: ContentAccents.history(context),
              title: context.t.history.title,
              body: t.historyBody,
              onTap: () => unawaited(context.pushNamed(AppRouteNames.history)),
            ),
            const SizedBox(height: AppSpacing.s24),
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.soul,
    required this.years,
    required this.notSet,
    required this.onEdit,
  });

  final Soul soul;
  final String years;
  final String notSet;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.t.soul;
    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          label: t.profileTitle,
          action: TextButton(
            key: const Key('soul.editInline'),
            onPressed: onEdit,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              t.edit,
              style: AppTextStyles.label.copyWith(color: palette.accent),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ProfileValue(
                label: t.nativeLanguageShort,
                value: soul.nativeLanguage,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _ProfileValue(
                label: t.age,
                value: soul.age == null ? notSet : '${soul.age} $years',
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: _ProfileValue(
                label: t.gender,
                value: (soul.gender == null || soul.gender!.isEmpty)
                    ? notSet
                    : soul.gender!,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(
            color: palette.muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(value, style: textTheme.bodyMedium?.copyWith(color: palette.ink)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.count, this.action});

  final String label;
  final int? count;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.s8),
            Text(
              '$count',
              style: AppTextStyles.caption.copyWith(color: palette.muted),
            ),
          ],
          const SizedBox(width: AppSpacing.s10),
          Expanded(child: Container(height: 1, color: palette.line)),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.s8),
            action!,
          ],
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final AppLineGlyph icon;
  final Color color;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.s24,
              child: AppLineIcon(icon, size: AppSize.size20, color: color),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ],
              ),
            ),
            AppLineIcon(
              AppLineGlyph.chevronRight,
              color: palette.muted,
              size: AppSize.size16,
            ),
          ],
        ),
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

    return Container(
      key: Key('soul.item.${item.id}'),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.text, style: textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      _sourceLabel(t, item.source),
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('soul.delete.${item.id}'),
                tooltip: t.deleteItem,
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.s24,
                  minHeight: AppSpacing.s24,
                ),
                icon: AppLineIcon(
                  AppLineGlyph.trash,
                  size: AppSize.size16,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ),
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
