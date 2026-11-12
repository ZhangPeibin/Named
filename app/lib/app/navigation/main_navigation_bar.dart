import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/strings.g.dart';

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const _destinations = [
    _Destination(
      path: '/',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: _Label.explore,
    ),
    _Destination(
      path: '/words',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: _Label.words,
    ),
    _Destination(
      path: '/challenges',
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag,
      label: _Label.challenge,
    ),
    _Destination(
      path: '/history',
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories,
      label: _Label.history,
    ),
    _Destination(
      path: '/me',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: _Label.me,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.t.navigation;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) {
          return;
        }
        context.go(_destinations[index].path);
      },
      destinations: [
        for (final destination in _destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: switch (destination.label) {
              _Label.explore => navigation.explore,
              _Label.words => navigation.words,
              _Label.challenge => navigation.challenge,
              _Label.history => navigation.history,
              _Label.me => navigation.me,
            },
          ),
      ],
    );
  }
}

class _Destination {
  const _Destination({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final _Label label;
}

enum _Label { explore, words, challenge, history, me }
