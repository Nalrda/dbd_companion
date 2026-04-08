import 'package:flutter/material.dart';
import '../models/perk.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

// ─── Octagon Clipper ──────────────────────────────────────────────────────────

class _OctagonClipper extends CustomClipper<Path> {
  final double cut;
  const _OctagonClipper({this.cut = 7});

  @override
  Path getClip(Size size) {
    final c = cut;
    return Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c)
      ..close();
  }

  @override
  bool shouldReclip(_OctagonClipper old) => old.cut != cut;
}

class _OctagonBorderPainter extends CustomPainter {
  final double cut;
  final Color color;
  final double strokeWidth;

  const _OctagonBorderPainter({
    required this.cut,
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final c = cut;
    final path = Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OctagonBorderPainter old) =>
      old.cut != cut || old.color != color;
}

// ─── Perk Icon ────────────────────────────────────────────────────────────────

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
    final categoryColor = AppTheme.primary;
    final cut = size * 0.14;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        boxShadow: showCategoryGlow
            ? [BoxShadow(color: categoryColor.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 0)]
            : null,
      ),
      child: ClipPath(
        clipper: _OctagonClipper(cut: cut),
        child: Stack(
          children: [
            // subtle category-tinted background
            Container(color: categoryColor.withValues(alpha: 0.08)),
            // icon image: local asset → network URL → letter fallback
            Hero(
              tag: 'perk_icon_${perk.id}',
              child: _PerkImage(perk: perk, size: size, fallback: _fallbackIcon(categoryColor)),
            ),
            // octagonal border overlay
            CustomPaint(
              size: Size(size, size),
              painter: _OctagonBorderPainter(
                cut: cut,
                color: categoryColor.withValues(alpha: 0.55),
                strokeWidth: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(Color categoryColor) {
    return Container(
      color: categoryColor.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          perk.name[0],
          style: TextStyle(
            color: categoryColor.withValues(alpha: 0.8),
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
        fit: BoxFit.cover,
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
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      cacheWidth: cacheSize,
      cacheHeight: cacheSize,
      errorBuilder: (_, __, ___) => Image.asset(
        idFile,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (_, __, ___) => _networkFallback(cacheSize),
      ),
    );
  }
}

// ─── Perk Card ────────────────────────────────────────────────────────────────

class PerkCard extends StatefulWidget {
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
  State<PerkCard> createState() => _PerkCardState();
}

class _PerkCardState extends State<PerkCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.primary;
    final borderAccent = widget.isSelected
        ? AppTheme.primary
        : _hovered
            ? AppTheme.primary.withValues(alpha: 0.45)
            : AppTheme.border;
    final borderWidth = widget.isSelected ? 1.5 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered && !widget.isSelected ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGlow.withValues(alpha: 0.22),
                          AppTheme.surfaceElevated,
                        ],
                      )
                    : AppTheme.surfaceGradient,
                border: Border(
                  left: BorderSide(color: categoryColor, width: 3),
                  top: BorderSide(color: borderAccent, width: borderWidth),
                  right: BorderSide(color: borderAccent, width: borderWidth),
                  bottom: BorderSide(color: borderAccent, width: borderWidth),
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGlow,
                          blurRadius: 14,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : _hovered
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGlow,
                              blurRadius: 12,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
              ),
              child: widget.compact ? _buildCompact() : _buildFull(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          PerkIcon(perk: widget.perk, size: 52, showCategoryGlow: widget.isSelected),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.perk.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.perk.character,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PerkIcon(perk: widget.perk, size: 70, showCategoryGlow: widget.isSelected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.perk.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.perk.character,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
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
      height: 88,
      filledBorderColor: AppTheme.primary.withValues(alpha: 0.4),
      emptyIcon: Icons.add,
      emptyIconSize: 18,
      emptyLabel: 'Perk ${index + 1}',
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perk!.character,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 16, color: AppTheme.textDim),
                    ),
                  ),
              ],
            ),
    );
  }
}
