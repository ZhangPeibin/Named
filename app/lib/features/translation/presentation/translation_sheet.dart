import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../i18n/strings.g.dart';
import '../domain/translation.dart';
import '../providers/translation_providers.dart';

Future<void> showTranslationSheet(BuildContext context, String text) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.appPalette.canvas,
    builder: (context) => UncontrolledProviderScope(
      container: container,
      child: TranslationSheet(text: text),
    ),
  );
}

class TranslationSheet extends ConsumerWidget {
  const TranslationSheet({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.talk;
    final async = ref.watch(translationProvider(text));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s16,
          AppSpacing.s20,
          AppSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.translationTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.s16),
            _OriginalText(text: text),
            const SizedBox(height: AppSpacing.s12),
            async.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => AppErrorView(
                title: t.translationFailed,
                message: error is ApiException
                    ? error.message
                    : context.t.common.somethingWentWrong,
                onRetry: () => ref.invalidate(translationProvider(text)),
              ),
              data: (result) => _TranslationResultView(result: result),
            ),
          ],
        ),
      ),
    );
  }
}

class _OriginalText extends StatelessWidget {
  const _OriginalText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: context.appPalette.muted),
    );
  }
}

class _TranslationResultView extends StatelessWidget {
  const _TranslationResultView({required this.result});

  final TranslationResult result;

  @override
  Widget build(BuildContext context) {
    final t = context.t.talk;
    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: palette.warm,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Text(
            result.translatedText,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        AppButton(
          key: const Key('translation.copy'),
          label: t.copyTranslation,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: result.translatedText));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t.copied)));
            }
          },
        ),
      ],
    );
  }
}
