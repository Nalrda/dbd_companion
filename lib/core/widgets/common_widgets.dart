import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';
import 'design_system.dart';

// ─── Shell scope ──────────────────────────────────────────────────────────────
// Lets pages know they are rendered inside the tab shell, so the compact
// header can offer the settings shortcut the bottom bar has no room for.

class ShellScope extends InheritedWidget {
  final bool compact;

  const ShellScope({super.key, required this.compact, required super.child});

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => old.compact != compact;
}

// ─── Page Header ──────────────────────────────────────────────────────────────
// Large condensed title with an optional subtitle, back button, actions and a
// `bottom` row for filters (role switch, search…).

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;

  /// Shows a back button. Defaults to popping the current route.
  final bool showBack;
  final VoidCallback? onBack;

  /// Replaces the title text (e.g. an inline name field).
  final Widget? titleWidget;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.showBack = false,
    this.onBack,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    final shell = ShellScope.maybeOf(context);
    final pad = pagePadding(context);
    final topPad = shell == null ? MediaQuery.paddingOf(context).top : 0.0;

    final trailing = <Widget>[
      ...actions,
      if (shell != null && shell.compact)
        AppIconButton(
          icon: Icons.settings_outlined,
          tooltip: AppLocalizations.of(context)?.settings ?? 'Settings',
          onPressed: () => context.push('/settings'),
        ),
    ];

    return ContentWidth(
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad.left, topPad + (compact ? 14 : 26), pad.right, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBack) ...[
                  AppIconButton(
                    icon: Icons.arrow_back,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: onBack ??
                        () => context.canPop() ? context.pop() : context.go('/builds'),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: titleWidget ??
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.display(
                              fontSize: compact ? 26 : 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                              height: 1.05,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(fontSize: 13, color: AppTheme.textTertiary),
                            ),
                          ],
                        ],
                      ),
                ),
                for (final a in trailing) ...[const SizedBox(width: 8), a],
              ],
            ),
            if (bottom != null) ...[const SizedBox(height: 16), bottom!],
          ],
        ),
      ),
    );
  }
}

// ─── Base Slot ────────────────────────────────────────────────────────────────
// Shared slot container used by PerkSlot, ItemSlot and OfferingSlot.
// Empty: outlined diamond with "+" and a label. Filled: caller's content.

class BaseSlot extends StatelessWidget {
  final bool isEmpty;
  final double height;
  final Color filledBorderColor;
  final IconData emptyIcon;
  final double emptyIconSize;
  final String emptyLabel;
  final Widget filledContent;
  final EdgeInsets contentPadding;
  final VoidCallback? onTap;
  final bool animate;

  const BaseSlot({
    super.key,
    required this.isEmpty,
    required this.height,
    required this.filledBorderColor,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.filledContent,
    this.emptyIconSize = 16,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.onTap,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget slot = SizedBox(
      height: height,
      child: AppPanel(
        onTap: onTap,
        padding: isEmpty ? const EdgeInsets.symmetric(horizontal: 14) : contentPadding,
        cut: 8,
        color: isEmpty ? AppTheme.background.withValues(alpha: 0.4) : null,
        borderColor: isEmpty ? AppTheme.border : filledBorderColor,
        child: isEmpty
            ? Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const DiamondMark(size: 18, color: AppTheme.borderHighlight, filled: false),
                        Icon(emptyIcon, size: 12, color: AppTheme.textTertiary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      emptyLabel.toUpperCase(),
                      style: AppFonts.caption(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.add, size: 18, color: AppTheme.textTertiary),
                ],
              )
            : filledContent,
      ),
    );
    if (animate) {
      slot = slot.animate().fadeIn(duration: 200.ms);
    }
    return slot;
  }
}

/// Small "×" used to clear a filled slot.
class SlotRemoveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const SlotRemoveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.close, size: 16, color: AppTheme.textTertiary),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => SectionLabel(title: title, trailing: trailing);
}

// ─── DbdButton ────────────────────────────────────────────────────────────────
// Kept for existing call sites; renders the design-system [AppButton].

class DbdButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  const DbdButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: outlined ? AppButtonVariant.secondary : AppButtonVariant.primary,
    );
  }
}

// ─── Role Toggle ──────────────────────────────────────────────────────────────

class RoleToggle extends StatelessWidget {
  final bool isSurvivor;
  final ValueChanged<bool> onChanged;
  final bool expand;

  const RoleToggle({
    super.key,
    required this.isSurvivor,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppSegmented<bool>(
      expand: expand,
      value: isSurvivor,
      onChanged: onChanged,
      segments: [
        AppSegment(value: true, label: l10n?.survivor ?? 'Survivor', icon: Icons.directions_run),
        AppSegment(value: false, label: l10n?.killer ?? 'Killer', icon: Icons.local_fire_department_outlined),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const DiamondMark(size: 58, color: AppTheme.border, filled: false),
                    DiamondMark(size: 44, color: AppTheme.primary.withValues(alpha: 0.08)),
                    Icon(icon, size: 26, color: AppTheme.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title.toUpperCase(),
                style: AppFonts.display(fontSize: 22, letterSpacing: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppFonts.body(fontSize: 14, color: AppTheme.textSecondary, height: 1.45),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

/// Centered loader / error used while async data resolves.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
}

class ErrorView extends StatelessWidget {
  final Object error;
  const ErrorView(this.error, {super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: '$error',
      );
}

// ─── Item helpers (shared between Build & GroupPlan editors) ──────────────────

Color itemCategoryColor(String cat) {
  switch (cat) {
    case 'medkit':     return const Color(0xFF6BBF73);
    case 'flashlight': return const Color(0xFFF2D65C);
    case 'toolbox':    return const Color(0xFF5DA9E9);
    case 'key':        return const Color(0xFFB07CD8);
    case 'map':        return const Color(0xFFF0A04B);
    default:           return AppTheme.textDim;
  }
}

IconData itemCategoryIcon(String cat) {
  switch (cat) {
    case 'medkit':     return Icons.medical_services_outlined;
    case 'flashlight': return Icons.flashlight_on_outlined;
    case 'toolbox':    return Icons.handyman_outlined;
    case 'key':        return Icons.key_outlined;
    case 'map':        return Icons.map_outlined;
    default:           return Icons.inventory_2_outlined;
  }
}

String itemCategoryLabel(String cat) {
  switch (cat) {
    case 'medkit':     return 'Medkit';
    case 'flashlight': return 'Flashlight';
    case 'toolbox':    return 'Toolbox';
    case 'key':        return 'Key';
    case 'map':        return 'Map';
    default:           return 'Item';
  }
}

// ─── Item Icon ────────────────────────────────────────────────────────────────

class ItemIcon extends StatelessWidget {
  final Item item;
  final double size;
  const ItemIcon({super.key, required this.item, this.size = 48});

  @override
  Widget build(BuildContext context) =>
      SquareGlyph(icon: itemCategoryIcon(item.category), color: itemCategoryColor(item.category), size: size);
}

/// Notched square holding a tinted glyph — used for items and offerings.
class SquareGlyph extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const SquareGlyph({super.key, required this.icon, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.10),
        shape: AppShapes.notched(
          cut: size * 0.18,
          side: BorderSide(color: color.withValues(alpha: 0.45)),
        ),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
