import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    _TabItem(
      path: '/builds',
      label: 'BUILDS',
      icon: Icons.construction_outlined,
      activeIcon: Icons.construction,
    ),
    _TabItem(
      path: '/randomizer',
      label: 'RANDOM',
      icon: Icons.casino_outlined,
      activeIcon: Icons.casino,
    ),
    _TabItem(
      path: '/killers',
      label: 'KILLERS',
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department,
    ),
    _TabItem(
      path: '/matches',
      label: 'MATCHES',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
    ),
    _TabItem(
      path: '/maps',
      label: 'MAPS',
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
    ),
    _TabItem(
      path: '/group',
      label: 'GROUP',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    final idx = currentIndex < 0 ? 0 : currentIndex;
    final isWide = MediaQuery.of(context).size.width >= 600;
    final user = ref.watch(authNotifierProvider).user;

    void signOut() => ref.read(authNotifierProvider).signOut();

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _DbdNavRail(
              selectedIndex: idx,
              tabs: _tabs,
              onTap: (i) => context.go(_tabs[i].path),
              user: user,
              onSignOut: signOut,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppTheme.border),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _DbdNavBar(
        selectedIndex: idx,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].path),
        onSignOut: signOut,
      ),
    );
  }
}

// ─── Side Navigation Rail (wide screens) ─────────────────────────────────────

class _DbdNavRail extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;
  final dynamic user;
  final VoidCallback onSignOut;

  const _DbdNavRail({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
    required this.user,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: 80,
      color: AppTheme.surface,
      child: Column(
        children: [
          SizedBox(height: topPad + 16),
          // DBD Logo mark
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryDim.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'D',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 8),
          ...List.generate(
            tabs.length,
            (i) => _RailItem(
              tab: tabs[i],
              isActive: i == selectedIndex,
              onTap: () => onTap(i),
            ),
          ),
          const Spacer(),
          const Divider(color: AppTheme.border, height: 1),
          _SignOutButton(user: user, onSignOut: onSignOut),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _RailItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primary.withValues(alpha: 0.10)
                : _hovered
                    ? AppTheme.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.isActive ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isActive ? widget.tab.activeIcon : widget.tab.icon,
                color: widget.isActive ? AppTheme.primary : _hovered ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                widget.tab.label,
                style: GoogleFonts.rajdhani(
                  fontSize: 9,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive ? AppTheme.primary : _hovered ? AppTheme.primary.withValues(alpha: 0.6) : AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom DBD Navigation Bar (narrow/mobile) ────────────────────────────────

class _DbdNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;
  final VoidCallback onSignOut;

  const _DbdNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 60 + bottomPad,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
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
          children: [
            ...List.generate(
              tabs.length,
              (i) => _NavItem(
                tab: tabs[i],
                isActive: i == selectedIndex,
                onTap: () => onTap(i),
              ),
            ),
            _NavSignOutItem(onSignOut: onSignOut),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            color: _hovered && !widget.isActive
                ? AppTheme.primary.withValues(alpha: 0.04)
                : Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active indicator bar at top
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: widget.isActive ? 28 : 0,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    boxShadow: widget.isActive
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
                const SizedBox(height: 6),
                Icon(
                  widget.isActive ? widget.tab.activeIcon : widget.tab.icon,
                  color: widget.isActive
                      ? AppTheme.primary
                      : _hovered
                          ? AppTheme.primary.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: GoogleFonts.rajdhani(
                    fontSize: widget.isActive ? 10 : 9,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isActive
                        ? AppTheme.primary
                        : _hovered
                            ? AppTheme.primary.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                  child: Text(
                    widget.tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sign-Out button for nav rail ────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final dynamic user;
  final VoidCallback onSignOut;

  const _SignOutButton({required this.user, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSignOut,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                radius: 11,
                backgroundImage: NetworkImage(user!.photoURL as String),
              )
            else
              const Icon(Icons.account_circle_outlined,
                  color: AppTheme.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(
              'WYLOGUJ',
              style: GoogleFonts.rajdhani(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign-Out item for bottom nav bar ────────────────────────────────────────

class _NavSignOutItem extends StatelessWidget {
  final VoidCallback onSignOut;

  const _NavSignOutItem({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSignOut,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            const Icon(Icons.logout, color: AppTheme.textSecondary, size: 20),
            const SizedBox(height: 2),
            Text(
              'WYLOGUJ',
              style: GoogleFonts.rajdhani(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ─── Tab item data ────────────────────────────────────────────────────────────

class _TabItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
