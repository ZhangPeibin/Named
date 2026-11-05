import 'package:flutter/material.dart';

/// A shimmering placeholder box shown while data loads.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.circle = false,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  /// Pill/circle shape; ignores [borderRadius] and uses a fully rounded shape.
  final bool circle;

  static const _base = Color(0xFFECEEF1);
  static const _highlight = Color(0xBFFFFFFF);

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.circle
        ? BorderRadius.circular(widget.height)
        : (widget.borderRadius ?? BorderRadius.circular(6));

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppSkeleton._base)),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => FractionalTranslation(
                  translation: Offset(_controller.value * 2 - 1, 0),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00FFFFFF),
                          AppSkeleton._highlight,
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
