import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DailyMark extends StatelessWidget {
  const DailyMark({super.key, this.size = 38, this.completed = false});

  final double size;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.warm,
              borderRadius: BorderRadius.circular(size * 0.31),
              border: Border.all(color: palette.line.withValues(alpha: 0.7)),
            ),
            child: CustomPaint(
              painter: _DailyPainter(primary: palette.primary),
              child: const SizedBox.expand(),
            ),
          ),
          if (completed)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.canvas, width: 1.5),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: palette.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MiloMark extends StatelessWidget {
  const MiloMark({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.line, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/companion.jpg',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: palette.surfaceMuted,
                child: Icon(
                  Icons.face_outlined,
                  size: size * 0.5,
                  color: palette.primary,
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
                border: Border.all(color: palette.canvas, width: 1.5),
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 8,
                color: palette.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserMark extends StatelessWidget {
  const UserMark({super.key, this.size = 34});

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
      child: CustomPaint(painter: _UserPainter(primary: palette.primary)),
    );
  }
}

class _UserPainter extends CustomPainter {
  const _UserPainter({required this.primary});

  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final head = Offset(size.width * 0.5, size.height * 0.38);
    canvas.drawCircle(head, size.width * 0.14, stroke);
    final shoulders = Path()
      ..moveTo(size.width * 0.27, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.56,
        size.width * 0.5,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.56,
        size.width * 0.73,
        size.height * 0.76,
      );
    canvas.drawPath(shoulders, stroke);
  }

  @override
  bool shouldRepaint(covariant _UserPainter oldDelegate) {
    return oldDelegate.primary != primary;
  }
}

class _DailyPainter extends CustomPainter {
  const _DailyPainter({required this.primary});

  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, w * 0.048)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(w * 0.5, h * 0.33)
      ..quadraticBezierTo(w * 0.36, h * 0.29, w * 0.24, h * 0.35)
      ..lineTo(w * 0.24, h * 0.68)
      ..quadraticBezierTo(w * 0.37, h * 0.63, w * 0.5, h * 0.7);
    final right = Path()
      ..moveTo(w * 0.5, h * 0.33)
      ..quadraticBezierTo(w * 0.64, h * 0.29, w * 0.76, h * 0.35)
      ..lineTo(w * 0.76, h * 0.68)
      ..quadraticBezierTo(w * 0.63, h * 0.63, w * 0.5, h * 0.7);
    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.34),
      Offset(w * 0.5, h * 0.7),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.31, h * 0.45),
      Offset(w * 0.42, h * 0.45),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.45),
      Offset(w * 0.69, h * 0.45),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyPainter oldDelegate) {
    return oldDelegate.primary != primary;
  }
}
