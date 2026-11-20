import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';

/// A standardised modal bottom sheet with a drag handle, rounded top corners,
/// and consistent padding.
///
/// Use [showAppBottomSheet] to display it:
/// ```dart
/// showAppBottomSheet(
///   context: context,
///   builder: (context) => const Text('Hello'),
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.s24,
      0,
      AppSpacing.s24,
      0,
    ),
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = this.title;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDragHandle) ...[
          const SizedBox(height: AppSpacing.s12),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
        if (title != null) ...[
          const SizedBox(height: AppSpacing.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
            child: Text(title, style: textTheme.titleMedium),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        Padding(padding: padding, child: child),
      ],
    );
  }
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) {
  // Keep the sheet inside the same provider scope as the caller so widgets
  // that read providers (e.g. the audio control) work when the modal overlay
  // is not itself under a ProviderScope.
  ProviderContainer? container;
  try {
    container = ProviderScope.containerOf(context, listen: false);
  } catch (_) {
    container = null;
  }

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r16)),
    ),
    builder: (sheetContext) {
      final content = Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSpacing.s20),
          child: AppBottomSheet(child: builder(sheetContext)),
        ),
      );
      final scopedContainer = container;
      if (scopedContainer == null) {
        return content;
      }
      return UncontrolledProviderScope(
        container: scopedContainer,
        child: content,
      );
    },
  );
}
