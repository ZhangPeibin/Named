import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import 'companion_avatar.dart';

class CompanionGreeting extends StatelessWidget {
  const CompanionGreeting({
    super.key,
    required this.text,
    required this.onTap,
    required this.animation,
    this.reduceMotion = false,
  });

  final String text;
  final VoidCallback onTap;
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final bubble = _GreetingBubble(text: text);

    if (reduceMotion) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: GestureDetector(
          key: const Key('companion.greeting'),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CompanionAvatar(size: 32),
              const SizedBox(width: AppSpacing.s8),
              Flexible(child: bubble),
            ],
          ),
        ),
      );
    }

    final avatarAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    final bubbleAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.05, 0.78, curve: Curves.easeOutCubic),
    );
    final textAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    return GestureDetector(
      key: const Key('companion.greeting'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(avatarAnimation),
            child: FadeTransition(
              opacity: avatarAnimation,
              child: const CompanionAvatar(size: 32),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: bubbleAnimation,
                builder: (context, child) => Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: bubbleAnimation.value,
                  child: child,
                ),
                child: FadeTransition(opacity: textAnimation, child: bubble),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingBubble extends StatelessWidget {
  const _GreetingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: palette.line),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: palette.ink),
      ),
    );
  }
}
