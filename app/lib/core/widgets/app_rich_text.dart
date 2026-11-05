import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A text segment with optional style and tap handler.
class AppTextSegment {
  const AppTextSegment({
    required this.text,
    this.style,
    this.color,
    this.onTap,
  });

  final String text;
  final TextStyle? style;
  final Color? color;
  final VoidCallback? onTap;
}

/// Rich text built from [AppTextSegment]s for mixed styles and taps.
class AppRichText extends StatelessWidget {
  const AppRichText({
    super.key,
    required this.segments,
    this.baseStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final List<AppTextSegment> segments;
  final TextStyle? baseStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = baseStyle ?? DefaultTextStyle.of(context).style;

    return Text.rich(
      TextSpan(
        style: defaultStyle,
        children: [
          for (final segment in segments)
            TextSpan(
              text: segment.text,
              style: (segment.style ?? defaultStyle).copyWith(
                color: segment.color,
              ),
              recognizer: segment.onTap == null
                  ? null
                  : (TapGestureRecognizer()..onTap = segment.onTap),
            ),
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
