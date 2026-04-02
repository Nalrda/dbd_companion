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

    // ── Wide / desktop: top horizontal nav bar ──────────────────────────────
    if (isWide) {
      return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopNavBar(
              selectedIndex: idx,
              tabs: _tabs,
              onTap: (i) => context.go(_tabs[i].path),
              user: user,
              onSignOut: signOut,
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.border),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Narrow / mobile: bottom navigation bar ──────────────────────────────
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: idx,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].path),
        onSignOut: signOut,
      ),
    );
  }
}

// ─── Top Navigation Bar (wide screens) ───────────────────────────────────────

class _TopNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;
  final dynamic user;
  final VoidCallback onSignOut;

  const _TopNavBar({
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
      height: 56 + topPad,
      padding: EdgeInsets.only(top: topPad),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // ── Logo mark (click → settings) ─────────────────────────────────
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.push('/settings'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 32),
            // ── Nav items ─────────────────────────────────────────────────────
            ...List.generate(
              tabs.length,
              (i) => _TopNavItem(
                tab: tabs[i],
                isActive: i == selectedIndex,
                onTap: () => onTap(i),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _TopNavItem extends StatefulWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _TopNavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TopNavItem> createState() => _TopNavItemState();
}

class _TopNavItemState extends State<_TopNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isActive
        ? AppTheme.primary
        : _hovered
            ? AppTheme.primary.withValues(alpha: 0.65)
            : AppTheme.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primary.withValues(alpha: 0.07)
                : _hovered
                    ? AppTheme.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isActive ? widget.tab.activeIcon : widget.tab.icon,
                color: iconColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.tab.label,
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w600,
                  color: iconColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSignOutButton extends StatefulWidget {
  final dynamic user;
  final VoidCallback onSignOut;

  const _TopSignOutButton({required this.user, required this.onSignOut});

  @override
  State<_TopSignOutButton> createState() => _TopSignOutButtonState();
}

class _TopSignOutButtonState extends State<_TopSignOutButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSignOut,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.user?.photoURL != null)
                CircleAvatar(
                  radius: 12,
                  backgroundImage:
                      NetworkImage(widget.user!.photoURL as String),
                )
              else
                Icon(
                  Icons.account_circle_outlined,
                  color: _hovered ? AppTheme.primary : AppTheme.textSecondary,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Text(
                'SIGN OUT',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? AppTheme.primary : AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar (narrow / mobile) ──────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;
  final VoidCallback onSignOut;

  const _BottomNavBar({
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
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGlow,
            blurRadius: 24,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Row(
          children: [
            ...List.generate(
              tabs.length,
              (i) => _BottomNavItem(
                tab: tabs[i],
                isActive: i == selectedIndex,
                onTap: () => onTap(i),
              ),
            ),
            _BottomSettingsItem(onSignOut: onSignOut),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatefulWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<_BottomNavItem> {
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
                    fontWeight:
                        widget.isActive ? FontWeight.w700 : FontWeight.w500,
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

class _BottomSettingsItem extends StatelessWidget {
  final VoidCallback onSignOut;

  const _BottomSettingsItem({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/settings'),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            const Icon(Icons.settings_outlined, color: AppTheme.textSecondary, size: 20),
            const SizedBox(height: 2),
            Text(
              'MORE',
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
