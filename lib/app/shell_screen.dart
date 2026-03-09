import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    _TabItem(path: '/builds', icon: Icons.build_outlined, activeIcon: Icons.build, label: 'Builds'),
    _TabItem(path: '/randomizer', icon: Icons.casino_outlined, activeIcon: Icons.casino, label: 'Randomizer'),
    _TabItem(path: '/maps', icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Maps'),
    _TabItem(path: '/group', icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'Group'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({required this.path, required this.icon, required this.activeIcon, required this.label});
}
