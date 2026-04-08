import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Picker Sheet Layout ──────────────────────────────────────────────────────
// Shared DraggableScrollableSheet layout used by ItemPickerSheet and
// OfferingPickerSheet. Provides handle, optional title, search field,
// category chips and an Expanded area for the item list.

class PickerSheetLayout extends StatelessWidget {
  final String? title;
  final String searchHint;
  final String searchValue;
  final ValueChanged<String> onSearch;
  final List<(String, String)> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final Widget Function(ScrollController controller) listBuilder;

  const PickerSheetLayout({
    super.key,
    this.title,
    required this.searchHint,
    required this.searchValue,
    required this.onSearch,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.listBuilder,
  });

  Widget _chip(String id, String label) {
    final isActive = selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onCategoryChanged(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: categories.map((c) => _chip(c.$1, c.$2)).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: onSearch,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search, color: AppTheme.textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: listBuilder(controller)),
        ],
      ),
    );
  }
}
