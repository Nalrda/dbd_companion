import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/group_plan.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/group_plan_repository.dart';
import '../../core/repositories/perk_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class GroupPlanEditorScreen extends ConsumerStatefulWidget {
  final String planId;
  const GroupPlanEditorScreen({super.key, required this.planId});

  @override
  ConsumerState<GroupPlanEditorScreen> createState() => _GroupPlanEditorScreenState();
}

class _GroupPlanEditorScreenState extends ConsumerState<GroupPlanEditorScreen> {
  GroupPlan? _plan;
  List<Perk> _allPerks = [];
  // resolved perks per slot: _resolvedPerks[survivorIndex][slotIndex]
  final List<List<Perk?>> _resolvedPerks = List.generate(4, (_) => List.filled(4, null));
  // item id per survivor
  final List<String?> _survivorItemIds = List.filled(4, null);
  // offering id per survivor
  final List<String?> _survivorOfferingIds = List.filled(4, null);
  bool _loading = true;

  static const List<Color> _survivorColors = [
    Color(0xFF4FC3F7), // blue
    Color(0xFF81C784), // green
    Color(0xFFFFB74D), // orange
    Color(0xFFBA68C8), // purple
  ];

  static const List<String> _survivorLabels = [
    'Survivor 1', 'Survivor 2', 'Survivor 3', 'Survivor 4'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plan = await GroupPlanRepository.instance.getById(widget.planId);
    final perks = await PerkRepository.instance.getSurvivorPerks();

    if (plan == null) return;

    final resolved = List.generate(4, (si) {
      final ids = plan.getPerkIdsForSurvivor(si);
      return List.generate(4, (pi) {
        if (pi < ids.length) {
          try { return perks.firstWhere((p) => p.id == ids[pi]); }
          catch (_) { return null; }
        }
        return null;
      });
    });

    if (mounted) {
      setState(() {
        _plan = plan;
        _allPerks = perks;
        for (int i = 0; i < 4; i++) {
          _resolvedPerks[i] = resolved[i];
          _survivorItemIds[i] = plan.getItemIdForSurvivor(i);
          _survivorOfferingIds[i] = plan.getOfferingIdForSurvivor(i);
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_plan == null) return;
    for (int i = 0; i < 4; i++) {
      _plan!.setPerkIdsForSurvivor(
        i,
        _resolvedPerks[i].whereType<Perk>().map((p) => p.id).toList(),
      );
      _plan!.setItemIdForSurvivor(i, _survivorItemIds[i]);
      _plan!.setOfferingIdForSurvivor(i, _survivorOfferingIds[i]);
    }
    await GroupPlanRepository.instance.save(_plan!);
    ref.invalidate(groupPlansProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group plan saved!')),
      );
    }
  }

  void _pickItem(int survivorIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ItemPickerSheet(
        selectedId: _survivorItemIds[survivorIndex],
        onSelect: (item) {
          setState(() => _survivorItemIds[survivorIndex] =
              item.id == 'no_item' ? null : item.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _pickOffering(int survivorIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => OfferingPickerSheet(
        selectedId: _survivorOfferingIds[survivorIndex],
        isSurvivor: true,
        onSelect: (offering) {
          setState(() => _survivorOfferingIds[survivorIndex] =
              offering.id == 'no_offering' ? null : offering.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _pickPerk(int survivorIndex, int slotIndex) {
    final usedIds = _resolvedPerks
        .expand((slots) => slots)
        .whereType<Perk>()
        .map((p) => p.id)
        .toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PerkPickerSheet(
        perks: _allPerks,
        usedIds: usedIds,
        survivorColor: _survivorColors[survivorIndex],
        survivorLabel: _survivorLabels[survivorIndex],
        onSelect: (perk) {
          setState(() => _resolvedPerks[survivorIndex][slotIndex] = perk);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan?.name ?? 'Group Plan'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    if (isWide) {
      // Wide layout: 4 columns side by side, centered with max width
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(4, (si) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: si < 3 ? 12 : 0),
                  child: _SurvivorColumn(
                    survivorIndex: si,
                    color: _survivorColors[si],
                    label: _survivorLabels[si],
                    perkSlots: _resolvedPerks[si],
                    itemId: _survivorItemIds[si],
                    offeringId: _survivorOfferingIds[si],
                    onSlotTap: (slotIndex) => _pickPerk(si, slotIndex),
                    onSlotRemove: (slotIndex) => setState(
                      () => _resolvedPerks[si][slotIndex] = null,
                    ),
                    onItemTap: () => _pickItem(si),
                    onItemRemove: _survivorItemIds[si] != null
                        ? () => setState(() => _survivorItemIds[si] = null)
                        : null,
                    onOfferingTap: () => _pickOffering(si),
                    onOfferingRemove: _survivorOfferingIds[si] != null
                        ? () => setState(() => _survivorOfferingIds[si] = null)
                        : null,
                  ),
                ),
              )),
            ),
          ),
        ),
      );
    }

    // Narrow layout: scrollable list of columns
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(4, (si) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _SurvivorColumn(
            survivorIndex: si,
            color: _survivorColors[si],
            label: _survivorLabels[si],
            perkSlots: _resolvedPerks[si],
            itemId: _survivorItemIds[si],
            offeringId: _survivorOfferingIds[si],
            onSlotTap: (slotIndex) => _pickPerk(si, slotIndex),
            onSlotRemove: (slotIndex) => setState(
              () => _resolvedPerks[si][slotIndex] = null,
            ),
            onItemTap: () => _pickItem(si),
            onItemRemove: _survivorItemIds[si] != null
                ? () => setState(() => _survivorItemIds[si] = null)
                : null,
            onOfferingTap: () => _pickOffering(si),
            onOfferingRemove: _survivorOfferingIds[si] != null
                ? () => setState(() => _survivorOfferingIds[si] = null)
                : null,
          ),
        )),
      ),
    );
  }
}

// ─── Survivor Column ──────────────────────────────────────────────────────────

class _SurvivorColumn extends StatelessWidget {
  final int survivorIndex;
  final Color color;
  final String label;
  final List<Perk?> perkSlots;
  final String? itemId;
  final String? offeringId;
  final ValueChanged<int> onSlotTap;
  final ValueChanged<int> onSlotRemove;
  final VoidCallback onItemTap;
  final VoidCallback? onItemRemove;
  final VoidCallback onOfferingTap;
  final VoidCallback? onOfferingRemove;

  const _SurvivorColumn({
    required this.survivorIndex,
    required this.color,
    required this.label,
    required this.perkSlots,
    required this.itemId,
    required this.offeringId,
    required this.onSlotTap,
    required this.onSlotRemove,
    required this.onItemTap,
    this.onItemRemove,
    required this.onOfferingTap,
    this.onOfferingRemove,
  });

  @override
  Widget build(BuildContext context) {
    final filledCount = perkSlots.whereType<Perk>().length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: color.withValues(alpha:0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha:0.5)),
                  ),
                  child: Center(
                    child: Text(
                      '${survivorIndex + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$filledCount/4',
                  style: TextStyle(
                    color: filledCount == 4 ? color : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: filledCount == 4 ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Perk slots
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: List.generate(4, (slotIndex) {
                final perk = perkSlots[slotIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompactPerkSlot(
                    perk: perk,
                    slotIndex: slotIndex,
                    accentColor: color,
                    onTap: () => onSlotTap(slotIndex),
                    onRemove: perk != null ? () => onSlotRemove(slotIndex) : null,
                  ),
                );
              }),
            ),
          ),

          // Item slot
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'ITEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ItemSlot(
                  selectedItemId: itemId,
                  onTap: onItemTap,
                  onRemove: onItemRemove,
                ),
              ],
            ),
          ),

          // Offering slot
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'OFFERING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                OfferingSlot(
                  selectedOfferingId: offeringId,
                  isSurvivor: true,
                  onTap: onOfferingTap,
                  onRemove: onOfferingRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (survivorIndex * 60).ms).slideY(begin: 0.03, end: 0);
  }
}

// ─── Compact Perk Slot ────────────────────────────────────────────────────────

class _CompactPerkSlot extends StatelessWidget {
  final Perk? perk;
  final int slotIndex;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _CompactPerkSlot({
    required this.perk,
    required this.slotIndex,
    required this.accentColor,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: perk != null ? AppTheme.surfaceElevated : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: perk != null ? accentColor.withValues(alpha:0.3) : AppTheme.border,
          ),
        ),
        child: perk == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 14, color: AppTheme.textDim),
                  const SizedBox(width: 4),
                  Text(
                    'Perk ${slotIndex + 1}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDim),
                  ),
                ],
              )
            : Row(
                children: [
                  PerkIcon(perk: perk!, size: 36),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perk!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          perk!.character,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(Icons.close, size: 14, color: AppTheme.textDim),
                    ),
                ],
              ),
      ),
    );
  }
}

// ─── Perk Picker Sheet ────────────────────────────────────────────────────────

class _PerkPickerSheet extends StatefulWidget {
  final List<Perk> perks;
  final Set<String> usedIds;
  final Color survivorColor;
  final String survivorLabel;
  final ValueChanged<Perk> onSelect;

  const _PerkPickerSheet({
    required this.perks,
    required this.usedIds,
    required this.survivorColor,
    required this.survivorLabel,
    required this.onSelect,
  });

  @override
  State<_PerkPickerSheet> createState() => _PerkPickerSheetState();
}

class _PerkPickerSheetState extends State<_PerkPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.perks.where((p) {
      if (_search.isEmpty) return true;
      return p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.character.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: widget.survivorColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pick perk for ${widget.survivorLabel}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search perks...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final perk = filtered[i];
                final isUsed = widget.usedIds.contains(perk.id);
                return Opacity(
                  opacity: isUsed ? 0.35 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PerkCard(
                      perk: perk,
                      compact: true,
                      onTap: isUsed ? null : () => widget.onSelect(perk),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
