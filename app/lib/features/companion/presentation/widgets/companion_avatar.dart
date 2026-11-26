import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.warm,
        shape: BoxShape.circle,
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: Image.asset(
          'assets/images/companion_avatar.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.pets, size: size * 0.5, color: palette.primary),
        ),
      ),
    );
  }
}

class BreathingCompanionAvatar extends StatefulWidget {
  const BreathingCompanionAvatar({super.key, this.size = 28});

  final double size;

  @override
  State<BreathingCompanionAvatar> createState() =>
      _BreathingCompanionAvatarState();
}

class _BreathingCompanionAvatarState extends State<BreathingCompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return CompanionAvatar(size: widget.size);
    }
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1,
        end: 1.03,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: CompanionAvatar(size: widget.size),
    );
  }
}
