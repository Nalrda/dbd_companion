import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Background Orb ──────────────────────────────────────────────────────────

class BackgroundOrb {
  final Color color;
  final double opacity;
  final Alignment position;
  final double size;

  const BackgroundOrb({
    required this.color,
    this.opacity = 0.25,
    required this.position,
    this.size = 400,
  });
}

// ─── App Background ──────────────────────────────────────────────────────────

class AppBackground extends StatelessWidget {
  final Widget child;
  final List<BackgroundOrb> orbs;

  const AppBackground({
    super.key,
    required this.child,
    this.orbs = const [],
  });

  /// Default two-orb background using primary color.
  static List<BackgroundOrb> defaultOrbs({
    Alignment topOrbAlign = Alignment.topRight,
    Alignment bottomOrbAlign = Alignment.bottomLeft,
  }) {
    return [
      BackgroundOrb(
        color: AppTheme.primary,
        opacity: 0.22,
        position: topOrbAlign,
        size: 420,
      ),
      BackgroundOrb(
        color: AppTheme.primaryDim,
        opacity: 0.18,
        position: bottomOrbAlign,
        size: 360,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Stack(
        children: [
          // Orbs
          ...orbs.map((orb) => Positioned.fill(
                child: Align(
                  alignment: orb.position,
                  child: Container(
                    width: orb.size,
                    height: orb.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          orb.color.withValues(alpha: orb.opacity),
                          orb.color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          // Content
          child,
        ],
      ),
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool addInsetHighlight;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
    this.backgroundColor,
    this.addInsetHighlight = true,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppTheme.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppTheme.border,
              width: 1,
            ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          child: Stack(
            children: [
              // Inset top highlight
              if (addInsetHighlight)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: borderRadius,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        topRight: Radius.circular(borderRadius),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ─── Glass Button ─────────────────────────────────────────────────────────────

class GlassButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final bool primary;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.primary = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
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
            decoration: widget.outlined
                ? BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.primary
                          ? AppTheme.primary.withValues(alpha: _hovered ? 0.6 : 0.35)
                          : AppTheme.border,
                    ),
                  )
                : BoxDecoration(
                    gradient: isEnabled
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary,
                              AppTheme.primaryDim,
                            ],
                          )
                        : null,
                    color: isEnabled ? null : AppTheme.primaryDim,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(
                                  alpha: _pressed ? 0.25 : _hovered ? 0.5 : 0.35),
                              blurRadius: _pressed ? 8 : _hovered ? 28 : 18,
                              offset: const Offset(0, 4),
                            ),
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
                                ? (widget.primary
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary)
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
                                ? (widget.primary
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary)
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

// ─── Glass Text Field ─────────────────────────────────────────────────────────

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? style;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: style ??
          GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        hintStyle: GoogleFonts.outfit(
          color: AppTheme.textTertiary,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ─── Accent Pill Toggle ───────────────────────────────────────────────────────

class AccentPillToggle extends StatelessWidget {
  final bool isFirst;
  final String firstLabel;
  final String secondLabel;
  final IconData? firstIcon;
  final IconData? secondIcon;
  final ValueChanged<bool> onChanged;

  const AccentPillToggle({
    super.key,
    required this.isFirst,
    required this.firstLabel,
    required this.secondLabel,
    this.firstIcon,
    this.secondIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PillTab(
                label: firstLabel,
                icon: firstIcon,
                isActive: isFirst,
                onTap: () => onChanged(true),
              ),
              _PillTab(
                label: secondLabel,
                icon: secondIcon,
                isActive: !isFirst,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primaryDim,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionLabel({super.key, required this.title, this.trailing});

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
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.border,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

// ─── Glass Empty State ────────────────────────────────────────────────────────

class GlassEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const GlassEmptyState({
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

// ─── Glass Page Header ────────────────────────────────────────────────────────

class GlassPageHeader extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;

  const GlassPageHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  static Widget text(String t) => Builder(
        builder: (context) => Text(
          t,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: topPad + 12,
            bottom: 12,
            left: 16,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.7),
            border: Border(
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
    );
  }
}
