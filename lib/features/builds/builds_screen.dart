import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/build.dart';
import '../../core/providers/providers.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class BuildsScreen extends ConsumerStatefulWidget {
  const BuildsScreen({super.key});

  @override
  ConsumerState<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends ConsumerState<BuildsScreen> {
  bool _showSurvivor = true;
  bool _showFavoritesOnly = false;
  String _search = '';
  bool _searchVisible = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildsAsync = ref.watch(buildsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/builds/create?survivor=$_showSurvivor'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          PageHeader(
            title: _searchVisible
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search builds...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.textDim),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  )
                : PageHeader.text('My Builds'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_outlined),
                color: AppTheme.textSecondary,
                tooltip: 'Import build',
                onPressed: _showImportDialog,
              ),
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
              IconButton(
                icon: Icon(
                  _showFavoritesOnly ? Icons.star : Icons.star_outline,
                  color: _showFavoritesOnly ? AppTheme.primary : AppTheme.textSecondary,
                ),
                tooltip: 'Favorites only',
                onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: RoleToggle(
                  isSurvivor: _showSurvivor,
                  onChanged: (v) => setState(() => _showSurvivor = v),
                ),
              ),
            ],
          ),
          Expanded(
            child: buildsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (builds) {
          var filtered = builds.where((b) => b.isSurvivor == _showSurvivor).toList();

          if (_showFavoritesOnly) {
            filtered = filtered.where((b) => b.isFavorite).toList();
          }

          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((b) =>
                    b.name.toLowerCase().contains(q) ||
                    b.tags.any((t) => t.toLowerCase().contains(q)))
                .toList();
          }

          // Favorites always at top
          filtered.sort((a, b) {
            if (a.isFavorite && !b.isFavorite) return -1;
            if (!a.isFavorite && b.isFavorite) return 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });

          if (filtered.isEmpty) {
            return EmptyState(
              icon: _showFavoritesOnly
                  ? Icons.star_outline
                  : _search.isNotEmpty
                      ? Icons.search_off
                      : Icons.build_outlined,
              title: _showFavoritesOnly
                  ? 'No favorites yet'
                  : _search.isNotEmpty
                      ? 'No results'
                      : 'No builds yet',
              subtitle: _showFavoritesOnly
                  ? 'Star a build to add it here'
                  : _search.isNotEmpty
                      ? 'Try a different search'
                      : _showSurvivor
                          ? 'Create your first survivor build'
                          : 'Create your first killer build',
              action: (_showFavoritesOnly || _search.isNotEmpty)
                  ? null
                  : DbdButton(
                      label: 'Create Build',
                      icon: Icons.add,
                      onPressed: () =>
                          context.push('/builds/create?survivor=$_showSurvivor'),
                    ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 110,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _BuildListItem(
                      item: filtered[index],
                      onTap: () => context.push('/builds/${filtered[index].id}'),
                      onDelete: () => _confirmDelete(filtered[index]),
                      onToggleFavorite: () => ref
                          .read(buildsProvider.notifier)
                          .toggleFavorite(filtered[index].id),
                    ).animate().fadeIn(delay: (index * 30).ms).slideY(begin: 0.05, end: 0);
                  },
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _BuildListItem(
                    item: filtered[index],
                    onTap: () => context.push('/builds/${filtered[index].id}'),
                    onDelete: () => _confirmDelete(filtered[index]),
                    onToggleFavorite: () => ref
                        .read(buildsProvider.notifier)
                        .toggleFavorite(filtered[index].id),
                  ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
                },
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

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Import Build',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a build code shared by another player.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'DBD:...',
                hintStyle: TextStyle(color: AppTheme.textDim),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final imported = BuildShareService.decode(controller.text);
              if (imported == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid build code')),
                );
                return;
              }
              Navigator.pop(ctx);
              context.push('/builds/create', extra: imported);
            },
            child: Text('Import', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Build build) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete build?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${build.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(buildsProvider.notifier).delete(build.id);
            },
            child: Text('Delete',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _BuildListItem extends StatelessWidget {
  final Build item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _BuildListItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isFavorite
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(
                item.isSurvivor ? Icons.person : Icons.sports_kabaddi,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.perkIds.length}/4 perks',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: item.tags
                          .take(3)
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.border,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggleFavorite,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  item.isFavorite ? Icons.star : Icons.star_outline,
                  color: item.isFavorite ? AppTheme.primary : AppTheme.textDim,
                  size: 20,
                ),
              ),
            ),
            PopupMenuButton<String>(
              color: AppTheme.surfaceElevated,
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textDim, size: 20),
              onSelected: (v) {
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
