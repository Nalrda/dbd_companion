import 'package:flutter/material.dart';
import '../models/perk.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'design_system.dart';

// ─── Perk Icon ────────────────────────────────────────────────────────────────
// Perks are shown as diamonds, like in the game: a tinted rhombus with a
// hairline frame and the white perk glyph centered inside.

class PerkIcon extends StatelessWidget {
  final Perk perk;
  final double size;
  final bool showCategoryGlow;

  const PerkIcon({
    super.key,
    required this.perk,
    this.size = 48,
    this.showCategoryGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = size * 0.78;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: DiamondFramePainter(
              fill: Color.alphaBlend(
                AppTheme.primary.withValues(alpha: showCategoryGlow ? 0.28 : 0.14),
                AppTheme.surfaceElevated,
              ),
              stroke: AppTheme.primary.withValues(alpha: showCategoryGlow ? 0.95 : 0.55),
              glow: showCategoryGlow ? AppTheme.primaryGlow : null,
            ),
          ),
          SizedBox(
            width: glyph,
            height: glyph,
            child: _PerkImage(perk: perk, size: glyph, fallback: _fallback(glyph)),
          ),
        ],
      ),
    );
  }

  Widget _fallback(double glyph) => Center(
        child: Text(
          perk.name.isNotEmpty ? perk.name[0] : '?',
          style: AppFonts.display(fontSize: glyph * 0.42, color: AppTheme.textSecondary),
        ),
      );
}

/// Diamond (rhombus) with fill, hairline stroke and optional glow.
class DiamondFramePainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final Color? glow;
  final double strokeWidth;

  DiamondFramePainter({
    required this.fill,
    required this.stroke,
    this.glow,
    this.strokeWidth = 1.3,
  });

  Path _path(Size size, double inset) {
    final w = size.width, h = size.height;
    return Path()
      ..moveTo(w / 2, inset)
      ..lineTo(w - inset, h / 2)
      ..lineTo(w / 2, h - inset)
      ..lineTo(inset, h / 2)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _path(size, 1);
    if (glow != null) {
      canvas.drawPath(
        outer,
        Paint()
          ..color = glow!
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawPath(outer, Paint()..color = fill);
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = stroke,
    );
    // Inner hairline for depth.
    canvas.drawPath(
      _path(size, size.width * 0.09),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = stroke.withValues(alpha: stroke.a * 0.35),
    );
  }

  @override
  bool shouldRepaint(DiamondFramePainter old) =>
      old.fill != fill || old.stroke != stroke || old.glow != glow;
}

/// Row of four small diamonds showing a build's perks at a glance; empty
/// positions render as outlines.
class PerkDiamondRow extends StatelessWidget {
  final List<Perk?> perks;
  final double size;
  final double spacing;

  const PerkDiamondRow({super.key, required this.perks, this.size = 34, this.spacing = 2});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final perk = i < perks.length ? perks[i] : null;
        return Padding(
          padding: EdgeInsets.only(right: i == 3 ? 0 : spacing),
          child: perk != null
              ? Tooltip(message: perk.name, child: PerkIcon(perk: perk, size: size))
              : SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: DiamondFramePainter(
                      fill: AppTheme.background.withValues(alpha: 0.5),
                      stroke: AppTheme.border,
                    ),
                  ),
                ),
        );
      }),
    );
  }
}

// Tries local asset by name, then by ID, then network URL, then letter fallback.
class _PerkImage extends StatelessWidget {
  final Perk perk;
  final double size;
  final Widget fallback;

  const _PerkImage({required this.perk, required this.size, required this.fallback});

  // Converts perk name to a safe filename:
  // "Self-Care" → "self_care.png"
  // "Boon: Circle of Healing" → "boon_circle_of_healing.png"
  // "Déjà Vu" → "deja_vu.png"
  // "Coup de Grâce" → "coup_de_grace.png"
  static String _nameToFilename(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[éèê]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ûüù]'), 'u')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[çÇ]'), 'c')
        .replaceAll(RegExp(r'[ß]'), 'ss')
        .replaceAll(RegExp(r"[':,!?]"), '')
        .replaceAll('&', '')
        .replaceAll(RegExp(r'[-\s]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Widget _networkFallback(int cacheSize) {
    if (perk.iconUrl != null) {
      return Image.network(
        perk.iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
      );
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final nameFile = 'assets/images/perks/${_nameToFilename(perk.name)}.png';
    final idFile   = 'assets/images/perks/${perk.id}.png';
    final cacheSize = (size * MediaQuery.of(context).devicePixelRatio).ceil();

    return Image.asset(
      nameFile,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.low,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
      errorBuilder: (_, __, ___) => Image.asset(
        idFile,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (_, __, ___) => _networkFallback(cacheSize),
      ),
    );
  }
}

// ─── Perk Card ────────────────────────────────────────────────────────────────

class PerkCard extends StatelessWidget {
  final Perk perk;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  const PerkCard({
    super.key,
    required this.perk,
    this.isSelected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 46.0 : 60.0;
    return AppPanel(
      onTap: onTap,
      selected: isSelected,
      cut: 8,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 6 : 8),
      child: Row(
        children: [
          PerkIcon(perk: perk, size: iconSize, showCategoryGlow: isSelected),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  perk.name,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  perk.character,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Icon(Icons.check, size: 18, color: AppTheme.primary),
            ),
        ],
      ),
    );
  }
}

// ─── Perk Slot ────────────────────────────────────────────────────────────────

class PerkSlot extends StatelessWidget {
  final Perk? perk;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const PerkSlot({
    super.key,
    this.perk,
    required this.index,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return BaseSlot(
      isEmpty: perk == null,
      height: 76,
      filledBorderColor: AppTheme.border,
      emptyIcon: Icons.add,
      emptyLabel: 'Perk ${index + 1}',
      contentPadding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      onTap: onTap,
      animate: true,
      filledContent: perk == null
          ? const SizedBox()
          : Row(
              children: [
                PerkIcon(perk: perk!, size: 62),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        perk!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        perk!.character,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null) SlotRemoveButton(onPressed: onRemove!),
              ],
            ),
    );
  }
}
