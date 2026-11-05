import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../i18n/strings.g.dart';

class SendCodeButton extends StatefulWidget {
  const SendCodeButton({
    super.key,
    this.onSendCode,
    this.enabled = true,
    this.countdownDuration = const Duration(minutes: 1),
  });

  final FutureOr<void> Function()? onSendCode;

  /// Whether the button is actionable (e.g. the email is valid).
  final bool enabled;
  final Duration countdownDuration;

  @override
  State<SendCodeButton> createState() => _SendCodeButtonState();
}

class _SendCodeButtonState extends State<SendCodeButton> {
  Timer? _timer;
  var _remaining = Duration.zero;
  var _isSending = false;

  bool get _isCountingDown => _remaining > Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSending || _isCountingDown) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await widget.onSendCode?.call();
      if (!mounted) {
        return;
      }
      _startCountdown();
    } catch (_) {
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.countdownDuration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextRemaining = _remaining - const Duration(seconds: 1);
      setState(() {
        _remaining = nextRemaining.isNegative ? Duration.zero : nextRemaining;
      });

      if (_remaining == Duration.zero) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.common;
    final palette = context.appPalette;
    final disabled = !widget.enabled || _isSending || _isCountingDown;
    final label = _isSending
        ? t.sendingCode
        : _isCountingDown
        ? _formatRemaining(_remaining)
        : t.sendCode;

    return TextButton(
      onPressed: disabled ? null : _sendCode,
      style: TextButton.styleFrom(
        backgroundColor: disabled ? palette.surfaceMuted : palette.surface,
        foregroundColor: disabled ? palette.muted : palette.primary,
        disabledForegroundColor: palette.muted,
        minimumSize: const Size(44, 38),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s14,
          vertical: AppSpacing.s8,
        ),
        side: BorderSide(color: disabled ? palette.line : palette.primary),
        shape: const StadiumBorder(),
        textStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontSize: 12),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  String _formatRemaining(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ Duration.secondsPerHour;
    final minutes = (totalSeconds % Duration.secondsPerHour) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
