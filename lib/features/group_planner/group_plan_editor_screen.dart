import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../core/widgets/widgets.dart';

/// Identity colors for the four squad members (used as small markers only).
const List<Color> squadColors = [
  Color(0xFF4FC3F7), // blue
  Color(0xFF81C784), // green
  Color(0xFFFFB74D), // orange
  Color(0xFFBA68C8), // purple
];

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

  // Phone layout: which survivor is shown.
  int _current = 0;
  bool _switching = false;
  final _pages = PageController();

  static const List<String> _survivorLabels = [
    'Survivor 1', 'Survivor 2', 'Survivor 3', 'Survivor 4'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
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
    if (mounted) showAppSnack(context, 'Group plan saved');
  }

  void _pickItem(int survivorIndex) {
    showAppSheet(
      context,
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

    showAppSheet(
      context,
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
    showAppSheet(
      context,
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
    // Perks already taken anywhere in the squad, and by whom.
    final usedBy = <String, int>{
      for (var si = 0; si < 4; si++)
        for (final p in _resolvedPerks[si].whereType<Perk>()) p.id: si,
    };

    showAppSheet(
      context,
      builder: (ctx) => _PerkPickerSheet(
        perks: _allPerks,
        usedBy: usedBy,
        survivorIndex: survivorIndex,
        survivorLabel: _survivorLabels[survivorIndex],
        onSelect: (perk) {
          setState(() => _resolvedPerks[survivorIndex][slotIndex] = perk);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final code = BuildShareService.encodeGroupPlan(_plan!);
    showAppSheet(
      context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(
              title: 'Share group plan',
              subtitle: 'Copy the code below and send it to your squad.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: AppPanel(
                cut: 8,
                color: AppTheme.background.withValues(alpha: 0.6),
                padding: const EdgeInsets.all(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      code,
                      style: AppFonts.body(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: AppButton(
                label: 'Copy code',
                icon: Icons.copy,
                expand: true,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Group plan code copied to clipboard');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToSurvivor(int i) {
    setState(() => _current = i);
    if (!_pages.hasClients) return;
    _switching = true;
    _pages
        .animateToPage(i, duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic)
        .whenComplete(() => _switching = false);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: AppBackground(child: LoadingView()));
    }

    final compact = AppLayout.isCompact(context);
    final filled = _resolvedPerks.expand((s) => s).whereType<Perk>().length;
    final items = _survivorItemIds.whereType<String>().length;
    final offerings = _survivorOfferingIds.whereType<String>().length;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              showBack: true,
              onBack: () => context.canPop() ? context.pop() : context.go('/group'),
              title: _plan?.name ?? 'Group Plan',
              subtitle: compact
                  ? '$filled/16 perks  ·  $items/4 items'
                  : '$filled/16 perks  ·  $items/4 items  ·  $offerings/4 offerings',
              actions: [
                AppIconButton(
                  icon: Icons.ios_share_outlined,
                  tooltip: 'Share plan',
                  onPressed: _plan != null ? () => _showShareSheet(context) : null,
                ),
                AppButton(
                  label: 'Save',
                  icon: compact ? null : Icons.check,
                  compact: true,
                  onPressed: _save,
                ),
              ],
              bottom: compact ? _squadSwitcher() : null,
            ),
            Expanded(child: compact ? _phoneBody() : _wideBody()),
          ],
        ),
      ),
    );
  }

  /// Phone: four tabs that double as a squad overview (marker + perk diamonds).
  Widget _squadSwitcher() {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _SquadTab(
              index: i,
              perks: _resolvedPerks[i],
              selected: i == _current,
              onTap: () => _goToSurvivor(i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _phoneBody() {
    return PageView.builder(
      controller: _pages,
      itemCount: 4,
      onPageChanged: (i) {
        if (!_switching) setState(() => _current = i);
      },
      itemBuilder: (context, si) => SingleChildScrollView(
        padding: pagePadding(context, top: 2, bottom: 32),
        child: _survivorPanel(si),
      ),
    );
  }

  Widget _wideBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = pagePadding(context, top: 4, bottom: 32);
        final inner = constraints.maxWidth.clamp(0, AppLayout.contentMax) - pad.horizontal;
        final fourUp = inner >= 940;
        const gap = 12.0;

        Widget row(List<int> indices) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final si in indices) ...[
                    if (si != indices.first) const SizedBox(width: gap),
                    Expanded(child: _survivorPanel(si, dense: fourUp).entrance(si, step: 50)),
                  ],
                ],
              ),
            );

        return ContentWidth(
          child: SingleChildScrollView(
            padding: pad,
            child: fourUp
                ? row(const [0, 1, 2, 3])
                : Column(
                    children: [
                      row(const [0, 1]),
                      const SizedBox(height: gap),
                      row(const [2, 3]),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _survivorPanel(int si, {bool dense = false}) {
    return _SurvivorPanel(
      survivorIndex: si,
      color: squadColors[si],
      label: _survivorLabels[si],
      dense: dense,
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
    );
  }
}

// ─── Squad tab (phone switcher) ───────────────────────────────────────────────

class _SquadTab extends StatelessWidget {
  final int index;
  final List<Perk?> perks;
  final bool selected;
  final VoidCallback onTap;

  const _SquadTab({
    required this.index,
    required this.perks,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Survivor ${index + 1}',
      child: AppPanel(
        onTap: onTap,
        selected: selected,
        cut: 7,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DiamondMark(size: 6, color: squadColors[index]),
                const SizedBox(width: 6),
                Text(
                  'S${index + 1}',
                  style: AppFonts.display(
                    fontSize: 15,
                    letterSpacing: 1.2,
                    color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: PerkDiamondRow(perks: perks, size: 15, spacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Survivor panel ───────────────────────────────────────────────────────────

class _SurvivorPanel extends StatelessWidget {
  final int survivorIndex;
  final Color color;
  final String label;

  /// Narrow column (four-up desktop layout): smaller perk icons, tighter padding.
  final bool dense;
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

  const _SurvivorPanel({
    required this.survivorIndex,
    required this.color,
    required this.label,
    this.dense = false,
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
    final hasItem = itemId != null;
    const cut = 10.0;

    return AppPanel(
      cut: cut,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(dense ? 12 : 14, 16, dense ? 12 : 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    DiamondMark(size: 8, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.display(fontSize: 18, letterSpacing: 1.3),
                      ),
                    ),
                    Text(
                      '$filledCount/4',
                      style: AppFonts.display(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: filledCount == 4 ? AppTheme.textPrimary : AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Perks
                const _FieldLabel('Perks'),
                for (var slotIndex = 0; slotIndex < 4; slotIndex++) ...[
                  if (slotIndex > 0) const SizedBox(height: 6),
                  _SquadPerkSlot(
                    perk: perkSlots[slotIndex],
                    slotIndex: slotIndex,
                    dense: dense,
                    onTap: () => onSlotTap(slotIndex),
                    onRemove: perkSlots[slotIndex] != null ? () => onSlotRemove(slotIndex) : null,
                  ),
                ],
                const SizedBox(height: 16),

                // Item
                const _FieldLabel('Item'),
                ItemSlot(
                  selectedItemId: itemId,
                  onTap: onItemTap,
                  onRemove: onItemRemove,
                ),
                const SizedBox(height: 16),

                // Add-ons (need an item first)
                _FieldLabel('Add-ons', hint: hasItem ? null : 'Pick an item first'),
                _AddonSlot(
                  addonId: addon1Id,
                  label: 'Add-on 1',
                  enabled: hasItem,
                  onTap: onAddon1Tap,
                  onRemove: onAddon1Remove,
                ),
                const SizedBox(height: 6),
                _AddonSlot(
                  addonId: addon2Id,
                  label: 'Add-on 2',
                  enabled: hasItem,
                  onTap: onAddon2Tap,
                  onRemove: onAddon2Remove,
                ),
                const SizedBox(height: 16),

                // Offering
                const _FieldLabel('Offering'),
                OfferingSlot(
                  selectedOfferingId: offeringId,
                  isSurvivor: true,
                  onTap: onOfferingTap,
                  onRemove: onOfferingRemove,
                ),
              ],
            ),
          ),
          // Thin identity edge along the top.
          Positioned(
            top: 0,
            left: cut + 2,
            right: 0,
            height: 2,
            child: ColoredBox(color: color.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final String? hint;
  const _FieldLabel(this.text, {this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: AppFonts.caption()),
          if (hint != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppFonts.body(fontSize: 11.5, color: AppTheme.textTertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Perk slot (squad variant) ────────────────────────────────────────────────

class _SquadPerkSlot extends StatelessWidget {
  final Perk? perk;
  final int slotIndex;
  final bool dense;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SquadPerkSlot({
    required this.perk,
    required this.slotIndex,
    required this.dense,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = perk;
    return BaseSlot(
      isEmpty: p == null,
      height: dense ? 58 : 64,
      filledBorderColor: AppTheme.border,
      emptyIcon: Icons.add,
      emptyLabel: 'Perk ${slotIndex + 1}',
      contentPadding: const EdgeInsets.fromLTRB(6, 4, 0, 4),
      onTap: onTap,
      animate: true,
      filledContent: p == null
          ? const SizedBox()
          : Row(
              children: [
                PerkIcon(perk: p, size: dense ? 46 : 54),
                SizedBox(width: dense ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.name,
                        maxLines: dense ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          fontSize: dense ? 13.5 : 15,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        p.character,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null) SlotRemoveButton(onPressed: onRemove!),
              ],
            ),
    );
  }
}

// ─── Add-on slot ──────────────────────────────────────────────────────────────

class _AddonSlot extends StatefulWidget {
  final String? addonId;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _AddonSlot({
    required this.addonId,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.onRemove,
  });

  @override
  State<_AddonSlot> createState() => _AddonSlotState();
}

class _AddonSlotState extends State<_AddonSlot> {
  Addon? _addon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AddonSlot old) {
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
    final addon = _addon;
    final rarityColor = addon != null ? AppTheme.rarityColor(addon.rarity) : AppTheme.textTertiary;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: widget.enabled ? 1 : 0.45,
      child: BaseSlot(
        isEmpty: addon == null,
        height: 50,
        filledBorderColor: AppTheme.border,
        emptyIcon: Icons.extension_outlined,
        emptyLabel: widget.label,
        contentPadding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
        onTap: widget.enabled ? widget.onTap : null,
        filledContent: addon == null
            ? const SizedBox()
            : Row(
                children: [
                  SquareGlyph(icon: Icons.extension_outlined, color: rarityColor, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          addon.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.body(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          addon.rarity.replaceAll('_', ' ').toUpperCase(),
                          maxLines: 1,
                          style: AppFonts.caption(color: rarityColor, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onRemove != null) SlotRemoveButton(onPressed: widget.onRemove!),
                ],
              ),
      ),
    );
  }
}

// ─── Perk picker sheet ────────────────────────────────────────────────────────

class _PerkPickerSheet extends StatefulWidget {
  final List<Perk> perks;

  /// Perk id → index of the survivor that already runs it.
  final Map<String, int> usedBy;
  final int survivorIndex;
  final String survivorLabel;
  final ValueChanged<Perk> onSelect;

  const _PerkPickerSheet({
    required this.perks,
    required this.usedBy,
    required this.survivorIndex,
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
    final q = _search.toLowerCase();
    final filtered = widget.perks.where((p) {
      if (_search.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.character.toLowerCase().contains(q);
    }).toList();

    return SizedBox(
      height: sheetHeight(context),
      child: Column(
        children: [
          SheetHeader(
            title: 'Pick perk',
            subtitle: 'For ${widget.survivorLabel}',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Search perks...',
              autofocus: true,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No perks found', style: AppFonts.body(color: AppTheme.textTertiary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final perk = filtered[i];
                      final owner = widget.usedBy[perk.id];
                      final isUsed = owner != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: isUsed ? 0.4 : 1,
                              child: PerkCard(
                                perk: perk,
                                compact: true,
                                onTap: isUsed ? null : () => widget.onSelect(perk),
                              ),
                            ),
                            if (isUsed)
                              Positioned(
                                right: 14,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: AppTag('In use · S${owner + 1}', color: squadColors[owner]),
                                ),
                              ),
                          ],
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

// ─── Add-on picker sheet ──────────────────────────────────────────────────────

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
    return SizedBox(
      height: sheetHeight(context, fraction: 0.75),
      child: Column(
        children: [
          SheetHeader(title: 'Choose add-on', subtitle: itemCategoryLabel(widget.itemCategory)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Search add-ons...',
              autofocus: true,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: _loading
                ? const LoadingView()
                : Builder(builder: (_) {
                    final filtered = _addons.where((a) {
                      if (a.id == widget.excludeId) return false;
                      return _search.isEmpty ||
                          a.name.toLowerCase().contains(_search.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No add-ons available',
                          style: AppFonts.body(color: AppTheme.textTertiary),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final addon = filtered[i];
                        final rarityColor = AppTheme.rarityColor(addon.rarity);
                        return PickerRow(
                          leading: SquareGlyph(
                            icon: Icons.extension_outlined,
                            color: rarityColor,
                            size: 38,
                          ),
                          title: addon.name,
                          subtitle: addon.rarity.replaceAll('_', ' '),
                          subtitleColor: rarityColor,
                          selected: addon.id == widget.selectedId,
                          onTap: () => widget.onSelect(addon),
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
