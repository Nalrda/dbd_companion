import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/group_plan.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class GroupPlannerScreen extends ConsumerWidget {
  const GroupPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(groupPlansProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createPlan(context, ref),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          PageHeader(title: PageHeader.text('Group Planner')),
          Expanded(child: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (plans) {
          if (plans.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: 'No group plans yet',
              subtitle: 'Plan builds for your full 4-survivor squad',
              action: DbdButton(
                label: 'Create Group Plan',
                icon: Icons.add,
                onPressed: () => _createPlan(context, ref),
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
                    mainAxisExtent: 100,
                  ),
                  itemCount: plans.length,
                  itemBuilder: (ctx, i) => _GroupPlanCard(
                    plan: plans[i],
                    onTap: () => context.push('/group/${plans[i].id}'),
                    onDelete: () => ref.read(groupPlansProvider.notifier).delete(plans[i].id),
                  ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.05, end: 0),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _GroupPlanCard(
                  plan: plans[i],
                  onTap: () => context.push('/group/${plans[i].id}'),
                  onDelete: () => ref.read(groupPlansProvider.notifier).delete(plans[i].id),
                ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.05, end: 0),
              );
            },
          );
        },
      )),
        ],
      ),
    );
  }

  void _createPlan(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('New Group Plan', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. Ranked SWF, Fun build...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final plan = await ref.read(groupPlansProvider.notifier).create(name: name);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                // ignore: use_build_context_synchronously
                context.push('/group/${plan.id}');
              }
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _GroupPlanCard extends StatelessWidget {
  final GroupPlan plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupPlanCard({required this.plan, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.groups, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 4 survivor perk count indicators
                  Row(
                    children: List.generate(4, (i) {
                      final count = plan.getPerkIdsForSurvivor(i).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 11, color: AppTheme.textDim),
                            const SizedBox(width: 2),
                            Text(
                              '$count/4',
                              style: TextStyle(
                                fontSize: 11,
                                color: count == 4 ? AppTheme.primary : AppTheme.textSecondary,
                                fontWeight: count == 4 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: AppTheme.surfaceElevated,
              icon: const Icon(Icons.more_vert, color: AppTheme.textDim, size: 20),
              onSelected: (v) { if (v == 'delete') onDelete(); },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
