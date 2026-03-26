import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

// ─── Perks Screen ─────────────────────────────────────────────────────────────

class PerksScreen extends ConsumerStatefulWidget {
  const PerksScreen({super.key});

  @override
  ConsumerState<PerksScreen> createState() => _PerksScreenState();
}

class _PerksScreenState extends ConsumerState<PerksScreen> {
  bool _isSurvivor = true;
  String _search = '';
  String? _selectedCategory;
  final _searchController = TextEditingController();
  bool _searchVisible = false;

  static const _categories = [
    'healing',
    'chase',
    'stealth',
    'generator',
    'support',
    'awareness',
    'endgame',
    'utility',
    'hex',
    'anti-healing',
    'anti-grab',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Perk> _filter(List<Perk> all) {
    final q = _search.toLowerCase().trim();
    return all.where((p) {
      final matchRole = p.isSurvivor == _isSurvivor;
      final matchCat = _selectedCategory == null || p.category == _selectedCategory;
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.character.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      return matchRole && matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allPerksAsync = ref.watch(allPerksProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Szukaj po nazwie, postaci, kategorii...',
                  hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : Text(
                'Perki',
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textPrimary,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _searchVisible ? Icons.close : Icons.search,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _search = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: allPerksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Błąd: $e', style: const TextStyle(color: AppTheme.textSecondary))),
        data: (allPerks) {
          final filtered = _filter(allPerks);
          return Column(
            children: [
              // Role toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: RoleToggle(
                  isSurvivor: _isSurvivor,
                  onChanged: (v) => setState(() {
                    _isSurvivor = v;
                    _selectedCategory = null;
                  }),
                ),
              ),
              // Category filter chips
              _CategoryFilterBar(
                selected: _selectedCategory,
                categories: _categories,
                onSelect: (cat) => setState(() {
                  _selectedCategory = _selectedCategory == cat ? null : cat;
                }),
              ),
              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} perk${filtered.length == 1 ? '' : 'ów'}',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(width: 8),
                      _CategoryBadge(category: _selectedCategory!),
                    ],
                  ],
                ),
              ),
              // Perk list
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(search: _search, category: _selectedCategory)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PerkCard(perk: filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Category Filter Bar ──────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  final String? selected;
  final List<String> categories;
  final ValueChanged<String> onSelect;

  const _CategoryFilterBar({
    required this.selected,
    required this.categories,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final visible = categories;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = visible[i];
          final isActive = cat == selected;
          final color = AppTheme.perkCategoryColor(cat);
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.18) : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? color.withValues(alpha: 0.7) : AppTheme.border,
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                _label(cat),
                style: GoogleFonts.rajdhani(
                  color: isActive ? color : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _label(String cat) {
    switch (cat) {
      case 'anti-healing': return 'Anti-Healing';
      case 'anti-grab':    return 'Anti-Grab';
      default:             return cat[0].toUpperCase() + cat.substring(1);
    }
  }
}

// ─── Category Badge ───────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.perkCategoryColor(category);
    final label = category[0].toUpperCase() + category.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String search;
  final String? category;
  const _EmptyState({required this.search, required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: AppTheme.textDim, size: 48),
            const SizedBox(height: 16),
            Text(
              'Brak wyników',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            if (search.isNotEmpty || category != null) ...[
              const SizedBox(height: 8),
              Text(
                search.isNotEmpty
                    ? 'Nie znaleziono perku dla "$search"'
                    : 'Brak perków w tej kategorii',
                style: const TextStyle(color: AppTheme.textDim, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
