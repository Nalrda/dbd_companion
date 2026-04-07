import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/models/group_plan.dart';
import '../../core/providers/providers.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/design_system.dart';

class GroupPlannerScreen extends ConsumerWidget {
  const GroupPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(groupPlansProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _GlowFAB(
        onPressed: () => _createPlan(context, ref),
      ),
      body: AppBackground(
        orbs: [
          BackgroundOrb(
            color: AppTheme.primary,
            opacity: 0.16,
            position: Alignment.bottomRight,
            size: 380,
          ),
        ],
        child: Column(
          children: [
            PageHeader(
              title: PageHeader.text(
                  AppLocalizations.of(context)!.groupPlannerTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  color: AppTheme.textSecondary,
                  tooltip: 'Import group plan',
                  onPressed: () => _showImportDialog(context, ref),
                ),
              ],
            ),
            Expanded(
              child: plansAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (plans) {
                  if (plans.isEmpty) {
                    return EmptyState(
                      icon: Icons.groups_outlined,
                      title: AppLocalizations.of(context)!.noGroupPlansYet,
                      subtitle:
                          AppLocalizations.of(context)!.planBuildsForSquad,
                      action: DbdButton(
                        label:
                            AppLocalizations.of(context)!.createGroupPlan,
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
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 100,
                          ),
                          itemCount: plans.length,
                          itemBuilder: (ctx, i) => _GroupPlanCard(
                            plan: plans[i],
                            onTap: () =>
                                context.push('/group/${plans[i].id}'),
                            onDelete: () => ref
                                .read(groupPlansProvider.notifier)
                                .delete(plans[i].id),
                          )
                              .animate()
                              .fadeIn(delay: (i * 30).ms)
                              .slideY(begin: 0.05, end: 0),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: plans.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _GroupPlanCard(
                          plan: plans[i],
                          onTap: () =>
                              context.push('/group/${plans[i].id}'),
                          onDelete: () => ref
                              .read(groupPlansProvider.notifier)
                              .delete(plans[i].id),
                        )
                            .animate()
                            .fadeIn(delay: (i * 40).ms)
                            .slideY(begin: 0.05, end: 0),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: 'Import Group Plan',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a group plan code shared by a squad member.',
              style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'DBDG:...'),
            ),
          ],
        ),
        cancelLabel: 'Cancel',
        confirmLabel: 'Import',
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () async {
          final imported =
              BuildShareService.decodeGroupPlan(controller.text);
          if (imported == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid group plan code')),
            );
            return;
          }
          Navigator.pop(ctx);
          final plan = await ref
              .read(groupPlansProvider.notifier)
              .importPlan(imported);
          if (context.mounted) context.push('/group/${plan.id}');
        },
      ),
    );
  }

  void _createPlan(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: 'New Group Plan',
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.outfit(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
              hintText: 'e.g. Ranked SWF, Fun build...'),
        ),
        cancelLabel: 'Cancel',
        confirmLabel: 'Create',
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () async {
          final name = controller.text.trim();
          if (name.isEmpty) return;
          final plan = await ref
              .read(groupPlansProvider.notifier)
              .create(name: name);
          if (ctx.mounted) {
            Navigator.pop(ctx);
            context.push('/group/${plan.id}');
          }
        },
      ),
    );
  }
}

// ─── Group Plan Card ──────────────────────────────────────────────────────────

class _GroupPlanCard extends StatefulWidget {
  final GroupPlan plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GroupPlanCard({
    required this.plan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_GroupPlanCard> createState() => _GroupPlanCardState();
}

class _GroupPlanCardState extends State<_GroupPlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.surfaceElevated : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppTheme.borderHighlight : AppTheme.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.2),
                      AppTheme.primaryDim.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child:
                    Icon(Icons.groups, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.plan.name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(4, (i) {
                        final count =
                            widget.plan.getPerkIdsForSurvivor(i).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 11,
                                  color: AppTheme.textTertiary),
                              const SizedBox(width: 2),
                              Text(
                                '$count/4',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: count == 4
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontWeight: count == 4
                                      ? FontWeight.w600
                                      : FontWeight.normal,
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
                color: AppTheme.backgroundSecondary,
                icon: const Icon(Icons.more_vert,
                    color: AppTheme.textTertiary, size: 20),
                onSelected: (v) {
                  if (v == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: GoogleFonts.outfit(color: AppTheme.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Glowing FAB ─────────────────────────────────────────────────────────────

class _GlowFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _GlowFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
