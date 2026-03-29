import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/killer.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class KillersScreen extends ConsumerStatefulWidget {
  const KillersScreen({super.key});

  @override
  ConsumerState<KillersScreen> createState() => _KillersScreenState();
}

class _KillersScreenState extends ConsumerState<KillersScreen> {
  String _search = '';
  bool _searchVisible = false;
  String? _filterDifficulty;
  final _searchController = TextEditingController();

  static const _difficulties = ['easy', 'intermediate', 'hard', 'very hard'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final killersAsync = ref.watch(killersProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search killers...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textDim),
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : const Text('Killers'),
        actions: [
          IconButton(
            icon: Icon(
              _searchVisible ? Icons.close : Icons.search,
              color: _searchVisible ? AppTheme.primary : AppTheme.textSecondary,
            ),
            onPressed: () => setState(() {
              _searchVisible = !_searchVisible;
              if (!_searchVisible) {
                _search = '';
                _searchController.clear();
              }
            }),
          ),
          PopupMenuButton<String?>(
            color: AppTheme.surfaceElevated,
            icon: Icon(
              Icons.filter_list,
              color: _filterDifficulty != null
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
            ),
            onSelected: (v) => setState(() => _filterDifficulty = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('All difficulties',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ..._difficulties.map(
                (d) => PopupMenuItem(
                  value: d,
                  child: Text(
                    _capitalize(d),
                    style: TextStyle(color: _difficultyColor(d)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: killersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (killers) {
          var filtered = killers;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((k) =>
                    k.name.toLowerCase().contains(q) ||
                    k.alias.toLowerCase().contains(q) ||
                    k.power.toLowerCase().contains(q))
                .toList();
          }
          if (_filterDifficulty != null) {
            filtered = filtered
                .where((k) => k.difficulty == _filterDifficulty)
                .toList();
          }

          if (filtered.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No killers found',
              subtitle: 'Try a different search or filter',
            );
          }

          return LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 100,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _KillerTile(
                  killer: filtered[i],
                  onTap: () => context.push('/killers/${filtered[i].id}'),
                ).animate().fadeIn(delay: (i * 25).ms).slideY(begin: 0.04, end: 0),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _KillerTile(
                killer: filtered[i],
                onTap: () => context.push('/killers/${filtered[i].id}'),
              ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.04, end: 0),
            );
          });
        },
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

Color _difficultyColor(String difficulty) {
  switch (difficulty) {
    case 'easy': return const Color(0xFF3E9E44);
    case 'intermediate': return AppTheme.primary;
    case 'hard': return AppTheme.accent;
    case 'very hard': return const Color(0xFF8B35D6);
    default: return AppTheme.textSecondary;
  }
}

// ─── Killer tile ──────────────────────────────────────────────────────────────

class _KillerTile extends StatelessWidget {
  final Killer killer;
  final VoidCallback onTap;

  const _KillerTile({required this.killer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(killer.difficulty);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryDim.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  killer.name.replaceFirst('The ', '')[0],
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    killer.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    killer.power,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: diffColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _capitalize(killer.difficulty),
                      style: TextStyle(
                        fontSize: 10,
                        color: diffColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textDim, size: 20),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
