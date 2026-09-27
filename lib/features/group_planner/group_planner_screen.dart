import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/models/group_plan.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'group_plan_editor_screen.dart' show squadColors;

class GroupPlannerScreen extends ConsumerWidget {
  const GroupPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final compact = AppLayout.isCompact(context);
    final plansAsync = ref.watch(groupPlansProvider);
    final perksById = {
      for (final p in ref.watch(allPerksProvider).valueOrNull ?? const <Perk>[]) p.id: p,
    };
    final count = plansAsync.valueOrNull?.length;

    return Scaffold(
      floatingActionButton: compact
          ? AppFab(label: l10n.createGroupPlan, onPressed: () => _createPlan(context, ref))
          : null,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              title: l10n.groupPlannerTitle,
              subtitle: count != null
                  ? '$count squad ${count == 1 ? 'plan' : 'plans'}'
                  : null,
              actions: [
                AppIconButton(
                  icon: Icons.download_outlined,
                  tooltip: 'Import group plan',
                  onPressed: () => _showImportDialog(context, ref),
                ),
                if (!compact)
                  AppButton(
                    label: l10n.createGroupPlan,
                    icon: Icons.add,
                    compact: true,
                    onPressed: () => _createPlan(context, ref),
                  ),
              ],
            ),
            Expanded(
              child: plansAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(e),
                data: (plans) {
                  if (plans.isEmpty) {
                    return EmptyState(
                      icon: Icons.groups_outlined,
                      title: l10n.noGroupPlansYet,
                      subtitle: l10n.planBuildsForSquad,
                      action: AppButton(
                        label: l10n.createGroupPlan,
                        icon: Icons.add,
                        onPressed: () => _createPlan(context, ref),
                      ),
                    );
                  }
                  return _list(context, ref, plans, perksById);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    List<GroupPlan> plans,
    Map<String, Perk> perksById,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = pagePadding(context, top: 4, bottom: 96);
        Widget itemAt(int i) {
          final plan = plans[i];
          return _GroupPlanCard(
            plan: plan,
            squad: List.generate(
              4,
              (si) => plan.getPerkIdsForSurvivor(si).map((id) => perksById[id]).toList(),
            ),
            onTap: () => context.push('/group/${plan.id}'),
            onShare: () => _copyCode(context, plan),
            onDelete: () => _confirmDelete(context, ref, plan),
          ).entrance(i);
        }

        final wide = constraints.maxWidth > 760;
        return ContentWidth(
          child: wide
              ? GridView.builder(
                  padding: pad,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 540,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 152,
                  ),
                  itemCount: plans.length,
                  itemBuilder: (_, i) => itemAt(i),
                )
              : ListView.separated(
                  padding: pad,
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => itemAt(i),
                ),
        );
      },
    );
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final code = await showAppTextPrompt(
      context,
      title: 'Import group plan',
      message: 'Paste a group plan code shared by a squad member.',
      hint: 'DBDG:...',
      confirmLabel: 'Import',
      maxLines: 3,
    );
    if (code == null || !context.mounted) return;
    final imported = BuildShareService.decodeGroupPlan(code);
    if (imported == null) {
      showAppSnack(context, 'Invalid group plan code', error: true);
      return;
    }
    final plan = await ref.read(groupPlansProvider.notifier).importPlan(imported);
    if (context.mounted) context.push('/group/${plan.id}');
  }

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    final name = await showAppTextPrompt(
      context,
      title: 'New group plan',
      hint: 'e.g. Ranked SWF, Fun build...',
      confirmLabel: 'Create',
    );
    if (name == null || !context.mounted) return;
    final plan = await ref.read(groupPlansProvider.notifier).create(name: name);
    if (context.mounted) context.push('/group/${plan.id}');
  }

  void _copyCode(BuildContext context, GroupPlan plan) {
    Clipboard.setData(ClipboardData(text: BuildShareService.encodeGroupPlan(plan)));
    showAppSnack(context, 'Group plan code copied to clipboard');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, GroupPlan plan) async {
    final ok = await showAppConfirm(
      context,
      title: 'Delete group plan?',
      message: '"${plan.name}" will be removed permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) ref.read(groupPlansProvider.notifier).delete(plan.id);
  }
}

// ─── Group plan card ──────────────────────────────────────────────────────────

class _GroupPlanCard extends StatelessWidget {
  final GroupPlan plan;

  /// Resolved perks per survivor (unknown ids resolve to null).
  final List<List<Perk?>> squad;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _GroupPlanCard({
    required this.plan,
    required this.squad,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final filled = squad.fold<int>(0, (sum, s) => sum + s.length.clamp(0, 4));
    final meta = '$filled/16 perks  ·  ${_ago(plan.updatedAt)}';

    Widget survivor(int i) => _SquadMember(index: i, perks: squad[i]);

    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(fontSize: 18, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_horiz, size: 20, color: AppTheme.textTertiary),
                onSelected: (v) {
                  if (v == 'open') onTap();
                  if (v == 'share') onShare();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'open', child: Text('Open')),
                  const PopupMenuItem(value: 'share', child: Text('Copy share code')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: AppFonts.body(color: AppTheme.danger)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: survivor(0)),
                  const SizedBox(width: 14),
                  Expanded(child: survivor(1)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: survivor(2)),
                  const SizedBox(width: 14),
                  Expanded(child: survivor(3)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
  }
}

/// One survivor in the card preview: colored marker, "S1" and four diamonds.
class _SquadMember extends StatelessWidget {
  final int index;
  final List<Perk?> perks;

  const _SquadMember({required this.index, required this.perks});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DiamondMark(size: 6, color: squadColors[index]),
        const SizedBox(width: 7),
        SizedBox(
          width: 18,
          child: Text(
            'S${index + 1}',
            style: AppFonts.caption(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: PerkDiamondRow(perks: perks, size: 28),
          ),
        ),
      ],
    );
  }
}
