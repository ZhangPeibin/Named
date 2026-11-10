import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../i18n/strings.g.dart';

class TalkAvatar extends StatelessWidget {
  const TalkAvatar({
    super.key,
    required this.isUser,
    this.size = 36,
    this.avatarUrl,
  });

  final bool isUser;
  final double size;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final t = context.t.talk;
    final url = avatarUrl?.trim();

    return Semantics(
      image: true,
      label: isUser ? t.youAvatar : t.miloAvatar,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isUser ? palette.warm : palette.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: url == null || url.isEmpty
            ? _FallbackAvatar(isUser: isUser, size: size)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _FallbackAvatar(isUser: isUser, size: size),
              ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.isUser, required this.size});

  final bool isUser;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    if (isUser) {
      return Icon(
        Icons.person_outline,
        size: size * 0.52,
        color: palette.primary,
      );
    }

    return Image.asset(
      'assets/images/companion.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.face_outlined, size: size * 0.52, color: palette.primary),
    );
  }
}
