import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ContentAccent {
  const ContentAccent({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class ContentAccents {
  const ContentAccents._();

  static bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static ContentAccent daily(BuildContext context) {
    return _isDark(context)
        ? const ContentAccent(
            background: Color(0x269CC4B8),
            foreground: Color(0xFF9CC4B8),
          )
        : const ContentAccent(
            background: Color(0xFFE5F0EA),
            foreground: Color(0xFF4F7C74),
          );
  }

  static ContentAccent user(BuildContext context) {
    return _isDark(context)
        ? const ContentAccent(
            background: Color(0x26E0A8B0),
            foreground: Color(0xFFE0A8B0),
          )
        : const ContentAccent(
            background: Color(0xFFF5E7EA),
            foreground: Color(0xFFA85F6B),
          );
  }

  static Color talk(BuildContext context) {
    return _isDark(context) ? const Color(0xFF9BBEDC) : const Color(0xFF4F7C9E);
  }

  static Color words(BuildContext context) {
    return _isDark(context) ? const Color(0xFF9CC4B8) : const Color(0xFF4F7C74);
  }

  static Color talks(BuildContext context) {
    return _isDark(context) ? const Color(0xFF82C8FF) : const Color(0xFF3A86C8);
  }

  static Color reads(BuildContext context) {
    return _isDark(context) ? const Color(0xFF9ED8A8) : const Color(0xFF4F9B69);
  }
}

class DailyMark extends StatelessWidget {
  const DailyMark({super.key, this.size = 38, this.completed = false});

  final double size;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = ContentAccents.daily(context);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent.background,
              borderRadius: BorderRadius.circular(size * 0.3),
              border: Border.all(
                color: accent.foreground.withValues(alpha: 0.14),
              ),
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.book_solid,
                size: size * 0.52,
                color: accent.foreground,
              ),
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
                  color: accent.foreground,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.canvas, width: 1.5),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 10,
                  color: Colors.white,
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
                  CupertinoIcons.person_fill,
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
                color: ContentAccents.talk(context),
                shape: BoxShape.circle,
                border: Border.all(color: palette.canvas, width: 1.5),
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_2_fill,
                size: 9,
                color: Colors.white,
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
    final accent = ContentAccents.user(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.background,
        shape: BoxShape.circle,
        border: Border.all(color: accent.foreground.withValues(alpha: 0.14)),
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        size: size * 0.55,
        color: accent.foreground,
      ),
    );
  }
}
