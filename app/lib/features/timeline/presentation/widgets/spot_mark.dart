import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

enum SpotMarkKind { daily, word, moment, trail }

class SpotMark extends StatelessWidget {
  const SpotMark({
    super.key,
    required this.kind,
    this.size = 38,
    this.completed = false,
  });

  final SpotMarkKind kind;
  final double size;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final background = switch (kind) {
      SpotMarkKind.daily => palette.warm,
      SpotMarkKind.word => palette.surfaceMuted,
      SpotMarkKind.moment => palette.warm,
      SpotMarkKind.trail => palette.surfaceMuted,
    };

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(size * 0.31),
              border: Border.all(color: palette.line.withValues(alpha: 0.7)),
            ),
            child: CustomPaint(
              painter: _SpotPainter(
                kind: kind,
                primary: palette.primary,
                accent: palette.accent,
                ink: palette.ink,
              ),
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
      child: CustomPaint(
        painter: _UserPainter(primary: palette.primary, accent: palette.accent),
      ),
    );
  }
}

class _UserPainter extends CustomPainter {
  const _UserPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final accentFill = Paint()..color = accent.withValues(alpha: 0.7);
    final head = Offset(size.width * 0.5, size.height * 0.38);
    canvas.drawCircle(head, size.width * 0.14, stroke);
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.25),
      size.width * 0.045,
      accentFill,
    );
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
    return oldDelegate.primary != primary || oldDelegate.accent != accent;
  }
}

class _SpotPainter extends CustomPainter {
  const _SpotPainter({
    required this.kind,
    required this.primary,
    required this.accent,
    required this.ink,
  });

  final SpotMarkKind kind;
  final Color primary;
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, size.width * 0.045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accentFill = Paint()..color = accent.withValues(alpha: 0.8);
    final softFill = Paint()..color = primary.withValues(alpha: 0.10);

    switch (kind) {
      case SpotMarkKind.daily:
        _paintDaily(canvas, size, stroke, accentFill, softFill);
      case SpotMarkKind.word:
        _paintWord(canvas, size, stroke, accentFill);
      case SpotMarkKind.moment:
        _paintMoment(canvas, size, stroke, accentFill, softFill);
      case SpotMarkKind.trail:
        _paintTrail(canvas, size, stroke, accentFill);
    }
  }

  void _paintDaily(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accentFill,
    Paint softFill,
  ) {
    final w = size.width;
    final h = size.height;
    final book = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.36, w * 0.56, h * 0.38),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(book, softFill);
    canvas.drawRRect(book, stroke);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.37),
      Offset(w * 0.5, h * 0.73),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.28, h * 0.48),
      Offset(w * 0.44, h * 0.48),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.56, h * 0.48),
      Offset(w * 0.72, h * 0.48),
      stroke,
    );
    canvas.drawCircle(Offset(w * 0.72, h * 0.25), w * 0.09, accentFill);
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + (i - 1.5) * 0.55;
      canvas.drawLine(
        Offset(w * 0.81, h * 0.25),
        Offset(
          w * 0.81 + math.cos(angle) * w * 0.08,
          h * 0.25 + math.sin(angle) * h * 0.08,
        ),
        stroke,
      );
    }
  }

  void _paintWord(Canvas canvas, Size size, Paint stroke, Paint accentFill) {
    final w = size.width;
    final h = size.height;
    final painter = TextPainter(
      text: TextSpan(
        text: 'Aa',
        style: TextStyle(
          color: primary,
          fontSize: w * 0.34,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lora',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(w * 0.23, h * 0.35));
    final stem = Path()
      ..moveTo(w * 0.72, h * 0.55)
      ..quadraticBezierTo(w * 0.69, h * 0.44, w * 0.74, h * 0.36);
    canvas.drawPath(stem, stroke);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.77, h * 0.35),
        width: w * 0.13,
        height: h * 0.09,
      ),
      accentFill,
    );
  }

  void _paintMoment(
    Canvas canvas,
    Size size,
    Paint stroke,
    Paint accentFill,
    Paint softFill,
  ) {
    final w = size.width;
    final h = size.height;
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.23, h * 0.23, w * 0.42, h * 0.46),
      Radius.circular(w * 0.07),
    );
    canvas.drawRRect(window, softFill);
    canvas.drawRRect(window, stroke);
    canvas.drawLine(
      Offset(w * 0.44, h * 0.24),
      Offset(w * 0.44, h * 0.68),
      stroke,
    );
    canvas.drawLine(
      Offset(w * 0.24, h * 0.46),
      Offset(w * 0.64, h * 0.46),
      stroke,
    );
    final plant = Path()
      ..moveTo(w * 0.62, h * 0.76)
      ..quadraticBezierTo(w * 0.68, h * 0.6, w * 0.78, h * 0.56);
    canvas.drawPath(plant, stroke);
    canvas.drawCircle(Offset(w * 0.78, h * 0.55), w * 0.075, accentFill);
    canvas.drawLine(
      Offset(w * 0.62, h * 0.77),
      Offset(w * 0.76, h * 0.77),
      stroke,
    );
  }

  void _paintTrail(Canvas canvas, Size size, Paint stroke, Paint accentFill) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.2, h * 0.7)
      ..cubicTo(w * 0.34, h * 0.42, w * 0.48, h * 0.72, w * 0.62, h * 0.45)
      ..cubicTo(w * 0.7, h * 0.3, w * 0.76, h * 0.32, w * 0.84, h * 0.24);
    final dashed = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawDashedPath(canvas, path, dashed);
    for (final point in [
      Offset(w * 0.2, h * 0.7),
      Offset(w * 0.54, h * 0.57),
      Offset(w * 0.84, h * 0.24),
    ]) {
      canvas.drawCircle(point, w * 0.065, accentFill);
      canvas.drawCircle(point, w * 0.065, stroke);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 3.2, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 6.4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpotPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.ink != ink;
  }
}
