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
      height: 60,
      filledBorderColor: AppTheme.border,
      emptyIcon: Icons.backpack_outlined,
      emptyLabel: 'Choose Item',
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      filledContent: item == null
          ? const SizedBox()
          : Row(
              children: [
                ItemIcon(item: item, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        itemCategoryLabel(item.category).toUpperCase(),
                        style: AppFonts.caption(color: itemCategoryColor(item.category), fontSize: 11),
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
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(e),
        data: (items) {
          final filtered = items.where((i) {
            final matchSearch = _search.isEmpty ||
                i.name.toLowerCase().contains(_search.toLowerCase());
            final matchCat = _filter == 'all' || i.category == _filter;
            return matchSearch && matchCat;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text('No items found', style: AppFonts.body(color: AppTheme.textTertiary)),
            );
          }
          return ListView.builder(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final item = filtered[i];
              return PickerRow(
                leading: ItemIcon(item: item, size: 38),
                title: item.name,
                subtitle: item.rarity.replaceAll('_', ' '),
                subtitleColor: AppTheme.rarityColor(item.rarity),
                selected: item.id == widget.selectedId,
                onTap: () => widget.onSelect(item),
              );
            },
          );
        },
      ),
    );
  }
}
