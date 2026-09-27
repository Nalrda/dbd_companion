import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  DESIGN SYSTEM
//  Visual language: dark "fog" canvas with film grain, notched panels (cut
//  top-left / bottom-right corners), condensed uppercase labels, diamond
//  markers and a single accent color taken from the selected theme.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Background ───────────────────────────────────────────────────────────────

/// Page backdrop: flat base, a faint accent haze from the top, fog rising from
/// the bottom and a static film grain. Wrap each page's content in it.
class AppBackground extends StatelessWidget {
  final Widget child;

  /// Horizontal anchor of the accent haze (-1 left … 1 right).
  final double hazeX;

  const AppBackground({super.key, required this.child, this.hazeX = 0.6});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: IgnorePointer(
              child: CustomPaint(
                isComplex: true,
                painter: _FogPainter(accent: AppTheme.primary, hazeX: hazeX),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  final Color accent;
  final double hazeX;

  _FogPainter({required this.accent, required this.hazeX});

  static final _grain = <int, Float32List>{};

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Accent haze from above.
    final hazeCenter = Offset(size.width * (0.5 + hazeX / 2), -size.height * 0.1);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.10), accent.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(
            center: hazeCenter, radius: math.max(size.width, size.height) * 0.65)),
    );

    // Fog rising from the bottom.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00FFFFFF),
            const Color(0xFFB8B2C8).withValues(alpha: 0.035),
          ],
        ).createShader(
            Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45)),
    );

    // Film grain — deterministic points, cached per canvas size bucket.
    final key = (size.width ~/ 64) * 10000 + (size.height ~/ 64);
    final points = _grain.putIfAbsent(key, () {
      final rnd = math.Random(7);
      final count = (size.width * size.height / 90).clamp(0, 60000).toInt();
      final list = Float32List(count * 2);
      for (var i = 0; i < count; i++) {
        list[i * 2] = rnd.nextDouble() * size.width;
        list[i * 2 + 1] = rnd.nextDouble() * size.height;
      }
      return list;
    });
    canvas.drawRawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = const Color(0x0DFFFFFF)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_FogPainter old) => old.accent != accent || old.hazeX != hazeX;
}

// ─── Panel ────────────────────────────────────────────────────────────────────

/// The basic container: solid surface, hairline border, notched corners.
/// Supports hover, selection and an optional colored edge on the left.
class AppPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final Color? edgeColor;
  final Color? color;
  final Color? borderColor;
  final double cut;

  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.edgeColor,
    this.color,
    this.borderColor,
    this.cut = 10,
  });

  @override
  State<AppPanel> createState() => _AppPanelState();
}

class _AppPanelState extends State<AppPanel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final borderColor = widget.selected
        ? AppTheme.primary.withValues(alpha: 0.7)
        : widget.borderColor ??
            (_hovered && interactive ? AppTheme.borderHighlight : AppTheme.border);
    final fill = widget.color ??
        (widget.selected
            ? Color.alphaBlend(AppTheme.primarySoft, AppTheme.surface)
            : _hovered && interactive
                ? AppTheme.surfaceElevated
                : AppTheme.surface);

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.edgeColor != null) {
      content = Stack(
        children: [
          content,
          Positioned(
            left: 0,
            top: widget.cut + 4,
            bottom: 12,
            child: Container(width: 2, color: widget.edgeColor),
          ),
        ],
      );
    }

    final shape = AppShapes.notched(
      cut: widget.cut,
      side: BorderSide(color: borderColor),
    );

    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: ShapeDecoration(color: fill, shape: shape),
      child: content,
    );

    if (!interactive) return panel;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          customBorder: shape,
          child: panel,
        ),
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Condensed uppercase button with notched corners.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final bool compact;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = false,
    this.compact = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expand = false,
    this.compact = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expand = false,
    this.compact = false,
  }) : variant = AppButtonVariant.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final v = widget.variant;

    Color fill;
    Color fg;
    BorderSide side = BorderSide.none;
    switch (v) {
      case AppButtonVariant.primary:
        fill = _hovered && enabled
            ? Color.lerp(AppTheme.primary, Colors.white, 0.08)!
            : AppTheme.primary;
        fg = AppTheme.onPrimary;
        if (!enabled) {
          fill = AppTheme.primaryDim;
          fg = AppTheme.textSecondary;
        }
      case AppButtonVariant.secondary:
        fill = _hovered && enabled ? AppTheme.hoverSurface : AppTheme.surfaceElevated;
        fg = enabled ? AppTheme.textPrimary : AppTheme.textTertiary;
        side = BorderSide(color: _hovered ? AppTheme.borderHighlight : AppTheme.border);
      case AppButtonVariant.ghost:
        fill = _hovered && enabled ? AppTheme.surfaceElevated : Colors.transparent;
        fg = enabled ? AppTheme.textSecondary : AppTheme.textTertiary;
      case AppButtonVariant.danger:
        fill = _hovered && enabled
            ? AppTheme.danger.withValues(alpha: 0.18)
            : AppTheme.danger.withValues(alpha: 0.10);
        fg = AppTheme.danger;
        side = BorderSide(color: AppTheme.danger.withValues(alpha: 0.45));
    }

    final height = widget.compact ? 38.0 : 48.0;
    final shape = AppShapes.notched(cut: widget.compact ? 7 : 9, side: side);

    final labelRow = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: widget.compact ? 16 : 18, color: fg),
        if ((widget.icon != null || widget.isLoading) && widget.label.isNotEmpty)
          SizedBox(width: widget.compact ? 6 : 8),
        if (widget.label.isNotEmpty)
          Flexible(
            child: Text(
              widget.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.display(
                fontSize: widget.compact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 1.2,
              ),
            ),
          ),
      ],
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: height,
        width: widget.expand ? double.infinity : null,
        decoration: ShapeDecoration(
          color: fill,
          shape: shape,
          shadows: v == AppButtonVariant.primary && enabled && _hovered
              ? [BoxShadow(color: AppTheme.primaryGlow, blurRadius: 18)]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            customBorder: shape,
            splashColor: fg.withValues(alpha: 0.12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.compact ? 14 : 20),
              child: labelRow,
            ),
          ),
        ),
      ),
    );
  }
}

/// Square hairline icon button used in headers and toolbars.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool active;
  final double size;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.active = false,
    this.size = 40,
    this.color,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.active
        ? AppTheme.primary
        : widget.color ?? (_hovered ? AppTheme.textPrimary : AppTheme.textSecondary);
    final shape = AppShapes.notched(
      cut: 6,
      side: BorderSide(
        color: widget.active
            ? AppTheme.primary.withValues(alpha: 0.5)
            : _hovered
                ? AppTheme.borderHighlight
                : AppTheme.border,
      ),
    );
    Widget button = MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.active ? AppTheme.primarySoft : AppTheme.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(widget.icon, size: widget.size * 0.47, color: fg),
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Accent action button placed bottom-right on compact layouts.
class AppFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const AppFab({
    super.key,
    this.icon = Icons.add,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final shape = AppShapes.notched(cut: 12);
    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [
            BoxShadow(color: AppTheme.primaryGlow, blurRadius: 22, offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: AppTheme.primary,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(icon, color: AppTheme.onPrimary, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Segmented control ────────────────────────────────────────────────────────

class AppSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  const AppSegment({required this.value, required this.label, this.icon});
}

/// Two-to-four option switch. The active option gets an accent underline and
/// soft fill — calmer than a solid block but unmistakable.
class AppSegmented<T> extends StatelessWidget {
  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool expand;

  const AppSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = segments.map((s) {
      final active = s.value == value;
      final child = _SegmentButton(
        label: s.label,
        icon: s.icon,
        active: active,
        onTap: () => onChanged(s.value),
      );
      return expand ? Expanded(child: child) : child;
    }).toList();

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: AppTheme.surface,
        shape: AppShapes.notched(cut: 8, side: const BorderSide(color: AppTheme.border)),
      ),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: items),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppTheme.textPrimary : AppTheme.textTertiary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: active ? AppTheme.primarySoft : Colors.transparent,
            shape: AppShapes.notched(
              cut: 6,
              side: BorderSide(
                color: active ? AppTheme.primary.withValues(alpha: 0.55) : Colors.transparent,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: active ? AppTheme.primary : fg),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: AppFonts.display(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chips & tags ─────────────────────────────────────────────────────────────

/// Toggleable filter chip.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.primary;
    final fg = selected ? accent : AppTheme.textSecondary;
    final shape = AppShapes.notched(
      cut: 5,
      side: BorderSide(color: selected ? accent.withValues(alpha: 0.6) : AppTheme.border),
    );
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : AppTheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppFonts.body(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small static label (e.g. build tags, rarity).
class AppTag extends StatelessWidget {
  final String label;
  final Color? color;

  const AppTag(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: ShapeDecoration(
        color: c.withValues(alpha: 0.10),
        shape: AppShapes.notched(cut: 4, side: BorderSide(color: c.withValues(alpha: 0.25))),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppFonts.display(fontSize: 11, fontWeight: FontWeight.w600, color: c, letterSpacing: 1),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

/// ◆ SECTION TITLE ──────────── [trailing]
class SectionLabel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? count;

  const SectionLabel({super.key, required this.title, this.trailing, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DiamondMark(size: 7, color: AppTheme.primary),
        const SizedBox(width: 10),
        Text(title.toUpperCase(), style: AppFonts.caption(color: AppTheme.textSecondary, fontSize: 12)),
        if (count != null) ...[
          const SizedBox(width: 8),
          Text(count!, style: AppFonts.caption(fontSize: 12)),
        ],
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

/// Small filled/outlined diamond used as bullet and marker.
class DiamondMark extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;

  const DiamondMark({super.key, this.size = 8, required this.color, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          border: filled ? null : Border.all(color: color, width: 1.2),
        ),
      ),
    );
  }
}

// ─── Search field ─────────────────────────────────────────────────────────────

class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const AppSearchField({
    super.key,
    this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        style: AppFonts.body(fontSize: 14),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: controller != null
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller!,
                  builder: (_, v, __) => v.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            controller!.clear();
                            onChanged?.call('');
                            onClear?.call();
                          },
                        ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

// ─── Stat tile ────────────────────────────────────────────────────────────────

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const StatTile({super.key, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppFonts.display(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: color ?? AppTheme.textPrimary,
            letterSpacing: 0.5,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: AppFonts.caption(), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ─── Dialogs ──────────────────────────────────────────────────────────────────

/// Standard dialog: title, content, cancel + confirm.
class AppDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final bool destructive;

  const AppDialog({
    super.key,
    required this.title,
    this.content,
    this.cancelLabel = 'Cancel',
    required this.confirmLabel,
    this.onCancel,
    required this.onConfirm,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DiamondMark(
                    size: 8,
                    color: destructive ? AppTheme.danger : AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: AppFonts.display(fontSize: 20, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
              if (content != null) ...[
                const SizedBox(height: 14),
                DefaultTextStyle(
                  style: AppFonts.body(color: AppTheme.textSecondary, height: 1.45),
                  child: content!,
                ),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.ghost(
                    label: cancelLabel,
                    compact: true,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: confirmLabel,
                    compact: true,
                    variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                    onPressed: onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a confirm dialog and resolves to `true` when confirmed.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      content: message != null ? Text(message) : null,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      destructive: destructive,
      onCancel: () => Navigator.of(ctx).pop(false),
      onConfirm: () => Navigator.of(ctx).pop(true),
    ),
  );
  return result ?? false;
}

/// Shows a one-field text prompt and resolves to the trimmed text (or null).
Future<String?> showAppTextPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String? hint,
  String? initialValue,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  int maxLines = 1,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      void submit() {
        final v = controller.text.trim();
        if (v.isNotEmpty) Navigator.of(ctx).pop(v);
      }

      return AppDialog(
        title: title,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        onCancel: () => Navigator.of(ctx).pop(),
        onConfirm: submit,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[Text(message), const SizedBox(height: 12)],
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: maxLines,
              style: AppFonts.body(),
              decoration: InputDecoration(hintText: hint),
              onSubmitted: maxLines == 1 ? (_) => submit() : null,
            ),
          ],
        ),
      );
    },
  ).whenComplete(controller.dispose);
}

/// Short confirmation toast.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            DiamondMark(size: 7, color: error ? AppTheme.danger : AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

// ─── Layout helpers ───────────────────────────────────────────────────────────

/// Centers page content and caps it at a readable width.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({super.key, required this.child, this.maxWidth = AppLayout.contentMax});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Horizontal page padding that grows on wide screens.
EdgeInsets pagePadding(BuildContext context, {double top = 0, double bottom = 24}) {
  final compact = AppLayout.isCompact(context);
  final h = compact ? 16.0 : 28.0;
  return EdgeInsets.fromLTRB(h, top, h, bottom);
}

/// Consistent staggered entrance for list items.
extension AppEntrance on Widget {
  Widget entrance(int index, {int step = 35, int max = 10}) {
    final delay = (index.clamp(0, max) * step).ms;
    return animate()
        .fadeIn(duration: 260.ms, delay: delay, curve: Curves.easeOut)
        .moveY(begin: 8, end: 0, duration: 260.ms, delay: delay, curve: Curves.easeOutCubic);
  }
}

