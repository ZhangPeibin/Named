import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.s16),
          Text(message, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
