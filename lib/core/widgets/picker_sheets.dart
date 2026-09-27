import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'design_system.dart';

// ─── Adaptive sheet ───────────────────────────────────────────────────────────
// Bottom sheet on phones, centered panel on wide screens — a full-width sheet
// on a desktop monitor is awkward to reach and read.

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 560,
}) {
  if (AppLayout.isCompact(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(32),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: builder(ctx),
      ),
    ),
  );
}

/// Height budget for scrollable sheet content.
double sheetHeight(BuildContext context, {double fraction = 0.85, double max = 720}) =>
    math.min(MediaQuery.sizeOf(context).height * fraction, max);

/// Title row used at the top of sheets: drag handle (phones), title, close.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SheetHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 10 : 18, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compact)
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.borderHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Row(
            children: [
              DiamondMark(size: 8, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(fontSize: 20, letterSpacing: 1.2),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Picker Sheet Layout ──────────────────────────────────────────────────────
// Shared layout used by ItemPickerSheet and OfferingPickerSheet: header,
// search, category chips and a scrollable list.

class PickerSheetLayout extends StatefulWidget {
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

  @override
  State<PickerSheetLayout> createState() => _PickerSheetLayoutState();
}

class _PickerSheetLayoutState extends State<PickerSheetLayout> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sheetHeight(context),
      child: Column(
        children: [
          SheetHeader(title: widget.title ?? widget.searchHint.replaceAll('...', '')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(hint: widget.searchHint, onChanged: widget.onSearch),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = widget.categories[i];
                return AppChip(
                  label: c.$2,
                  selected: widget.selectedCategory == c.$1,
                  onTap: () => widget.onCategoryChanged(c.$1),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(child: widget.listBuilder(_scroll)),
        ],
      ),
    );
  }
}

/// Selectable row inside pickers: leading visual, title, subtitle, check.
class PickerRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final bool selected;
  final VoidCallback onTap;

  const PickerRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppPanel(
        onTap: onTap,
        selected: selected,
        cut: 7,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppFonts.body(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!.toUpperCase(),
                      style: AppFonts.caption(color: subtitleColor, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
