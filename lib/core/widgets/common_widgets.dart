import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';

// ─── Page Header ──────────────────────────────────────────────────────────────
// Inline page header for tab screens (replaces Flutter AppBar).

class PageHeader extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;

  const PageHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.background.withValues(alpha: 0.7),
              border: const Border(
                bottom: BorderSide(color: AppTheme.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: title),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget text(String label) => Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: 0.5,
        ),
      );
}

// ─── Base Slot ────────────────────────────────────────────────────────────────
// Shared slot container used by PerkSlot, ItemSlot and OfferingSlot.
// Handles the empty/filled visual state (border, background, empty label).
// The caller provides [filledContent] — the full Row shown when non-empty.

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
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.onTap,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget slot = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: isEmpty ? AppTheme.surface : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEmpty ? AppTheme.border : filledBorderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isEmpty
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(emptyIcon, color: AppTheme.textTertiary, size: emptyIconSize),
                    const SizedBox(width: 6),
                    Text(
                      emptyLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: contentPadding,
                child: filledContent,
              ),
      ),
    );
    if (animate) {
      return slot.animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
    }
    return slot;
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2.5,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
          margin: const EdgeInsets.only(right: 8),
        ),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: AppTheme.border)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

// ─── DbdButton ────────────────────────────────────────────────────────────────

class DbdButton extends StatefulWidget {
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
  State<DbdButton> createState() => _DbdButtonState();
}

class _DbdButtonState extends State<DbdButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: isEnabled ? (_) => setState(() => _hovered = true) : null,
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : (_hovered ? 1.01 : 1.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.outlined
                ? null
                : isEnabled
                    ? AppTheme.primaryGradient
                    : null,
            color: widget.outlined
                ? AppTheme.surface
                : isEnabled
                    ? null
                    : AppTheme.primaryDim,
            border: widget.outlined
                ? Border.all(color: AppTheme.primary.withValues(alpha: _hovered ? 0.6 : 0.4))
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: !widget.outlined && isEnabled
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(
                          alpha: _pressed ? 0.25 : _hovered ? 0.5 : 0.35),
                      blurRadius: _pressed ? 8 : _hovered ? 28 : 18,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: widget.outlined
                              ? AppTheme.primary
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: widget.outlined
                              ? AppTheme.primary
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      ),
    );
  }
}

// ─── Role Toggle ──────────────────────────────────────────────────────────────

class RoleToggle extends StatelessWidget {
  final bool isSurvivor;
  final ValueChanged<bool> onChanged;

  const RoleToggle({super.key, required this.isSurvivor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: l10n?.survivor ?? 'Survivor', isActive: isSurvivor, onTap: () => onChanged(true)),
          _Tab(label: l10n?.killer ?? 'Killer', isActive: !isSurvivor, onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryDim],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(icon, size: 32, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 28), action!],
          ],
        ),
      ),
    );
  }
}

// ─── Item helpers (shared between Build & GroupPlan editors) ──────────────────

Color itemCategoryColor(String cat) {
  switch (cat) {
    case 'medkit':     return const Color(0xFF4CAF50);
    case 'flashlight': return const Color(0xFFFFEB3B);
    case 'toolbox':    return const Color(0xFF2196F3);
    case 'key':        return const Color(0xFF9C27B0);
    case 'map':        return const Color(0xFFFF9800);
    default:           return AppTheme.textDim;
  }
}

IconData itemCategoryIcon(String cat) {
  switch (cat) {
    case 'medkit':     return Icons.medical_services_outlined;
    case 'flashlight': return Icons.flashlight_on_outlined;
    case 'toolbox':    return Icons.build_outlined;
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
  Widget build(BuildContext context) {
    final color = itemCategoryColor(item.category);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Icon(itemCategoryIcon(item.category), color: color, size: size * 0.5),
      ),
    );
  }
}
