import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      _TabItem(
        path: '/builds',
        label: l10n.tabBuilds,
        icon: Icons.construction_outlined,
        activeIcon: Icons.construction,
      ),
      _TabItem(
        path: '/group',
        label: l10n.tabGroup,
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups,
      ),
      _TabItem(
        path: '/randomizer',
        label: l10n.tabRandom,
        icon: Icons.casino_outlined,
        activeIcon: Icons.casino,
      ),
      _TabItem(
        path: '/matches',
        label: l10n.tabMatches,
        icon: Icons.history_outlined,
        activeIcon: Icons.history,
      ),
      _TabItem(
        path: '/maps',
        label: l10n.tabMaps,
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
      ),
    ];

    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = tabs.indexWhere((t) => location.startsWith(t.path));
    final idx = currentIndex < 0 ? 0 : currentIndex;
    final isWide = MediaQuery.of(context).size.width >= 600;
    final authNotifier = ref.watch(authNotifierProvider);
    final user = authNotifier.user;
    final isGuest = authNotifier.isGuest;

    void signOut() => ref.read(authNotifierProvider).signOut();
    void signInWithGoogle() => ref.read(authNotifierProvider).signInWithGoogle();

    if (isWide) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopNavBar(
              selectedIndex: idx,
              tabs: tabs,
              onTap: (i) => context.go(tabs[i].path),
              user: user,
              onSignOut: signOut,
            ),
            if (isGuest) _GuestBanner(onSignIn: signInWithGoogle),
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (isGuest) _GuestBanner(onSignIn: signInWithGoogle),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: idx,
        tabs: tabs,
        onTap: (i) => context.go(tabs[i].path),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56 + topPad,
          padding: EdgeInsets.only(top: topPad),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(color: AppTheme.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Logo mark
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withValues(alpha: 0.3),
                            AppTheme.primaryDim.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings,
                        color: AppTheme.primary,
                        size: 17,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
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
    final color = widget.isActive
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primary.withValues(alpha: 0.08)
                : _hovered
                    ? AppTheme.primary.withValues(alpha: 0.04)
                    : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? AppTheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isActive ? widget.tab.activeIcon : widget.tab.icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.tab.label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 62 + bottomPad,
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: AppTheme.border),
            ),
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
            duration: const Duration(milliseconds: 200),
            color: _hovered && !widget.isActive
                ? AppTheme.primary.withValues(alpha: 0.04)
                : Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Active indicator dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 2,
                  width: widget.isActive ? 24 : 0,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
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
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.outfit(
                    fontSize: widget.isActive ? 10 : 9,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: widget.isActive
                        ? AppTheme.primary
                        : _hovered
                            ? AppTheme.primary.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  child: Text(
                    widget.tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            const Icon(Icons.settings_outlined,
                color: AppTheme.textSecondary, size: 20),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.tabMore,
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Guest Banner ─────────────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  final VoidCallback onSignIn;
  const _GuestBanner({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline,
              color: AppTheme.textSecondary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.guestModeDesc,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onSignIn,
              child: Text(
                AppLocalizations.of(context)!.signIn,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
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
