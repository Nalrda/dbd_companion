import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/offering.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'picker_sheets.dart';

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

    return BaseSlot(
      isEmpty: offering == null,
      height: 64,
      filledBorderColor: offering != null
          ? offeringRarityColor(offering.rarity).withValues(alpha: 0.5)
          : AppTheme.border,
      emptyIcon: Icons.card_giftcard_outlined,
      emptyLabel: 'Choose Offering',
      onTap: onTap,
      filledContent: offering == null
          ? const SizedBox()
          : Row(
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
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: AppTheme.textDim),
                    ),
                  ),
              ],
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

    return PickerSheetLayout(
      searchHint: 'Search offerings...',
      searchValue: _search,
      onSearch: (v) => setState(() => _search = v),
      categories: _categories,
      selectedCategory: _selectedCategory,
      onCategoryChanged: (v) => setState(() => _selectedCategory = v),
      listBuilder: (controller) => offeringsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (offerings) {
          final filtered = offerings.where((o) {
            if (_selectedCategory != 'all' && o.category != _selectedCategory) {
              return false;
            }
            if (_search.isNotEmpty &&
                !o.name.toLowerCase().contains(_search.toLowerCase())) {
              return false;
            }
            return true;
          }).toList();

          // no_offering first
          final noOff = offerings.where((o) => o.id == 'no_offering').firstOrNull;
          final list = [
            if (noOff != null && _selectedCategory == 'all' && _search.isEmpty) noOff,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryDim : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : offeringRarityColor(o.rarity).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: offeringRarityColor(o.rarity).withValues(alpha: 0.15),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: offeringRarityColor(o.rarity),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
