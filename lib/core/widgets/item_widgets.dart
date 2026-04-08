import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';
import 'picker_sheets.dart';

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
    return BaseSlot(
      isEmpty: item == null,
      height: 64,
      filledBorderColor: item != null
          ? itemCategoryColor(item.category).withValues(alpha: 0.5)
          : AppTheme.border,
      emptyIcon: Icons.backpack_outlined,
      emptyLabel: 'Choose Item',
      onTap: onTap,
      filledContent: item == null
          ? const SizedBox()
          : Row(
              children: [
                ItemIcon(item: item, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        itemCategoryLabel(item.category),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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

    return PickerSheetLayout(
      title: 'Choose Item',
      searchHint: 'Search items...',
      searchValue: _search,
      onSearch: (v) => setState(() => _search = v),
      categories: _categories,
      selectedCategory: _filter,
      onCategoryChanged: (v) => setState(() => _filter = v),
      listBuilder: (controller) => itemsAsync.when(
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
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                item.rarity.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(fontSize: 10, color: rarityColor),
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
