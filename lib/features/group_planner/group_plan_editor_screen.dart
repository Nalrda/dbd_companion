import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/addon.dart';
import '../../core/models/group_plan.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/addon_repository.dart';
import '../../core/repositories/group_plan_repository.dart';
import '../../core/repositories/item_repository.dart';
import '../../core/repositories/perk_repository.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_system.dart';
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
  // addon ids per survivor [survivorIndex][0=addon1, 1=addon2]
  final List<List<String?>> _survivorAddonIds = List.generate(4, (_) => List.filled(2, null));
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
          _survivorAddonIds[i][0] = plan.getAddon1IdForSurvivor(i);
          _survivorAddonIds[i][1] = plan.getAddon2IdForSurvivor(i);
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
      _plan!.setAddon1IdForSurvivor(i, _survivorAddonIds[i][0]);
      _plan!.setAddon2IdForSurvivor(i, _survivorAddonIds[i][1]);
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
          setState(() {
            _survivorItemIds[survivorIndex] = item.id == 'no_item' ? null : item.id;
            _survivorAddonIds[survivorIndex][0] = null;
            _survivorAddonIds[survivorIndex][1] = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _pickAddon(int survivorIndex, int addonSlot) async {
    final itemId = _survivorItemIds[survivorIndex];
    if (itemId == null) return;
    final item = await ItemRepository.instance.getById(itemId);
    if (item == null || !mounted) return;

    final excludeId = addonSlot == 0
        ? _survivorAddonIds[survivorIndex][1]
        : _survivorAddonIds[survivorIndex][0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddonPickerSheet(
        itemCategory: item.category,
        excludeId: excludeId,
        selectedId: _survivorAddonIds[survivorIndex][addonSlot],
        onSelect: (addon) {
          setState(() => _survivorAddonIds[survivorIndex][addonSlot] = addon.id);
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_plan?.name ?? 'Group Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share plan',
            onPressed: _plan != null ? () => _showShareSheet(context) : null,
          ),
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
              child: Text('Save',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: AppBackground(
        orbs: AppBackground.defaultOrbs(),
        child: _buildBody(),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final code = BuildShareService.encodeGroupPlan(_plan!);
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
            Text(
              'Share Group Plan',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Copy the code below and send it to your squad.',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
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
                    const SnackBar(content: Text('Group plan code copied to clipboard')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    if (isWide) {
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
                    addon1Id: _survivorAddonIds[si][0],
                    addon2Id: _survivorAddonIds[si][1],
                    onSlotTap: (slotIndex) => _pickPerk(si, slotIndex),
                    onSlotRemove: (slotIndex) => setState(
                      () => _resolvedPerks[si][slotIndex] = null,
                    ),
                    onItemTap: () => _pickItem(si),
                    onItemRemove: _survivorItemIds[si] != null
                        ? () => setState(() {
                              _survivorItemIds[si] = null;
                              _survivorAddonIds[si][0] = null;
                              _survivorAddonIds[si][1] = null;
                            })
                        : null,
                    onOfferingTap: () => _pickOffering(si),
                    onOfferingRemove: _survivorOfferingIds[si] != null
                        ? () => setState(() => _survivorOfferingIds[si] = null)
                        : null,
                    onAddon1Tap: () => _pickAddon(si, 0),
                    onAddon1Remove: _survivorAddonIds[si][0] != null
                        ? () => setState(() => _survivorAddonIds[si][0] = null)
                        : null,
                    onAddon2Tap: () => _pickAddon(si, 1),
                    onAddon2Remove: _survivorAddonIds[si][1] != null
                        ? () => setState(() => _survivorAddonIds[si][1] = null)
                        : null,
                  ),
                ),
              )),
            ),
          ),
        ),
      );
    }

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
            addon1Id: _survivorAddonIds[si][0],
            addon2Id: _survivorAddonIds[si][1],
            onSlotTap: (slotIndex) => _pickPerk(si, slotIndex),
            onSlotRemove: (slotIndex) => setState(
              () => _resolvedPerks[si][slotIndex] = null,
            ),
            onItemTap: () => _pickItem(si),
            onItemRemove: _survivorItemIds[si] != null
                ? () => setState(() {
                      _survivorItemIds[si] = null;
                      _survivorAddonIds[si][0] = null;
                      _survivorAddonIds[si][1] = null;
                    })
                : null,
            onOfferingTap: () => _pickOffering(si),
            onOfferingRemove: _survivorOfferingIds[si] != null
                ? () => setState(() => _survivorOfferingIds[si] = null)
                : null,
            onAddon1Tap: () => _pickAddon(si, 0),
            onAddon1Remove: _survivorAddonIds[si][0] != null
                ? () => setState(() => _survivorAddonIds[si][0] = null)
                : null,
            onAddon2Tap: () => _pickAddon(si, 1),
            onAddon2Remove: _survivorAddonIds[si][1] != null
                ? () => setState(() => _survivorAddonIds[si][1] = null)
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
  final String? addon1Id;
  final String? addon2Id;
  final ValueChanged<int> onSlotTap;
  final ValueChanged<int> onSlotRemove;
  final VoidCallback onItemTap;
  final VoidCallback? onItemRemove;
  final VoidCallback onOfferingTap;
  final VoidCallback? onOfferingRemove;
  final VoidCallback onAddon1Tap;
  final VoidCallback? onAddon1Remove;
  final VoidCallback onAddon2Tap;
  final VoidCallback? onAddon2Remove;

  const _SurvivorColumn({
    required this.survivorIndex,
    required this.color,
    required this.label,
    required this.perkSlots,
    required this.itemId,
    required this.offeringId,
    this.addon1Id,
    this.addon2Id,
    required this.onSlotTap,
    required this.onSlotRemove,
    required this.onItemTap,
    this.onItemRemove,
    required this.onOfferingTap,
    this.onOfferingRemove,
    required this.onAddon1Tap,
    this.onAddon1Remove,
    required this.onAddon2Tap,
    this.onAddon2Remove,
  });

  @override
  Widget build(BuildContext context) {
    final filledCount = perkSlots.whereType<Perk>().length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      '${survivorIndex + 1}',
                      style: GoogleFonts.outfit(
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
                    style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$filledCount/4',
                  style: GoogleFonts.outfit(
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
                    style: GoogleFonts.outfit(
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

          // Add-on slots (visible when item selected)
          if (itemId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'ADD-ONS',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _CompactAddonSlot(
                    addonId: addon1Id,
                    label: 'Add-on 1',
                    accentColor: color,
                    onTap: onAddon1Tap,
                    onRemove: onAddon1Remove,
                  ),
                  const SizedBox(height: 6),
                  _CompactAddonSlot(
                    addonId: addon2Id,
                    label: 'Add-on 2',
                    accentColor: color,
                    onTap: onAddon2Tap,
                    onRemove: onAddon2Remove,
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
                    style: GoogleFonts.outfit(
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
    ).animate().fadeIn(delay: (survivorIndex * 60).ms).slideY(begin: 0.05, end: 0);
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
            color: perk != null ? accentColor.withValues(alpha: 0.3) : AppTheme.border,
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
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textDim),
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
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          perk!.character,
                          style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary),
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
                  style: GoogleFonts.outfit(
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
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
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

// ─── Compact Addon Slot ───────────────────────────────────────────────────────

class _CompactAddonSlot extends StatefulWidget {
  final String? addonId;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _CompactAddonSlot({
    required this.addonId,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.onRemove,
  });

  @override
  State<_CompactAddonSlot> createState() => _CompactAddonSlotState();
}

class _CompactAddonSlotState extends State<_CompactAddonSlot> {
  Addon? _addon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_CompactAddonSlot old) {
    super.didUpdateWidget(old);
    if (old.addonId != widget.addonId) _load();
  }

  Future<void> _load() async {
    if (widget.addonId == null) {
      if (mounted) setState(() => _addon = null);
      return;
    }
    final a = await AddonRepository.instance.getById(widget.addonId!);
    if (mounted) setState(() => _addon = a);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _addon != null ? AppTheme.surfaceElevated : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _addon != null
                ? widget.accentColor.withValues(alpha: 0.3)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.extension_outlined,
                size: 14,
                color: _addon != null ? widget.accentColor : AppTheme.textDim),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _addon?.name ?? widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _addon != null ? AppTheme.textPrimary : AppTheme.textDim,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_addon != null && widget.onRemove != null)
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.close, size: 12, color: AppTheme.textDim),
              )
            else
              const Icon(Icons.add, size: 13, color: AppTheme.textDim),
          ],
        ),
      ),
    );
  }
}

// ─── Addon Picker Sheet ───────────────────────────────────────────────────────

class _AddonPickerSheet extends StatefulWidget {
  final String itemCategory;
  final String? selectedId;
  final String? excludeId;
  final ValueChanged<Addon> onSelect;

  const _AddonPickerSheet({
    required this.itemCategory,
    required this.selectedId,
    required this.onSelect,
    this.excludeId,
  });

  @override
  State<_AddonPickerSheet> createState() => _AddonPickerSheetState();
}

class _AddonPickerSheetState extends State<_AddonPickerSheet> {
  String _search = '';
  List<Addon> _addons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AddonRepository.instance.getItemAddons(widget.itemCategory).then((list) {
      if (mounted) setState(() { _addons = list; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose Add-on',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search add-ons...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Builder(builder: (_) {
                    final filtered = _addons.where((a) {
                      if (a.id == widget.excludeId) return false;
                      return _search.isEmpty ||
                          a.name.toLowerCase().contains(_search.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No add-ons available',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      );
                    }

                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final addon = filtered[i];
                        final isSelected = addon.id == widget.selectedId;
                        final rarityColor = AppTheme.rarityColor(addon.rarity);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => widget.onSelect(addon),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryDim.withValues(alpha: 0.3)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.extension_outlined,
                                      size: 16, color: rarityColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(addon.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: rarityColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color: rarityColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      addon.rarity.replaceAll('_', ' '),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: rarityColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(Icons.check_circle,
                                          size: 16, color: AppTheme.primary),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
