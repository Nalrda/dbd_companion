import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/offering.dart';
import '../models/perk.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

// ─── Perk Icon ────────────────────────────────────────────────────────────────

class PerkIcon extends StatelessWidget {
  final Perk perk;
  final double size;

  const PerkIcon({super.key, required this.perk, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18),
        child: perk.iconUrl != null
            ? Image.network(
                perk.iconUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _fallbackIcon();
                },
              )
            : _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: AppTheme.border.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          perk.name[0],
          style: TextStyle(
            color: AppTheme.textDim,
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
        child: compact ? _buildCompact() : _buildFull(),
      ),
    );
  }

  Widget _buildCompact() {
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
          PerkIcon(perk: perk, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
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

// ─── Item Slot ────────────────────────────────────────────────────────────────

class ItemSlot extends ConsumerWidget {
  final String? selectedItemId;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const ItemSlot({
    super.key,
    required this.selectedItemId,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(survivorItemsProvider);
    return itemsAsync.when(
      loading: () => _buildSlot(null),
      error: (_, __) => _buildSlot(null),
      data: (items) {
        final item = selectedItemId != null
            ? items.firstWhere((i) => i.id == selectedItemId,
                orElse: () => items.first)
            : null;
        return _buildSlot(item);
      },
    );
  }

  Widget _buildSlot(Item? item) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: item != null ? AppTheme.surfaceElevated : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item != null
                ? itemCategoryColor(item.category).withValues(alpha: 0.5)
                : AppTheme.border,
          ),
        ),
        child: item == null
            ? const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.backpack_outlined, color: AppTheme.textDim, size: 16),
                    SizedBox(width: 6),
                    Text('Choose Item',
                        style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    ItemIcon(item: item, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis),
                          Text(itemCategoryLabel(item.category),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    if (onRemove != null)
                      GestureDetector(
                        onTap: onRemove,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 14, color: AppTheme.textDim),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Item Picker Sheet ────────────────────────────────────────────────────────

class ItemPickerSheet extends ConsumerStatefulWidget {
  final String? selectedId;
  final ValueChanged<Item> onSelect;

  const ItemPickerSheet({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  ConsumerState<ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends ConsumerState<ItemPickerSheet> {
  String _search = '';
  String _filter = 'all';

  static const _categories = [
    ('all', 'All'),
    ('medkit', 'Medkit'),
    ('flashlight', 'Flashlight'),
    ('toolbox', 'Toolbox'),
    ('key', 'Key'),
    ('map', 'Map'),
  ];

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(survivorItemsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose Item',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isActive = _filter == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = cat.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primary : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isActive ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text(cat.$2,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : AppTheme.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                final filtered = items.where((i) {
                  final matchSearch = _search.isEmpty ||
                      i.name.toLowerCase().contains(_search.toLowerCase());
                  final matchCat = _filter == 'all' || i.category == _filter;
                  return matchSearch && matchCat;
                }).toList();

                return ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    final isSelected = item.id == widget.selectedId;
                    final rarityColor = AppTheme.rarityColor(item.rarity);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => widget.onSelect(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(10),
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
                          child: Row(
                            children: [
                              ItemIcon(item: item, size: 40),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary)),
                                    Text(
                                      item.rarity.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(fontSize: 10, color: rarityColor),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: rarityColor, shape: BoxShape.circle),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Offering helpers ─────────────────────────────────────────────────────────

Color offeringRarityColor(String rarity) {
  switch (rarity) {
    case 'common':     return const Color(0xFFB0BEC5);
    case 'uncommon':   return const Color(0xFFFFD54F);
    case 'rare':       return const Color(0xFFBA68C8);
    case 'very_rare':  return const Color(0xFFEF5350);
    case 'ultra_rare': return const Color(0xFF37474F);
    default:           return AppTheme.textDim;
  }
}

IconData offeringCategoryIcon(String category) {
  switch (category) {
    case 'bloodpoints': return Icons.monetization_on_outlined;
    case 'map':         return Icons.map_outlined;
    case 'fog':         return Icons.cloud_outlined;
    case 'hook':        return Icons.anchor_outlined;
    case 'chest':       return Icons.inventory_2_outlined;
    case 'mori':        return Icons.sports_kabaddi_outlined;
    case 'escape':      return Icons.directions_run_outlined;
    case 'hatch':       return Icons.door_sliding_outlined;
    default:            return Icons.card_giftcard_outlined;
  }
}

String offeringRarityLabel(String rarity) {
  switch (rarity) {
    case 'common':     return 'Common';
    case 'uncommon':   return 'Uncommon';
    case 'rare':       return 'Rare';
    case 'very_rare':  return 'Very Rare';
    case 'ultra_rare': return 'Ultra Rare';
    default:           return '';
  }
}

// ─── OfferingSlot ─────────────────────────────────────────────────────────────

class OfferingSlot extends ConsumerWidget {
  final String? selectedOfferingId;
  final bool isSurvivor;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const OfferingSlot({
    super.key,
    required this.selectedOfferingId,
    required this.isSurvivor,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = isSurvivor
        ? ref.watch(survivorOfferingsProvider)
        : ref.watch(killerOfferingsProvider);

    final offering = offeringsAsync.whenOrNull(
      data: (list) => selectedOfferingId != null
          ? list.where((o) => o.id == selectedOfferingId).firstOrNull
          : null,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: offering != null ? AppTheme.surfaceElevated : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: offering != null
                ? offeringRarityColor(offering.rarity).withValues(alpha: 0.5)
                : AppTheme.border,
          ),
        ),
        child: offering == null
            ? const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard_outlined, color: AppTheme.textDim, size: 16),
                    SizedBox(width: 6),
                    Text('Choose Offering',
                        style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: offeringRarityColor(offering.rarity).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: offeringRarityColor(offering.rarity).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        offeringCategoryIcon(offering.category),
                        color: offeringRarityColor(offering.rarity),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            offering.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            offeringRarityLabel(offering.rarity),
                            style: TextStyle(
                              fontSize: 11,
                              color: offeringRarityColor(offering.rarity),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onRemove != null)
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(Icons.close, size: 16, color: AppTheme.textDim),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── OfferingPickerSheet ──────────────────────────────────────────────────────

class OfferingPickerSheet extends ConsumerStatefulWidget {
  final String? selectedId;
  final bool isSurvivor;
  final ValueChanged<Offering> onSelect;

  const OfferingPickerSheet({
    super.key,
    required this.selectedId,
    required this.isSurvivor,
    required this.onSelect,
  });

  @override
  ConsumerState<OfferingPickerSheet> createState() => _OfferingPickerSheetState();
}

class _OfferingPickerSheetState extends ConsumerState<OfferingPickerSheet> {
  String _search = '';
  String _selectedCategory = 'all';

  static const _categories = [
    ('all', 'All'),
    ('bloodpoints', 'BP'),
    ('map', 'Map'),
    ('fog', 'Fog'),
    ('hook', 'Hook'),
    ('chest', 'Chest'),
    ('mori', 'Mori'),
    ('escape', 'Escape'),
    ('hatch', 'Hatch'),
  ];

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = widget.isSurvivor
        ? ref.watch(survivorOfferingsProvider)
        : ref.watch(killerOfferingsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              autofocus: false,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search offerings...',
                prefixIcon:
                    Icon(Icons.search, color: AppTheme.textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.$2,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        )),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat.$1),
                    backgroundColor: AppTheme.surfaceElevated,
                    selectedColor: AppTheme.primary,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: offeringsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (offerings) {
                final filtered = offerings.where((o) {
                  if (_selectedCategory != 'all' &&
                      o.category != _selectedCategory) return false;
                  if (_search.isNotEmpty &&
                      !o.name
                          .toLowerCase()
                          .contains(_search.toLowerCase())) return false;
                  return true;
                }).toList();

                // no_offering first
                final noOff = offerings
                    .where((o) => o.id == 'no_offering')
                    .firstOrNull;
                final list = [
                  if (noOff != null && _selectedCategory == 'all' && _search.isEmpty)
                    noOff,
                  ...filtered.where((o) => o.id != 'no_offering'),
                ];

                return ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final o = list[i];
                    final isSelected = widget.selectedId == o.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => widget.onSelect(o),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryDim
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : offeringRarityColor(o.rarity)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: offeringRarityColor(o.rarity)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  offeringCategoryIcon(o.category),
                                  color: offeringRarityColor(o.rarity),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (o.rarity != 'none')
                                      Text(
                                        offeringRarityLabel(o.rarity),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              offeringRarityColor(o.rarity),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: AppTheme.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
