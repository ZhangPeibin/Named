import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/companion_profile.dart';
import '../../providers/companion_providers.dart';
import 'companion_avatar.dart';

Future<CompanionProfile?> showCompanionSetupSheet(
  BuildContext context, {
  CompanionProfile? initial,
}) {
  return showAppBottomSheet<CompanionProfile>(
    context: context,
    builder: (context) => CompanionSetupSheet(initial: initial),
  );
}

class CompanionSetupSheet extends ConsumerStatefulWidget {
  const CompanionSetupSheet({super.key, this.initial});

  final CompanionProfile? initial;

  @override
  ConsumerState<CompanionSetupSheet> createState() =>
      _CompanionSetupSheetState();
}

class _CompanionSetupSheetState extends ConsumerState<CompanionSetupSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _hobbyController;
  CompanionGender? _gender;
  String? _error;
  String? _suggestion;
  bool _isSaving = false;
  CompanionProfile? _saved;

  bool get _isEditing => widget.initial?.isNamed == true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _hobbyController = TextEditingController(text: widget.initial?.hobby ?? '');
    _gender = widget.initial?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hobbyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t.companion;
    final name = _nameController.text.trim();
    final hobby = _hobbyController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.nameRequired);
      return;
    }
    if (name.length > 16) {
      setState(() => _error = t.nameTooLong);
      return;
    }
    if (hobby.length > 24) {
      setState(() => _error = t.hobbyTooLong);
      return;
    }

    setState(() {
      _error = null;
      _suggestion = null;
      _isSaving = true;
    });

    try {
      final profile = await ref
          .read(companionControllerProvider)
          .saveProfile(
            name: name,
            gender: _gender,
            hobby: hobby.isEmpty ? null : hobby,
          );
      if (!mounted) {
        return;
      }
      if (_isEditing) {
        Navigator.of(context).pop(profile);
      } else {
        setState(() => _saved = profile);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = _messageFor(error));
        if (error.code == 'companion_name_rejected') {
          unawaited(_loadSuggestion());
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _loadSuggestion() async {
    try {
      final name = await ref.read(companionControllerProvider).suggestName();
      if (mounted) {
        setState(() => _suggestion = name);
      }
    } on ApiException {
      if (mounted) {
        setState(() => _suggestion = null);
      }
    }
  }

  void _clearMessages() {
    setState(() {
      _error = null;
      _suggestion = null;
    });
  }

  String _messageFor(ApiException error) {
    final t = context.t.companion;
    return switch (error.code) {
      'companion_name_required' => t.nameRequired,
      'companion_name_too_long' => t.nameTooLong,
      'companion_hobby_too_long' => t.hobbyTooLong,
      'companion_name_rejected' => t.nameRejected,
      'companion_hobby_rejected' => t.hobbyRejected,
      _ => t.saveFailed,
    };
  }

  String _genderLabel(CompanionGender gender) {
    final t = context.t.companion;
    return switch (gender) {
      CompanionGender.female => t.genderFemale,
      CompanionGender.male => t.genderMale,
      CompanionGender.preferNotToSay => t.genderPreferNotToSay,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.companion;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final saved = _saved;

    if (saved != null) {
      return Column(
        key: const Key('companion.saved'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: CompanionAvatar(size: 72)),
          const SizedBox(height: AppSpacing.s16),
          Text(
            t.namedFirstLine(name: saved.name ?? ''),
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.s20),
          AppButton(
            key: const Key('companion.start'),
            label: t.start,
            onPressed: () => Navigator.of(context).pop(saved),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(t.setupTitle, style: textTheme.headlineMedium),
              ),
              IconButton(
                key: const Key('companion.close'),
                tooltip: context.t.common.close,
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const AppLineIcon(AppLineGlyph.close, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          AppTextField(
            key: const Key('companion.nameInput'),
            controller: _nameController,
            labelText: t.nameLabel,
            hintText: t.nameHint,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearMessages(),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppField(
            label: t.genderLabel,
            child: Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final gender in CompanionGender.values)
                  ChoiceChip(
                    key: Key('companion.gender.${gender.name}'),
                    label: Text(_genderLabel(gender)),
                    selected: _gender == gender,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _gender = gender),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppTextField(
            key: const Key('companion.hobbyInput'),
            controller: _hobbyController,
            labelText: t.hobbyLabel,
            hintText: t.hobbyHint,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _clearMessages(),
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
          if (_suggestion != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.randomSuggestion(name: _suggestion!),
                    style: textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ),
                TextButton(
                  key: const Key('companion.useRandom'),
                  onPressed: () {
                    setState(() {
                      _nameController.text = _suggestion!;
                      _suggestion = null;
                      _error = null;
                    });
                  },
                  child: Text(t.useRandom(name: _suggestion!)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s20),
          AppButton(
            key: const Key('companion.save'),
            label: _isEditing ? t.saveEdit : t.save,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
