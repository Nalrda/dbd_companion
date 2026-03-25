import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    _TabItem(path: '/builds',     icon: Icons.build_outlined,  activeIcon: Icons.build,   label: 'Builds'),
    _TabItem(path: '/randomizer', icon: Icons.casino_outlined, activeIcon: Icons.casino,  label: 'Randomizer'),
    _TabItem(path: '/maps',       icon: Icons.map_outlined,    activeIcon: Icons.map,     label: 'Maps'),
    _TabItem(path: '/group',      icon: Icons.groups_outlined, activeIcon: Icons.groups,  label: 'Group'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    final idx = currentIndex < 0 ? 0 : currentIndex;

    return Scaffold(
      body: child,
      bottomNavigationBar: _DbdNavBar(
        selectedIndex: idx,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].path),
      ),
    );
  }
}

// ─── Custom DBD Navigation Bar ────────────────────────────────────────────────

class _DbdNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _DbdNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 60 + bottomPad,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.primaryGlow,
            blurRadius: 24,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Row(
          children: List.generate(
            tabs.length,
            (i) => _NavItem(
              tab: tabs[i],
              isActive: i == selectedIndex,
              onTap: () => onTap(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator bar at top
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 32 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                key: ValueKey(isActive),
                color: isActive ? AppTheme.primary : AppTheme.textDim,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.rajdhani(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textDim,
                letterSpacing: 0.6,
              ),
              child: Text(tab.label),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
