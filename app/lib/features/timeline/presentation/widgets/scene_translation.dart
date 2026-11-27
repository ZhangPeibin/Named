import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_line_icon.dart';
import '../../../../i18n/strings.g.dart';
import '../../../sentence/providers/sentence_providers.dart';

class SceneTranslation extends ConsumerStatefulWidget {
  const SceneTranslation({super.key, required this.text, this.minWords = 5});

  final String text;
  final int minWords;

  @override
  ConsumerState<SceneTranslation> createState() => _SceneTranslationState();
}

class _SceneTranslationState extends ConsumerState<SceneTranslation> {
  bool _expanded = false;

  bool get _isLong {
    final words = widget.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    return words >= widget.minWords;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLong) {
      return const SizedBox.shrink();
    }

    final palette = context.appPalette;
    final t = context.t.timeline;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            key: const Key('timeline.scene.translate'),
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              foregroundColor: palette.muted,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              minimumSize: const Size(0, AppSize.touchTarget),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            icon: const AppLineIcon(
              AppLineGlyph.translate,
              size: AppSize.size16,
            ),
            label: Text(_expanded ? t.hideTranslation : t.showTranslation),
          ),
          if (_expanded) _buildTranslation(context, palette),
        ],
      ),
    );
  }

  Widget _buildTranslation(BuildContext context, AppPalette palette) {
    final t = context.t.timeline;
    final text = widget.text.trim();
    final detail = ref.watch(sentenceDetailProvider(text));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        0,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      child: detail.when(
        loading: () => Row(
          children: [
            SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.muted,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(
              t.translating,
              style: AppTextStyles.bodySmall.copyWith(color: palette.muted),
            ),
          ],
        ),
        error: (error, stack) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                t.translationFailed,
                style: AppTextStyles.bodySmall.copyWith(color: palette.muted),
              ),
            ),
            TextButton(
              key: const Key('timeline.scene.translate.retry'),
              onPressed: () => ref.invalidate(sentenceDetailProvider(text)),
              child: Text(context.t.common.retry),
            ),
          ],
        ),
        data: (detail) {
          final translation = detail.translationNative.trim().isNotEmpty
              ? detail.translationNative
              : detail.explanationNative;
          return Text(
            translation,
            key: const Key('timeline.scene.translation'),
            style: AppTextStyles.body.copyWith(color: palette.muted),
          );
        },
      ),
    );
  }
}
