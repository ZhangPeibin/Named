import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../providers/auth_notifier.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.auth;
    final auth = ref.watch(authNotifierProvider);
    final isBusy = auth.isLoading;

    return AppScaffold(
      title: t.signInTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.devSignInHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.s24),
          AppButton(
            key: const Key('signIn.devButton'),
            label: t.devSignIn,
            onPressed: isBusy
                ? null
                : () => ref.read(authNotifierProvider.notifier).devSignIn(),
          ),
        ],
      ),
    );
  }
}
