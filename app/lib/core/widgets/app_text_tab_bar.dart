import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class AppTextTabBar extends StatelessWidget {
  const AppTextTabBar({
    super.key,
    required this.labels,
    this.tabWidth = AppSize.textTabWidth,
    this.indicatorWeight = AppSize.tabIndicatorWeight,
    this.labelColor = AppColors.textPrimary,
    this.unselectedLabelColor = AppColors.textMuted,
    this.dividerColor = AppColors.dividerLine,
  });

  final List<String> labels;
  final double tabWidth;
  final double indicatorWeight;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TabBar(
      tabs: [
        for (final label in labels)
          SizedBox(
            width: tabWidth,
            child: Tab(text: label),
          ),
      ],
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: EdgeInsets.zero,
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
      labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      indicatorColor: labelColor,
      indicatorWeight: indicatorWeight,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: dividerColor,
      dividerHeight: 1,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}
