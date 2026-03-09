import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/build.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class BuildsScreen extends ConsumerStatefulWidget {
  const BuildsScreen({super.key});

  @override
  ConsumerState<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends ConsumerState<BuildsScreen> {
  bool _showSurvivor = true;

  @override
  Widget build(BuildContext context) {
    final buildsAsync = ref.watch(buildsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Builds'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: RoleToggle(
              isSurvivor: _showSurvivor,
              onChanged: (v) => setState(() => _showSurvivor = v),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/builds/create?survivor=$_showSurvivor'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: buildsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (builds) {
          final filtered =
              builds.where((b) => b.isSurvivor == _showSurvivor).toList();

          if (filtered.isEmpty) {
            return EmptyState(
              icon: Icons.build_outlined,
              title: 'No builds yet',
              subtitle: _showSurvivor
                  ? 'Create your first survivor build'
                  : 'Create your first killer build',
              action: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/builds/create?survivor=$_showSurvivor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Build'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _BuildListItem(
                item: filtered[index],
                onTap: () =>
                    context.push('/builds/${filtered[index].id}'),
                onDelete: () => _confirmDelete(filtered[index]),
              ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.05, end: 0);
            },
          );
        },
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
            child: const Text('Delete',
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

  const _BuildListItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.perkIds.length}/4 perks',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: item.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
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
            PopupMenuButton<String>(
              color: AppTheme.surfaceElevated,
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textDim, size: 20),
              onSelected: (v) {
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
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
