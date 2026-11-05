import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.location});

  final String? location;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final requestedLocation = location;
    final t = context.t.notFound;

    return AppScaffold(
      title: t.title,
      leading: BackButton(onPressed: () => _goBack(context)),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore, size: 72, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.s24),
          Text(
            t.title,
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            requestedLocation == null
                ? t.description
                : t.noRoute(location: requestedLocation),
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    unawaited(SystemNavigator.pop());
  }
}
