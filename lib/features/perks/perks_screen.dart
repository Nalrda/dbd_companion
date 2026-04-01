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
  final _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Perk> _filter(List<Perk> all) {
    final q = _search.toLowerCase().trim();
    return all.where((p) {
      final matchRole = p.isSurvivor == _isSurvivor;
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.character.toLowerCase().contains(q);
      return matchRole && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allPerksAsync = ref.watch(allPerksProvider);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: _searchVisible
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Szukaj po nazwie, postaci...',
                      hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  )
                : PageHeader.text('Perki'),
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
          Expanded(child: allPerksAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primary)),
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
                  onChanged: (v) => setState(() => _isSurvivor = v),
                ),
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
                  ],
                ),
              ),
              // Perk list
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(search: _search)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // 2 columns on wide screens
                          if (constraints.maxWidth > 700) {
                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 8,
                                mainAxisExtent: 96,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => PerkCard(perk: filtered[i]),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PerkCard(perk: filtered[i]),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      )),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String search;
  const _EmptyState({required this.search});

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
            if (search.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nie znaleziono perku dla "$search"',
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
