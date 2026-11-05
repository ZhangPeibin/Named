import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.centerBody = true,
    this.maxWidth = AppSpacing.pageMaxWidth,
    this.padding = const EdgeInsets.all(AppSpacing.pageHorizontalPadding),
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final bool centerBody;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: body,
      ),
    );

    return Scaffold(
      appBar: AppBar(leading: leading, title: Text(title)),
      body: centerBody ? Center(child: content) : content,
    );
  }
}
