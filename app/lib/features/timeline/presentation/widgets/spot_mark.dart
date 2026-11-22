import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/content_accent.dart';
import '../../../../core/widgets/app_line_icon.dart';

/// Read card mark: an ink line book. Dummied to `muted` once completed.
class DailyMark extends StatelessWidget {
  const DailyMark({super.key, this.size = 24, this.completed = false});

  final double size;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox.square(
      dimension: size,
      child: AppLineIcon(
        AppLineGlyph.book,
        size: size,
        color: completed ? palette.muted : ContentAccents.reads(context),
      ),
    );
  }
}

/// Ask card mark: an ink line speech bubble.
class AskMark extends StatelessWidget {
  const AskMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: AppLineIcon(
        AppLineGlyph.chat,
        size: size,
        color: ContentAccents.ask(context),
      ),
    );
  }
}

/// Talk card mark: the companion photo, borderless.
class MiloMark extends StatelessWidget {
  const MiloMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Image.asset(
          'assets/images/companion.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: palette.surfaceMuted,
            child: Center(
              child: AppLineIcon(
                AppLineGlyph.person,
                size: size * 0.7,
                color: palette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "me" mark: an ink line person.
class UserMark extends StatelessWidget {
  const UserMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: AppLineIcon(
        AppLineGlyph.person,
        size: size,
        color: ContentAccents.soul(context),
      ),
    );
  }
}
