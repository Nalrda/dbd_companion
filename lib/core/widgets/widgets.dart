import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/perk.dart';
import '../theme/app_theme.dart';

// ─── Perk Icon ────────────────────────────────────────────────────────────────

class PerkIcon extends StatelessWidget {
  final Perk perk;
  final double size;

  const PerkIcon({super.key, required this.perk, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AppTheme.rarityColor(perk.rarity);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: rarityColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18),
        child: perk.iconUrl != null
            ? Image.network(
                perk.iconUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(rarityColor),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _fallbackIcon(rarityColor);
                },
              )
            : _fallbackIcon(rarityColor),
      ),
    );
  }

  Widget _fallbackIcon(Color rarityColor) {
    return Container(
      color: rarityColor.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          perk.name[0],
          style: TextStyle(
            color: rarityColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
          ),
        ),
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
    final rarityColor = AppTheme.rarityColor(perk.rarity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryDim.withValues(alpha: 0.3)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: compact ? _buildCompact(rarityColor) : _buildFull(rarityColor),
      ),
    );
  }

  Widget _buildCompact(Color rarityColor) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          PerkIcon(perk: perk, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  perk.character,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: rarityColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildFull(Color rarityColor) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PerkIcon(perk: perk, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        perk.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        perk.rarity.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: rarityColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  perk.character,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  perk.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
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
    final isEmpty = perk == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: isEmpty ? AppTheme.surface : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEmpty ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: isEmpty
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: AppTheme.textDim, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Perk ${index + 1}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDim),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    PerkIcon(perk: perk!, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            perk!.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            perk!.character,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
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
              ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppTheme.border)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
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
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'Survivor', isActive: isSurvivor, onTap: () => onChanged(true)),
          _Tab(label: 'Killer', isActive: !isSurvivor, onTap: () => onChanged(false)),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondary,
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
            Icon(icon, size: 48, color: AppTheme.textDim),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
