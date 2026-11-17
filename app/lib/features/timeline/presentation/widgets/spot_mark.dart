import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ContentAccent {
  const ContentAccent({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class ContentAccents {
  const ContentAccents._();

  static ContentAccent daily(BuildContext context) {
    final palette = context.appPalette;
    return ContentAccent(
      background: palette.surfaceMuted,
      foreground: palette.primary,
    );
  }

  static ContentAccent user(BuildContext context) {
    final palette = context.appPalette;
    return ContentAccent(
      background: palette.surfaceMuted,
      foreground: palette.primary,
    );
  }

  static Color talk(BuildContext context) => context.appPalette.primary;

  static Color words(BuildContext context) => context.appPalette.muted;

  static Color talks(BuildContext context) => context.appPalette.muted;

  static Color reads(BuildContext context) => context.appPalette.muted;
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.line),
            ),
            child: Center(
              child: Icon(
                Icons.menu_book_rounded,
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
                  color: palette.primary,
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
                  Icons.person_rounded,
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
                color: palette.ink,
                shape: BoxShape.circle,
                border: Border.all(color: palette.canvas, width: 1.5),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
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
        border: Border.all(color: context.appPalette.line),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: accent.foreground,
      ),
    );
  }
}
