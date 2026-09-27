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
    case 'ultra_rare': return const Color(0xFF8FA3AD);
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
      height: 60,
      filledBorderColor: AppTheme.border,
      emptyIcon: Icons.local_fire_department_outlined,
      emptyLabel: 'Choose Offering',
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      filledContent: offering == null
          ? const SizedBox()
          : Row(
              children: [
                SquareGlyph(
                  icon: offeringCategoryIcon(offering.category),
                  color: offeringRarityColor(offering.rarity),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        offering.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (offeringRarityLabel(offering.rarity).isNotEmpty)
                        Text(
                          offeringRarityLabel(offering.rarity).toUpperCase(),
                          style: AppFonts.caption(color: offeringRarityColor(offering.rarity), fontSize: 11),
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
      title: 'Choose Offering',
      searchHint: 'Search offerings...',
      searchValue: _search,
      onSearch: (v) => setState(() => _search = v),
      categories: _categories,
      selectedCategory: _selectedCategory,
      onCategoryChanged: (v) => setState(() => _selectedCategory = v),
      listBuilder: (controller) => offeringsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(e),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final o = list[i];
              return PickerRow(
                leading: SquareGlyph(
                  icon: offeringCategoryIcon(o.category),
                  color: offeringRarityColor(o.rarity),
                  size: 38,
                ),
                title: o.name,
                subtitle: o.rarity != 'none' ? offeringRarityLabel(o.rarity) : null,
                subtitleColor: offeringRarityColor(o.rarity),
                selected: widget.selectedId == o.id,
                onTap: () => widget.onSelect(o),
              );
            },
          );
        },
      ),
    );
  }
}
