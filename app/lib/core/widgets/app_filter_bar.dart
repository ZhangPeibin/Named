import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppFilterData {
  const AppFilterData({
    required this.chipLabel,
    required this.isActive,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  final String chipLabel;
  final bool isActive;
  final Object selectedValue;
  final List<AppFilterOption> options;
  final ValueChanged<Object> onSelected;
}

class AppFilterOption {
  const AppFilterOption({required this.value, required this.label});

  final Object value;
  final String label;
}

class AppFilterBar extends StatelessWidget {
  const AppFilterBar({super.key, required this.filters});

  final List<AppFilterData> filters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s4,
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s14,
      ),
      child: Row(
        children: [
          for (final (index, filter) in filters.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.s10),
            _FilterChipButton(
              label: filter.chipLabel,
              isActive: filter.isActive,
              onTap: () => _showFilterSheet(context, filter),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    AppFilterData filter,
  ) async {
    final selected = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _FilterSheet(
        children: [
          for (final option in filter.options)
            _FilterOptionTile(
              label: option.label,
              selected: option.value == filter.selectedValue,
              onTap: () => Navigator.of(context).pop(option.value),
            ),
        ],
      ),
    );

    if (selected == null) {
      return;
    }
    filter.onSelected(selected);
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s8,
            AppSpacing.s6,
            AppSpacing.s8,
            AppSpacing.s20,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? AppColors.selectedBg : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.r10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? AppColors.brandDark
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check,
                  size: AppSize.size18,
                  color: AppColors.brand,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isActive ? AppColors.selectedBg : AppColors.borderLight,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 168),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isActive
                ? Border.all(color: AppColors.brand.withValues(alpha: 0.35))
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: isActive ? AppColors.brandDark : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
