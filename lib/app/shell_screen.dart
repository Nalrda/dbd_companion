import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/widgets.dart';

/// Tab shell. Phones get a bottom bar (settings live in each page header);
/// wider screens get a side rail that also holds the account block.
class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      _TabItem('/builds', l10n.tabBuilds, Icons.handyman_outlined, Icons.handyman),
      _TabItem('/group', l10n.tabGroup, Icons.groups_outlined, Icons.groups),
      _TabItem('/randomizer', l10n.tabRandom, Icons.casino_outlined, Icons.casino),
      _TabItem('/matches', l10n.tabMatches, Icons.history_outlined, Icons.history),
      _TabItem('/maps', l10n.tabMaps, Icons.map_outlined, Icons.map),
    ];

    final location = GoRouterState.of(context).matchedLocation;
    final found = tabs.indexWhere((t) => location.startsWith(t.path));
    final index = found < 0 ? 0 : found;
    void go(int i) => context.go(tabs[i].path);

    final auth = ref.watch(authNotifierProvider);
    final width = MediaQuery.sizeOf(context).width;

    if (width < AppLayout.compactMax) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: ShellScope(
            compact: true,
            child: Column(
              children: [
                if (auth.isGuest)
                  _GuestBanner(onSignIn: () => ref.read(authNotifierProvider).signInWithGoogle()),
                Expanded(child: child),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomBar(tabs: tabs, index: index, onTap: go),
      );
    }

    final expanded = width >= AppLayout.expandedMin;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideRail(tabs: tabs, index: index, onTap: go, expanded: expanded),
          const VerticalDivider(width: 1),
          Expanded(child: ShellScope(compact: false, child: child)),
        ],
      ),
    );
  }
}

class _TabItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem(this.path, this.label, this.icon, this.activeIcon);
}

// ─── Bottom bar (phones) ──────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int index;
  final ValueChanged<int> onTap;

  const _BottomBar({required this.tabs, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final t = tabs[i];
            final active = i == index;
            return Expanded(
              child: Semantics(
                selected: active,
                button: true,
                label: t.label,
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: active ? 1 : 0,
                        child: DiamondMark(size: 5, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 5),
                      Icon(
                        active ? t.activeIcon : t.icon,
                        size: 22,
                        color: active ? AppTheme.primary : AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t.label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: AppFonts.display(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                          color: active ? AppTheme.textPrimary : AppTheme.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Side rail (tablet / desktop) ─────────────────────────────────────────────

class _SideRail extends ConsumerWidget {
  final List<_TabItem> tabs;
  final int index;
  final ValueChanged<int> onTap;
  final bool expanded;

  const _SideRail({
    required this.tabs,
    required this.index,
    required this.onTap,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authNotifierProvider);
    final top = MediaQuery.paddingOf(context).top;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 236 : 88,
      color: AppTheme.backgroundSecondary,
      padding: EdgeInsets.fromLTRB(12, top + 20, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Brand(expanded: expanded),
          const SizedBox(height: 28),
          for (var i = 0; i < tabs.length; i++) ...[
            _RailItem(
              icon: i == index ? tabs[i].activeIcon : tabs[i].icon,
              label: tabs[i].label,
              active: i == index,
              expanded: expanded,
              onTap: () => onTap(i),
            ),
            const SizedBox(height: 4),
          ],
          const Spacer(),
          if (expanded) ...[
            _AccountBlock(auth: auth),
            const SizedBox(height: 8),
          ],
          _RailItem(
            icon: Icons.settings_outlined,
            label: l10n.settings,
            active: false,
            expanded: expanded,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool expanded;
  const _Brand({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DiamondMark(size: 26, color: AppTheme.primary, filled: false),
          DiamondMark(size: 11, color: AppTheme.primary),
        ],
      ),
    );
    if (!expanded) return Center(child: mark);
    return Row(
      children: [
        const SizedBox(width: 4),
        mark,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DBD', style: AppFonts.display(fontSize: 20, letterSpacing: 3, height: 1)),
              Text('COMPANION', style: AppFonts.caption(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RailItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final fg = active
        ? AppTheme.textPrimary
        : _hovered
            ? AppTheme.textPrimary
            : AppTheme.textSecondary;
    final shape = AppShapes.notched(cut: 7);

    final content = widget.expanded
        ? Row(
            children: [
              Icon(widget.icon, size: 20, color: active ? AppTheme.primary : fg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label.toUpperCase(),
                  style: AppFonts.display(
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              if (active) DiamondMark(size: 6, color: AppTheme.primary),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 22, color: active ? AppTheme.primary : fg),
              const SizedBox(height: 4),
              Text(
                widget.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppFonts.display(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          );

    final item = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: active
            ? AppTheme.primarySoft
            : _hovered
                ? AppTheme.surface
                : Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            children: [
              Padding(
                padding: widget.expanded
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                    : const EdgeInsets.symmetric(vertical: 10),
                child: content,
              ),
              if (active)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(width: 2, color: AppTheme.primary),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      selected: active,
      button: true,
      child: widget.expanded ? item : Tooltip(message: widget.label, child: item),
    );
  }
}

class _AccountBlock extends ConsumerWidget {
  final AuthNotifier auth;
  const _AccountBlock({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = auth.user;

    if (auth.isGuest || user == null) {
      return AppPanel(
        padding: const EdgeInsets.all(12),
        cut: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.guestModeDesc,
              style: AppFonts.body(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: l10n.signIn,
              icon: Icons.login,
              compact: true,
              onPressed: () => ref.read(authNotifierProvider).signInWithGoogle(),
            ),
          ],
        ),
      );
    }

    final name = user.displayName ?? user.email ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppTheme.surfaceElevated,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppFonts.display(fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest banner (phones) ────────────────────────────────────────────────────

class _GuestBanner extends StatelessWidget {
  final VoidCallback onSignIn;
  const _GuestBanner({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 15, color: AppTheme.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.guestModeDesc,
              maxLines: 2,
              style: AppFonts.body(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onSignIn,
            child: Text(
              l10n.signIn.toUpperCase(),
              style: AppFonts.display(fontSize: 13, color: AppTheme.primary, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
