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
