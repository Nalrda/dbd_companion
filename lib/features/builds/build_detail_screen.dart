import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/build.dart';
import '../../core/models/item.dart';
import '../../core/models/offering.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/item_repository.dart';
import '../../core/repositories/offering_repository.dart';
import '../../core/repositories/perk_repository.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class BuildDetailScreen extends ConsumerWidget {
  final String buildId;

  const BuildDetailScreen({super.key, required this.buildId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildsAsync = ref.watch(buildsProvider);

    return buildsAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (builds) {
        Build? build;
        try {
          build = builds.firstWhere((b) => b.id == buildId);
        } catch (_) {
          return const Scaffold(
              body: Center(child: Text('Build not found')));
        }

        return _BuildDetailView(build: build);
      },
    );
  }
}

class _BuildDetailView extends StatefulWidget {
  final Build build;
  const _BuildDetailView({required this.build});

  @override
  State<_BuildDetailView> createState() => _BuildDetailViewState();
}

class _BuildDetailViewState extends State<_BuildDetailView> {
  List<Perk> _perks = [];
  Item? _item;
  Offering? _offering;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final perks =
        await PerkRepository.instance.getPerksByIds(widget.build.perkIds);
    final item = widget.build.itemId != null
        ? await ItemRepository.instance.getById(widget.build.itemId!)
        : null;
    final offering = widget.build.offeringId != null
        ? await OfferingRepository.instance.getById(widget.build.offeringId!)
        : null;
    if (mounted) {
      setState(() {
        _perks = perks;
        _item = item;
        _offering = offering;
      });
    }
  }

  void _showShareSheet(BuildContext context) {
    final code = BuildShareService.encode(widget.build);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            const Text(
              'Share Build',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Copy the code below and send it to another player.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DbdButton(
                label: 'Copy Code',
                icon: Icons.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Build code copied to clipboard')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.build.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share build',
            onPressed: () => _showShareSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/builds/${widget.build.id}/edit'),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.build.isSurvivor
                            ? Icons.person
                            : Icons.sports_kabaddi,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.build.isSurvivor ? 'Survivor' : 'Killer',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const SectionHeader(title: 'PERKS'),
                const SizedBox(height: 12),

                if (_perks.isEmpty && widget.build.perkIds.isNotEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (widget.build.perkIds.isEmpty)
                  const Text(
                    'No perks added to this build.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  ..._perks.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PerkCard(perk: e.value),
                      ).animate().fadeIn(delay: (e.key * 50).ms).slideY(begin: 0.04, end: 0)),

                // Item (survivor only)
                if (widget.build.isSurvivor && _item != null) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'ITEM'),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.backpack_outlined,
                    label: _item!.name,
                    badge: _item!.rarity,
                  ),
                ],

                // Add-ons (killer only)
                if (!widget.build.isSurvivor &&
                    ((widget.build.addon1?.isNotEmpty ?? false) ||
                        (widget.build.addon2?.isNotEmpty ?? false))) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'ADD-ONS'),
                  const SizedBox(height: 10),
                  if (widget.build.addon1?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _InfoRow(
                        icon: Icons.extension_outlined,
                        label: widget.build.addon1!,
                      ),
                    ),
                  if (widget.build.addon2?.isNotEmpty ?? false)
                    _InfoRow(
                      icon: Icons.extension_outlined,
                      label: widget.build.addon2!,
                    ),
                ],

                // Offering
                if (_offering != null) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'OFFERING'),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.local_fire_department_outlined,
                    label: _offering!.name,
                    badge: _offering!.rarity,
                  ),
                ],

                if (widget.build.notes != null &&
                    widget.build.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'NOTES'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      widget.build.notes!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                if (widget.build.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'TAGS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.build.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper widget ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;

  const _InfoRow({required this.icon, required this.label, this.badge});

  static Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'uncommon':   return const Color(0xFFFFD700);
      case 'rare':       return const Color(0xFF4CAF50);
      case 'very_rare':  return const Color(0xFF9C27B0);
      case 'ultra_rare': return const Color(0xFFE91E63);
      default:           return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (badge != null && badge != 'none')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _rarityColor(badge!).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _rarityColor(badge!).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                badge!.replaceAll('_', ' '),
                style: TextStyle(
                  color: _rarityColor(badge!),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
