import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Brand line-icon glyphs. Drawn on a 24×24 grid with a 1.6 stroke, round caps
/// and round joins, matching the design prototype's icon language.
enum AppLineGlyph {
  // content
  book,
  chat,
  person,
  headphones,
  // navigation / UI
  chevronRight,
  chevronLeft,
  chevronDown,
  chevronUp,
  arrowUp,
  arrowLeft,
  arrowRight,
  close,
  plus,
  check,
  checkCircle,
  circleOutline,
  // media
  play,
  pause,
  stop,
  replay,
  forward,
  volume,
  mic,
  // semantic
  translate,
  leaf,
  flag,
  error,
  refresh,
  settings,
  palette,
  bell,
  sun,
  moon,
  logout,
  inbox,
  trash,
  bookmark,
  sparkle,
  image,
  thumbUp,
  thumbDown,
  compass,
}

class AppLineIcon extends StatelessWidget {
  const AppLineIcon(
    this.glyph, {
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 1.6,
  });

  final AppLineGlyph glyph;
  final double? size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final resolvedColor = color ?? theme.color ?? context.appPalette.ink;
    final resolvedSize = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: resolvedSize,
      child: CustomPaint(
        painter: _AppLineIconPainter(glyph, resolvedColor, strokeWidth),
      ),
    );
  }
}

class _AppLineIconPainter extends CustomPainter {
  const _AppLineIconPainter(this.glyph, this.color, this.strokeWidth);

  final AppLineGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_pathFor(glyph), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppLineIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

Path _roundRect(double l, double t, double r, double b, double rad) {
  return Path()
    ..moveTo(l + rad, t)
    ..lineTo(r - rad, t)
    ..arcToPoint(
      Offset(r, t + rad),
      radius: Radius.circular(rad),
      clockwise: true,
    )
    ..lineTo(r, b - rad)
    ..arcToPoint(
      Offset(r - rad, b),
      radius: Radius.circular(rad),
      clockwise: true,
    )
    ..lineTo(l + rad, b)
    ..arcToPoint(
      Offset(l, b - rad),
      radius: Radius.circular(rad),
      clockwise: true,
    )
    ..lineTo(l, t + rad)
    ..arcToPoint(
      Offset(l + rad, t),
      radius: Radius.circular(rad),
      clockwise: true,
    )
    ..close();
}

Path _cascadeCircularArrow({
  required double start,
  required double sweep,
  double radius = 7.4,
  bool arrowAtEnd = true,
}) {
  const center = Offset(12, 12);
  final p = Path()
    ..addArc(Rect.fromCircle(center: center, radius: radius), start, sweep);
  final angle = arrowAtEnd ? start + sweep : start;
  final pt = Offset(
    center.dx + radius * math.cos(angle),
    center.dy + radius * math.sin(angle),
  );
  final dirSign = sweep >= 0 ? 1.0 : -1.0;
  final dir = Offset(-math.sin(angle) * dirSign, math.cos(angle) * dirSign);
  final nrm = Offset(-dir.dy, dir.dx);
  const len = 3.1;
  final barb1 = pt - dir * len + nrm * len;
  final barb2 = pt - dir * len - nrm * len;
  p
    ..moveTo(barb1.dx, barb1.dy)
    ..lineTo(pt.dx, pt.dy)
    ..lineTo(barb2.dx, barb2.dy);
  return p;
}

Path _pathFor(AppLineGlyph glyph) {
  switch (glyph) {
    case AppLineGlyph.book:
      return Path()
        ..moveTo(12, 6.5)
        ..quadraticBezierTo(8.5, 4.5, 3.5, 4.5)
        ..lineTo(3.5, 18.5)
        ..quadraticBezierTo(8.5, 18.5, 12, 20.5)
        ..quadraticBezierTo(15.5, 18.5, 20.5, 18.5)
        ..lineTo(20.5, 4.5)
        ..quadraticBezierTo(15.5, 4.5, 12, 6.5)
        ..close()
        ..moveTo(12, 6.5)
        ..lineTo(12, 20.5);
    case AppLineGlyph.chat:
      return Path()
        ..moveTo(20, 11.5)
        ..cubicTo(20, 6.6, 16.5, 3.6, 12, 3.6)
        ..cubicTo(7.5, 3.6, 4, 6.6, 4, 11.5)
        ..cubicTo(4, 14.6, 5.7, 16.9, 8.2, 18.2)
        ..lineTo(7.2, 21.4)
        ..lineTo(12.4, 18.6)
        ..cubicTo(16.7, 18.4, 20, 15.6, 20, 11.5)
        ..close();
    case AppLineGlyph.person:
      return Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 8), radius: 4))
        ..moveTo(4.5, 21)
        ..quadraticBezierTo(4.5, 14.5, 12, 14.5)
        ..quadraticBezierTo(19.5, 14.5, 19.5, 21);
    case AppLineGlyph.headphones:
      return Path()
        ..moveTo(4.5, 15.5)
        ..cubicTo(4.5, 9, 7.8, 4.5, 12, 4.5)
        ..cubicTo(16.2, 4.5, 19.5, 9, 19.5, 15.5)
        ..moveTo(5.5, 14.5)
        ..lineTo(5.5, 19)
        ..moveTo(18.5, 14.5)
        ..lineTo(18.5, 19);
    case AppLineGlyph.chevronRight:
      return Path()
        ..moveTo(9, 6)
        ..lineTo(15, 12)
        ..lineTo(9, 18);
    case AppLineGlyph.chevronLeft:
      return Path()
        ..moveTo(15, 6)
        ..lineTo(9, 12)
        ..lineTo(15, 18);
    case AppLineGlyph.chevronDown:
      return Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9);
    case AppLineGlyph.chevronUp:
      return Path()
        ..moveTo(6, 15)
        ..lineTo(12, 9)
        ..lineTo(18, 15);
    case AppLineGlyph.arrowUp:
      return Path()
        ..moveTo(12, 20)
        ..lineTo(12, 5)
        ..moveTo(6, 11)
        ..lineTo(12, 5)
        ..lineTo(18, 11);
    case AppLineGlyph.arrowLeft:
      return Path()
        ..moveTo(19, 12)
        ..lineTo(5, 12)
        ..moveTo(11, 6)
        ..lineTo(5, 12)
        ..lineTo(11, 18);
    case AppLineGlyph.arrowRight:
      return Path()
        ..moveTo(5, 12)
        ..lineTo(19, 12)
        ..moveTo(13, 6)
        ..lineTo(19, 12)
        ..lineTo(13, 18);
    case AppLineGlyph.close:
      return Path()
        ..moveTo(6, 6)
        ..lineTo(18, 18)
        ..moveTo(18, 6)
        ..lineTo(6, 18);
    case AppLineGlyph.plus:
      return Path()
        ..moveTo(12, 5)
        ..lineTo(12, 19)
        ..moveTo(5, 12)
        ..lineTo(19, 12);
    case AppLineGlyph.check:
      return Path()
        ..moveTo(5, 12.5)
        ..lineTo(10, 17.5)
        ..lineTo(19, 7);
    case AppLineGlyph.checkCircle:
      return Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9))
        ..moveTo(8.2, 12.3)
        ..lineTo(10.9, 15)
        ..lineTo(15.8, 9.2);
    case AppLineGlyph.circleOutline:
      return Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9));
    case AppLineGlyph.play:
      return Path()
        ..moveTo(8, 5)
        ..lineTo(19, 12)
        ..lineTo(8, 19)
        ..close();
    case AppLineGlyph.pause:
      return Path()
        ..moveTo(9, 5)
        ..lineTo(9, 19)
        ..moveTo(15, 5)
        ..lineTo(15, 19);
    case AppLineGlyph.stop:
      return _roundRect(6.5, 6.5, 17.5, 17.5, 2.5);
    case AppLineGlyph.replay:
      return _cascadeCircularArrow(start: 0.7, sweep: -5.0);
    case AppLineGlyph.forward:
      return _cascadeCircularArrow(start: -0.7, sweep: 5.0);
    case AppLineGlyph.volume:
      return Path()
        ..moveTo(4, 9)
        ..lineTo(7.5, 9)
        ..lineTo(11, 5.5)
        ..lineTo(11, 18.5)
        ..lineTo(7.5, 15)
        ..lineTo(4, 15)
        ..close()
        ..moveTo(14.5, 9)
        ..cubicTo(15.9, 10, 15.9, 14, 14.5, 15)
        ..moveTo(17, 6.5)
        ..cubicTo(19.6, 8.5, 19.6, 15.5, 17, 17.5);
    case AppLineGlyph.mic:
      return Path()
        ..addPath(_roundRect(9, 3, 15, 14, 3), Offset.zero)
        ..moveTo(6, 11)
        ..lineTo(6, 12)
        ..cubicTo(6, 15.3, 8.7, 18, 12, 18)
        ..cubicTo(15.3, 18, 18, 15.3, 18, 12)
        ..lineTo(18, 11)
        ..moveTo(12, 18)
        ..lineTo(12, 21)
        ..moveTo(9, 21)
        ..lineTo(15, 21);
    case AppLineGlyph.translate:
      return Path()
        ..moveTo(7, 18)
        ..lineTo(12, 6)
        ..lineTo(17, 18)
        ..moveTo(9.2, 14)
        ..lineTo(14.8, 14);
    case AppLineGlyph.leaf:
      return Path()
        ..moveTo(5, 19)
        ..cubicTo(0, 7, 11, 2, 21, 3)
        ..cubicTo(22, 13, 17, 23, 5, 19)
        ..close()
        ..moveTo(5, 19)
        ..lineTo(17, 7);
    case AppLineGlyph.flag:
      return Path()
        ..moveTo(6, 21)
        ..lineTo(6, 4)
        ..cubicTo(10, 2, 13, 6, 18, 4)
        ..lineTo(18, 13)
        ..cubicTo(13, 15, 10, 11, 6, 13);
    case AppLineGlyph.error:
      return Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9))
        ..moveTo(12, 7)
        ..lineTo(12, 13)
        ..moveTo(12, 16.4)
        ..lineTo(12, 16.5);
    case AppLineGlyph.refresh:
      return _cascadeCircularArrow(start: -0.65, sweep: 4.9, arrowAtEnd: false);
    case AppLineGlyph.settings:
      return Path()
        ..moveTo(4, 8)
        ..lineTo(20, 8)
        ..moveTo(4, 16)
        ..lineTo(20, 16)
        ..addOval(Rect.fromCircle(center: const Offset(9, 8), radius: 2.2))
        ..addOval(Rect.fromCircle(center: const Offset(15, 16), radius: 2.2));
    case AppLineGlyph.palette:
      return Path()
        ..moveTo(12, 3)
        ..cubicTo(12, 3, 6, 10.2, 6, 14.2)
        ..cubicTo(6, 17.5, 8.7, 20, 12, 20)
        ..cubicTo(15.3, 20, 18, 17.5, 18, 14.2)
        ..cubicTo(18, 10.2, 12, 3, 12, 3)
        ..close();
    case AppLineGlyph.bell:
      return Path()
        ..moveTo(6, 16)
        ..lineTo(6, 11)
        ..cubicTo(6, 7.7, 8.7, 5, 12, 5)
        ..cubicTo(15.3, 5, 18, 7.7, 18, 11)
        ..lineTo(18, 16)
        ..lineTo(19.5, 18)
        ..lineTo(4.5, 18)
        ..close()
        ..moveTo(10, 20)
        ..cubicTo(10.4, 21.3, 13.6, 21.3, 14, 20);
    case AppLineGlyph.sun:
      final p = Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 4));
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        p
          ..moveTo(12 + 6.6 * math.cos(a), 12 + 6.6 * math.sin(a))
          ..lineTo(12 + 8.6 * math.cos(a), 12 + 8.6 * math.sin(a));
      }
      return p;
    case AppLineGlyph.moon:
      return Path()
        ..moveTo(16, 4)
        ..arcToPoint(
          const Offset(16, 20),
          radius: const Radius.circular(9),
          clockwise: false,
          largeArc: true,
        )
        ..arcToPoint(
          const Offset(16, 4),
          radius: const Radius.circular(7.2),
          clockwise: true,
          largeArc: false,
        )
        ..close();
    case AppLineGlyph.logout:
      return Path()
        ..moveTo(13, 4)
        ..lineTo(6, 4)
        ..lineTo(6, 20)
        ..lineTo(13, 20)
        ..moveTo(10, 12)
        ..lineTo(20, 12)
        ..moveTo(16, 8)
        ..lineTo(20, 12)
        ..lineTo(16, 16);
    case AppLineGlyph.inbox:
      return Path()
        ..moveTo(4, 13)
        ..lineTo(7, 5)
        ..lineTo(17, 5)
        ..lineTo(20, 13)
        ..lineTo(20, 19)
        ..lineTo(4, 19)
        ..close()
        ..moveTo(4, 13)
        ..lineTo(9, 13)
        ..lineTo(10.4, 15.2)
        ..lineTo(13.6, 15.2)
        ..lineTo(15, 13)
        ..lineTo(20, 13);
    case AppLineGlyph.trash:
      return Path()
        ..moveTo(5, 7)
        ..lineTo(19, 7)
        ..moveTo(9, 7)
        ..lineTo(9, 4.5)
        ..lineTo(15, 4.5)
        ..lineTo(15, 7)
        ..moveTo(6.7, 7)
        ..lineTo(7.6, 20)
        ..lineTo(16.4, 20)
        ..lineTo(17.3, 7)
        ..moveTo(10, 10.5)
        ..lineTo(10, 16.5)
        ..moveTo(14, 10.5)
        ..lineTo(14, 16.5);
    case AppLineGlyph.bookmark:
      return Path()
        ..moveTo(7, 4)
        ..lineTo(17, 4)
        ..lineTo(17, 20)
        ..lineTo(12, 16)
        ..lineTo(7, 20)
        ..close();
    case AppLineGlyph.sparkle:
      return Path()
        ..moveTo(12, 3)
        ..lineTo(15, 9)
        ..lineTo(21, 12)
        ..lineTo(15, 15)
        ..lineTo(12, 21)
        ..lineTo(9, 15)
        ..lineTo(3, 12)
        ..lineTo(9, 9)
        ..close();
    case AppLineGlyph.image:
      final p = _roundRect(3.5, 4.5, 20.5, 19.5, 3)
        ..addOval(Rect.fromCircle(center: const Offset(8.5, 9), radius: 1.4))
        ..moveTo(4.5, 17)
        ..lineTo(9, 12.5)
        ..lineTo(12.8, 16.3)
        ..lineTo(15.6, 13.5)
        ..lineTo(19.5, 17.4);
      return p;
    case AppLineGlyph.thumbUp:
      return Path()
        ..addPath(_roundRect(4, 10, 7.5, 20, 1.6), Offset.zero)
        ..moveTo(7.5, 20)
        ..lineTo(17.5, 20)
        ..cubicTo(18.4, 20, 19, 19.4, 19.1, 18.6)
        ..lineTo(20.2, 13)
        ..cubicTo(20.4, 12.1, 19.8, 11.4, 18.9, 11.4)
        ..lineTo(15, 11.4)
        ..lineTo(15.7, 7.4)
        ..cubicTo(15.9, 6.3, 15.3, 5.2, 14.2, 4.9)
        ..cubicTo(13.4, 4.7, 12.8, 5.1, 12.4, 5.7)
        ..lineTo(7.5, 11)
        ..lineTo(7.5, 20)
        ..close();
    case AppLineGlyph.thumbDown:
      final m = Matrix4.identity()
        ..translateByDouble(0.0, 24.0, 0.0, 1.0)
        ..scaleByDouble(1.0, -1.0, 1.0, 1.0);
      return _pathFor(AppLineGlyph.thumbUp).transform(m.storage);
    case AppLineGlyph.compass:
      return Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 9))
        ..moveTo(15.5, 8.5)
        ..lineTo(13, 13)
        ..lineTo(8.5, 15.5)
        ..lineTo(11, 11)
        ..close();
  }
}
