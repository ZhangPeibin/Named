import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_line_icon.dart';
import '../../../core/widgets/app_otp_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/send_code_button.dart';
import '../../../i18n/strings.g.dart';
import '../domain/initial_soul.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_providers.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  static const _pageCount = 2;

  final _nativeLanguageController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _pageController = PageController();

  int _page = 0;
  bool _languageDone = false;
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
    _pageController.dispose();
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

  void _goToPage(int index) {
    setState(() {
      _page = index;
      _error = null;
    });
    if (_pageController.hasClients) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _pageController.jumpToPage(index);
      } else {
        unawaited(
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    }
  }

  void _handlePageChanged(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _page = index;
      _error = null;
    });
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
    _skipInitialSoul = false;
    _languageDone = true;
    _goToPage(1);
  }

  void _useExistingAccount() {
    _skipInitialSoul = true;
    _languageDone = true;
    _goToPage(1);
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
    if (_isVerifying) {
      return;
    }
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
      _languageDone = false;
      setState(() => _error = context.t.auth.nativeLanguageRequired);
      _goToPage(0);
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
        _skipInitialSoul = false;
        _languageDone = false;
        setState(() => _error = context.t.auth.nativeLanguageRequired);
        _goToPage(0);
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

    return AppScaffold(
      title: '',
      showAppBar: false,
      centerBody: false,
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: SizedBox(
              height: AppSize.logoLockupHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    context.isAppDark
                        ? 'assets/branding/marks/lockup_dark.png'
                        : 'assets/branding/marks/lockup_light.png',
                    width: AppSize.logoLockupWidth,
                    height: AppSize.logoLockupHeight,
                    fit: BoxFit.contain,
                    semanticLabel: 'Named',
                  ),
                  if (_page > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        key: const Key('signIn.backToLanguage'),
                        tooltip: t.back,
                        onPressed: () => _goToPage(0),
                        icon: AppLineIcon(
                          AppLineGlyph.chevronLeft,
                          size: AppSize.size22,
                          color: palette.ink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          _StepIndicator(current: _page, count: _pageCount),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: _languageDone
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: _handlePageChanged,
              children: [_languagePage(context), _emailPage(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageFrame(
    BuildContext context, {
    required String title,
    required String intro,
    String? eyebrow,
    required List<Widget> children,
  }) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    const horizontal = AppSpacing.pageHorizontalPadding;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        horizontal,
        AppSpacing.s32,
        horizontal,
        AppSpacing.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow,
              style: AppTextStyles.eyebrow.copyWith(color: palette.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          Text(
            title,
            style: textTheme.displayMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            intro,
            style: textTheme.bodyLarge?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s16),
          ...children,
        ],
      ),
    );
  }

  Widget _languagePage(BuildContext context) {
    final t = context.t.auth;
    return _pageFrame(
      context,
      eyebrow: t.brandEyebrow,
      title: t.languageTitle,
      intro: t.nativeLanguageIntro,
      children: [
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
      ],
    );
  }

  Widget _emailPage(BuildContext context) {
    final t = context.t.auth;
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    return _pageFrame(
      context,
      title: t.emailTitle,
      intro: t.emailIntro,
      children: [
        AppTextField(
          key: const Key('signIn.email'),
          controller: _emailController,
          labelText: t.email,
          hintText: t.emailHint,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {
            _error = null;
            if (_codeSent) {
              _codeSent = false;
              _codeController.clear();
            }
          }),
        ),
        const SizedBox(height: AppSpacing.s12),
        SizedBox(
          width: double.infinity,
          child: SendCodeButton(
            onSendCode: _sendCode,
            enabled: _emailLooksValid && !_isSendingCode,
          ),
        ),
        if (_codeSent) ...[
          const SizedBox(height: AppSpacing.s16),
          Text(
            t.codeSentTo.replaceFirst('{email}', _emailController.text.trim()),
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(t.code, style: textTheme.labelLarge),
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
      ],
    );
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.s6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: index == current
                ? AppSize.stepBarActive
                : AppSize.stepBarIdle,
            height: AppSize.stepBarHeight,
            decoration: BoxDecoration(
              color: index <= current ? palette.primary : palette.line,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ],
      ],
    );
  }
}
