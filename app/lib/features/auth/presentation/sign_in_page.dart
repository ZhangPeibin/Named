import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_otp_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/send_code_button.dart';
import '../../../i18n/strings.g.dart';
import '../domain/initial_soul.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_providers.dart';

enum _SignInStep { nativeLanguage, email }

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _nativeLanguageController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  _SignInStep _step = _SignInStep.nativeLanguage;
  bool _skipInitialSoul = false;
  bool _codeSent = false;
  bool _isSendingCode = false;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_restorePendingSoul));
  }

  @override
  void dispose() {
    _nativeLanguageController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _restorePendingSoul() async {
    final language = await ref
        .read(pendingSoulRepositoryProvider)
        .readNativeLanguage();
    if (!mounted || language == null || language.isEmpty) {
      return;
    }
    _nativeLanguageController.text = language;
  }

  bool get _emailLooksValid {
    final email = _emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  Future<void> _continueFromLanguage() async {
    final language = _nativeLanguageController.text.trim();
    if (language.isEmpty) {
      setState(() => _error = context.t.auth.nativeLanguageRequired);
      return;
    }
    await ref.read(pendingSoulRepositoryProvider).saveNativeLanguage(language);
    if (!mounted) {
      return;
    }
    setState(() {
      _error = null;
      _skipInitialSoul = false;
      _step = _SignInStep.email;
    });
  }

  void _useExistingAccount() {
    setState(() {
      _error = null;
      _skipInitialSoul = true;
      _step = _SignInStep.email;
    });
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!_emailLooksValid) {
      setState(() => _error = context.t.auth.invalidEmail);
      throw StateError('Invalid email');
    }

    setState(() {
      _error = null;
      _isSendingCode = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).requestCode(email);
      if (!mounted) {
        return;
      }
      setState(() {
        _codeSent = true;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _verify() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final language = _nativeLanguageController.text.trim();

    if (!_emailLooksValid) {
      setState(() => _error = context.t.auth.invalidEmail);
      return;
    }
    if (code.length != 6) {
      setState(() => _error = context.t.auth.invalidCode);
      return;
    }
    if (!_skipInitialSoul && language.isEmpty) {
      setState(() {
        _step = _SignInStep.nativeLanguage;
        _error = context.t.auth.nativeLanguageRequired;
      });
      return;
    }

    setState(() {
      _error = null;
      _isVerifying = true;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .verify(
            email: email,
            code: code,
            initialSoul: _skipInitialSoul
                ? null
                : InitialSoul(nativeLanguage: language),
          );
      // The router redirects to home when auth state becomes signedIn.
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.code == 'native_language_required') {
        setState(() {
          _skipInitialSoul = false;
          _step = _SignInStep.nativeLanguage;
          _error = context.t.auth.nativeLanguageRequired;
        });
      } else {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.auth;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final isLanguageStep = _step == _SignInStep.nativeLanguage;

    return AppScaffold(
      title: '',
      showAppBar: false,
      centerBody: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s8,
        AppSpacing.pageHorizontalPadding,
        AppSpacing.s32,
      ),
      body: ListView(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Named', style: textTheme.displayMedium),
              const SizedBox(width: AppSpacing.s6),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s10),
                child: Icon(
                  Icons.eco_outlined,
                  color: palette.primary,
                  size: AppSize.size18,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  t.brandEyebrow,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s32),
          _StepProgress(current: isLanguageStep ? 1 : 2),
          const SizedBox(height: AppSpacing.s24),
          Text(
            isLanguageStep ? t.languageTitle : t.emailTitle,
            style: textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.s10),
          Text(
            isLanguageStep ? t.nativeLanguageIntro : t.emailIntro,
            style: textTheme.bodyLarge?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: isLanguageStep
                  ? _languageStep(context)
                  : _emailStep(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _languageStep(BuildContext context) {
    final t = context.t.auth;
    return [
      AppTextField(
        key: const Key('signIn.nativeLanguage'),
        controller: _nativeLanguageController,
        labelText: t.nativeLanguage,
        hintText: t.nativeLanguageHint,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() => _error = null),
      ),
      const SizedBox(height: AppSpacing.s24),
      if (_error != null) _ErrorText(_error!),
      AppButton(
        key: const Key('signIn.continue'),
        label: t.continueLabel,
        onPressed: _continueFromLanguage,
      ),
      const SizedBox(height: AppSpacing.s8),
      AppButton(
        key: const Key('signIn.existingAccount'),
        label: t.alreadyHaveAccount,
        variant: AppButtonVariant.text,
        onPressed: _useExistingAccount,
      ),
    ];
  }

  List<Widget> _emailStep(BuildContext context) {
    final t = context.t.auth;
    return [
      AppTextField(
        key: const Key('signIn.email'),
        controller: _emailController,
        labelText: t.email,
        hintText: t.emailHint,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() => _error = null),
      ),
      const SizedBox(height: AppSpacing.s12),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SendCodeButton(
            onSendCode: _sendCode,
            enabled: _emailLooksValid && !_isSendingCode,
          ),
        ],
      ),
      if (_codeSent) ...[
        const SizedBox(height: AppSpacing.s24),
        Text(t.code, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.s12),
        AppOtpField(
          key: const Key('signIn.code'),
          controller: _codeController,
          onChanged: (_) => setState(() => _error = null),
          onCompleted: (_) => _verify(),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.s16),
        _ErrorText(_error!),
      ],
      const SizedBox(height: AppSpacing.s24),
      if (_codeSent)
        AppButton(
          key: const Key('signIn.verify'),
          label: t.verify,
          isLoading: _isVerifying,
          onPressed: _isVerifying ? null : _verify,
        ),
      const SizedBox(height: AppSpacing.s8),
      AppButton(
        key: const Key('signIn.backToLanguage'),
        label: t.back,
        variant: AppButtonVariant.text,
        onPressed: () => setState(() {
          _step = _SignInStep.nativeLanguage;
          _error = null;
        }),
      ),
    ];
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: palette.error),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      children: [
        for (var step = 1; step <= 2; step++) ...[
          if (step > 1) const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: step <= current ? palette.primary : palette.line,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
