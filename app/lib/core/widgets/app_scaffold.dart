import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.centerBody = true,
    this.maxWidth = AppSpacing.pageMaxWidth,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontalPadding,
      AppSpacing.s8,
      AppSpacing.pageHorizontalPadding,
      AppSpacing.s32,
    ),
    this.bottomNavigationBar,
    this.showAppBar = true,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerBody;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Widget? bottomNavigationBar;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final content = Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: body,
      ),
    );

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: showAppBar
          ? AppBar(leading: leading, title: Text(title), actions: actions)
          : null,
      body: showAppBar
          ? (centerBody ? Center(child: content) : content)
          : SafeArea(child: centerBody ? Center(child: content) : content),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
