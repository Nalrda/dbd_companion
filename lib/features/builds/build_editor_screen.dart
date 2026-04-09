import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/addon.dart';
import '../../core/models/build.dart';
import '../../core/models/killer.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/addon_repository.dart';
import '../../core/repositories/item_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/widgets.dart';

class BuildEditorScreen extends ConsumerStatefulWidget {
  final String? buildId;
  final bool isSurvivor;
  final List<String>? sharedPerkIds;
  final String? sharedName;
  /// When set, pre-fills all fields from an imported build (ignores other shared* params).
  final Build? sharedBuild;

  const BuildEditorScreen({
    super.key,
    this.buildId,
    this.isSurvivor = true,
    this.sharedPerkIds,
    this.sharedName,
    this.sharedBuild,
  });

  @override
  ConsumerState<BuildEditorScreen> createState() => _BuildEditorScreenState();
}

class _BuildEditorScreenState extends ConsumerState<BuildEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late bool _isSurvivor;
  late List<String?> _perkSlots;
  final List<String> _tags = [];
  String _searchQuery = '';
  int? _editingSlot;
  Build? _existingBuild;
  String? _selectedItemId;
  String? _selectedOfferingId;
  String? _selectedKillerId;
  String? _selectedAddon1Id;
  String? _selectedAddon2Id;

  @override
  void initState() {
    super.initState();
    _perkSlots = List.filled(4, null);

    final imported = widget.sharedBuild;
    if (imported != null) {
      _isSurvivor = imported.isSurvivor;
      _nameController = TextEditingController(text: imported.name);
      _notesController = TextEditingController(text: imported.notes ?? '');
      _selectedItemId = imported.itemId;
      _selectedOfferingId = imported.offeringId;
      _selectedKillerId = imported.killerId;
      _selectedAddon1Id = imported.addon1;
      _selectedAddon2Id = imported.addon2;
      for (int i = 0; i < imported.perkIds.length && i < 4; i++) {
        _perkSlots[i] = imported.perkIds[i];
      }
      _tags.addAll(imported.tags);
    } else {
      _isSurvivor = widget.isSurvivor;
      _nameController = TextEditingController(text: widget.sharedName ?? '');
      _notesController = TextEditingController();
      if (widget.sharedPerkIds != null) {
        for (int i = 0; i < widget.sharedPerkIds!.length && i < 4; i++) {
          _perkSlots[i] = widget.sharedPerkIds![i];
        }
      }
    }

    _loadExistingBuild();
  }

  Future<void> _loadExistingBuild() async {
    if (widget.buildId == null) return;
    final builds = await ref.read(buildsProvider.future);
    final build = builds.firstWhere(
      (b) => b.id == widget.buildId,
      orElse: () => Build(id: '', name: '', isSurvivor: widget.isSurvivor, perkIds: []),
    );
    if (build.id.isEmpty) return;
    setState(() {
      _existingBuild = build;
      _nameController.text = build.name;
      _notesController.text = build.notes ?? '';
      _isSurvivor = build.isSurvivor;
      _selectedItemId = build.itemId;
      _selectedOfferingId = build.offeringId;
      _selectedKillerId = build.killerId;
      _selectedAddon1Id = build.addon1;
      _selectedAddon2Id = build.addon2;
      for (int i = 0; i < build.perkIds.length && i < 4; i++) {
        _perkSlots[i] = build.perkIds[i];
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a build name')),
      );
      return;
    }
    final perkIds = _perkSlots.whereType<String>().toList();

    if (_existingBuild != null) {
      final updated = _existingBuild!.copyWith(
        name: name,
        perkIds: perkIds,
        notes: _notesController.text.trim(),
        tags: _tags,
        itemId: _selectedItemId,
        addon1: _selectedAddon1Id,
        addon2: _selectedAddon2Id,
        offeringId: _selectedOfferingId,
        killerId: _selectedKillerId,
      );
      await ref.read(buildsProvider.notifier).save(updated);
    } else {
      await ref.read(buildsProvider.notifier).create(
        name: name,
        isSurvivor: _isSurvivor,
        perkIds: perkIds,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        tags: _tags,
        itemId: _selectedItemId,
        addon1: _selectedAddon1Id,
        addon2: _selectedAddon2Id,
        offeringId: _selectedOfferingId,
        killerId: _selectedKillerId,
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final perksAsync = _isSurvivor
        ? ref.watch(survivorPerksProvider)
        : ref.watch(killerPerksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_existingBuild == null ? 'New Build' : 'Edit Build'),
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
              child: Text('Save',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
      body: AppBackground(
        orbs: AppBackground.defaultOrbs(),
        child: perksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (perks) => _buildBody(perks),
        ),
      ),
    );
  }

  Widget _buildBody(List<Perk> allPerks) {
    final filtered = allPerks.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.character.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isWide ? 360 : constraints.maxWidth,
              child: _buildLeftPanel(allPerks),
            ),
            if (isWide && _editingSlot != null)
              Expanded(child: _buildPerkPicker(filtered, allPerks)),
          ],
        );
      },
    );
  }

  Widget _buildLeftPanel(List<Perk> allPerks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'Build name...',
              prefixIcon: Icon(Icons.drive_file_rename_outline, color: AppTheme.textDim, size: 18),
            ),
          ),

          const SizedBox(height: 20),
          const SectionHeader(title: 'PERKS'),
          const SizedBox(height: 10),

          ...List.generate(4, (i) {
            final perkId = _perkSlots[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PerkSlot(
                index: i,
                perk: perkId != null ? allPerks.where((p) => p.id == perkId).firstOrNull : null,
                onTap: () => _openPerkPicker(i),
                onRemove: perkId != null ? () => setState(() => _perkSlots[i] = null) : null,
              ),
            );
          }),

          const SizedBox(height: 20),

          if (_isSurvivor) ...[
            const SectionHeader(title: 'ITEM'),
            const SizedBox(height: 10),
            ItemSlot(
              selectedItemId: _selectedItemId,
              onTap: _openItemPicker,
              onRemove: _selectedItemId != null
                  ? () => setState(() {
                        _selectedItemId = null;
                        _selectedAddon1Id = null;
                        _selectedAddon2Id = null;
                      })
                  : null,
            ),
            if (_selectedItemId != null) ...[
              const SizedBox(height: 12),
              const SectionHeader(title: 'ITEM ADD-ONS'),
              const SizedBox(height: 10),
              _AddonSlot(
                label: 'Add-on 1',
                addonId: _selectedAddon1Id,
                onTap: () => _openAddonPicker(slot: 1),
                onRemove: _selectedAddon1Id != null
                    ? () => setState(() => _selectedAddon1Id = null)
                    : null,
              ),
              const SizedBox(height: 8),
              _AddonSlot(
                label: 'Add-on 2',
                addonId: _selectedAddon2Id,
                onTap: () => _openAddonPicker(slot: 2),
                onRemove: _selectedAddon2Id != null
                    ? () => setState(() => _selectedAddon2Id = null)
                    : null,
              ),
            ],
          ] else ...[
            const SectionHeader(title: 'KILLER'),
            const SizedBox(height: 10),
            _KillerSlot(
              selectedKillerId: _selectedKillerId,
              onTap: _openKillerPicker,
              onRemove: _selectedKillerId != null
                  ? () => setState(() {
                        _selectedKillerId = null;
                        _selectedAddon1Id = null;
                        _selectedAddon2Id = null;
                      })
                  : null,
            ),
            if (_selectedKillerId != null) ...[
              const SizedBox(height: 12),
              const SectionHeader(title: 'KILLER ADD-ONS'),
              const SizedBox(height: 10),
              _AddonSlot(
                label: 'Add-on 1',
                addonId: _selectedAddon1Id,
                onTap: () => _openAddonPicker(slot: 1),
                onRemove: _selectedAddon1Id != null
                    ? () => setState(() => _selectedAddon1Id = null)
                    : null,
              ),
              const SizedBox(height: 8),
              _AddonSlot(
                label: 'Add-on 2',
                addonId: _selectedAddon2Id,
                onTap: () => _openAddonPicker(slot: 2),
                onRemove: _selectedAddon2Id != null
                    ? () => setState(() => _selectedAddon2Id = null)
                    : null,
              ),
            ],
          ],

          const SizedBox(height: 20),
          const SectionHeader(title: 'OFFERING'),
          const SizedBox(height: 10),
          OfferingSlot(
            selectedOfferingId: _selectedOfferingId,
            isSurvivor: _isSurvivor,
            onTap: _openOfferingPicker,
            onRemove: _selectedOfferingId != null
                ? () => setState(() => _selectedOfferingId = null)
                : null,
          ),

          const SizedBox(height: 20),
          const SectionHeader(title: 'NOTES'),
          const SizedBox(height: 10),

          TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Build notes, strategy tips...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pickers ──────────────────────────────────────────────────────────────

  void _openItemPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ItemPickerSheet(
        selectedId: _selectedItemId,
        onSelect: (item) {
          setState(() {
            _selectedItemId = item.id == 'no_item' ? null : item.id;
            _selectedAddon1Id = null;
            _selectedAddon2Id = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openKillerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _KillerPickerSheet(
        selectedId: _selectedKillerId,
        onSelect: (killer) {
          setState(() {
            _selectedKillerId = killer.id;
            _selectedAddon1Id = null;
            _selectedAddon2Id = null;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openAddonPicker({required int slot}) async {
    String? sourceKey;
    String sourceType = '';

    if (_isSurvivor && _selectedItemId != null) {
      final item = await ItemRepository.instance.getById(_selectedItemId!);
      sourceKey = item?.category;
      sourceType = 'item';
    } else if (!_isSurvivor && _selectedKillerId != null) {
      sourceKey = _selectedKillerId;
      sourceType = 'killer';
    }
    if (sourceKey == null) return;

    if (!mounted) return;

    final alreadyPicked = slot == 1 ? _selectedAddon2Id : _selectedAddon1Id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddonPickerSheet(
        sourceKey: sourceKey!,
        sourceType: sourceType,
        excludeId: alreadyPicked,
        selectedId: slot == 1 ? _selectedAddon1Id : _selectedAddon2Id,
        onSelect: (addon) {
          setState(() {
            if (slot == 1) {
              _selectedAddon1Id = addon.id;
            } else {
              _selectedAddon2Id = addon.id;
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openOfferingPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => OfferingPickerSheet(
        selectedId: _selectedOfferingId,
        isSurvivor: _isSurvivor,
        onSelect: (offering) {
          setState(() =>
              _selectedOfferingId = offering.id == 'no_offering' ? null : offering.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openPerkPicker(int slot) {
    setState(() => _editingSlot = slot);
    final isWide = MediaQuery.of(context).size.width > 620;
    if (!isWide) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _PerkPickerSheet(
          isSurvivor: _isSurvivor,
          selectedIds: _perkSlots.whereType<String>().toList(),
          onSelect: (perk) {
            setState(() => _perkSlots[slot] = perk.id);
            Navigator.pop(ctx);
          },
        ),
      );
    }
  }

  Widget _buildPerkPicker(List<Perk> filtered, List<Perk> all) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search perks...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textDim, size: 18),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final perk = filtered[index];
                final isUsed = _perkSlots.contains(perk.id);
                return Opacity(
                  opacity: isUsed ? 0.4 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PerkCard(
                      perk: perk,
                      compact: true,
                      onTap: isUsed
                          ? null
                          : () {
                              setState(() {
                                _perkSlots[_editingSlot!] = perk.id;
                                _editingSlot = null;
                              });
                            },
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

// ─── Addon Slot ───────────────────────────────────────────────────────────────

class _AddonSlot extends StatefulWidget {
  final String label;
  final String? addonId;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _AddonSlot({
    required this.label,
    required this.addonId,
    required this.onTap,
    this.onRemove,
  });

  @override
  State<_AddonSlot> createState() => _AddonSlotState();
}

class _AddonSlotState extends State<_AddonSlot> {
  Addon? _addon;

  @override
  void didUpdateWidget(_AddonSlot old) {
    super.didUpdateWidget(old);
    if (old.addonId != widget.addonId) _loadAddon();
  }

  @override
  void initState() {
    super.initState();
    _loadAddon();
  }

  Future<void> _loadAddon() async {
    if (widget.addonId == null) {
      if (mounted) setState(() => _addon = null);
      return;
    }
    final a = await AddonRepository.instance.getById(widget.addonId!);
    if (mounted) setState(() => _addon = a);
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _addon != null
        ? AppTheme.rarityColor(_addon!.rarity)
        : AppTheme.border;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _addon != null ? rarityColor.withValues(alpha: 0.5) : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.extension_outlined,
                size: 18,
                color: _addon != null ? rarityColor : AppTheme.textDim),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _addon?.name ?? widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _addon != null ? AppTheme.textPrimary : AppTheme.textDim,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_addon != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _addon!.rarity.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 10, color: rarityColor, fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.close, size: 14, color: AppTheme.textDim),
                  ),
                ),
            ] else
              const Icon(Icons.add, size: 16, color: AppTheme.textDim),
          ],
        ),
      ),
    );
  }
}

// ─── Killer Slot ──────────────────────────────────────────────────────────────

class _KillerSlot extends ConsumerWidget {
  final String? selectedKillerId;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _KillerSlot({
    required this.selectedKillerId,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final killersAsync = ref.watch(killersProvider);
    return killersAsync.when(
      loading: () => _buildSlot(null),
      error: (_, __) => _buildSlot(null),
      data: (killers) {
        final killer = selectedKillerId != null
            ? killers.firstWhere((k) => k.id == selectedKillerId,
                orElse: () => killers.first)
            : null;
        return _buildSlot(killer);
      },
    );
  }

  Widget _buildSlot(Killer? killer) {
    return BaseSlot(
      isEmpty: killer == null,
      height: 64,
      filledBorderColor: AppTheme.primary.withValues(alpha: 0.4),
      emptyIcon: Icons.sports_kabaddi,
      emptyLabel: 'Choose Killer',
      onTap: onTap,
      filledContent: killer == null
          ? const SizedBox()
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.sports_kabaddi, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        killer.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        killer.power,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: AppTheme.textDim),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─── Killer Picker Sheet ──────────────────────────────────────────────────────

class _KillerPickerSheet extends ConsumerStatefulWidget {
  final String? selectedId;
  final ValueChanged<Killer> onSelect;

  const _KillerPickerSheet({required this.selectedId, required this.onSelect});

  @override
  ConsumerState<_KillerPickerSheet> createState() => _KillerPickerSheetState();
}

class _KillerPickerSheetState extends ConsumerState<_KillerPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final killersAsync = ref.watch(killersProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
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
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Killer',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search killers...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textDim, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: killersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (killers) {
                final filtered = _search.isEmpty
                    ? killers
                    : killers.where((k) =>
                        k.name.toLowerCase().contains(_search.toLowerCase()) ||
                        k.power.toLowerCase().contains(_search.toLowerCase())).toList();

                return ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final killer = filtered[i];
                    final isSelected = killer.id == widget.selectedId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => widget.onSelect(killer),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryDim.withValues(alpha: 0.3)
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryDim.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.sports_kabaddi,
                                    size: 18, color: AppTheme.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      killer.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      killer.power,
                                      style: const TextStyle(
                                          fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    size: 18, color: AppTheme.primary),
                            ],
                          ),
                        ),
                      ),
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
}

// ─── Addon Picker Sheet ───────────────────────────────────────────────────────

class _AddonPickerSheet extends StatefulWidget {
  final String sourceKey;
  final String sourceType; // 'killer' or 'item'
  final String? selectedId;
  final String? excludeId;
  final ValueChanged<Addon> onSelect;

  const _AddonPickerSheet({
    required this.sourceKey,
    required this.sourceType,
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
    _loadAddons();
  }

  Future<void> _loadAddons() async {
    final List<Addon> result;
    if (widget.sourceType == 'killer') {
      result = await AddonRepository.instance.getKillerAddons(widget.sourceKey);
    } else {
      result = await AddonRepository.instance.getItemAddons(widget.sourceKey);
    }
    if (mounted) setState(() { _addons = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
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
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Add-on',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                ),
              ),
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
                      if (_search.isEmpty) return true;
                      return a.name.toLowerCase().contains(_search.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No add-ons found',
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryDim.withValues(alpha: 0.3)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.extension_outlined,
                                      size: 18, color: rarityColor),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      addon.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: rarityColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: rarityColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      addon.rarity.replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: rarityColor,
                                        fontWeight: FontWeight.w600,
                                      ),
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

// ─── Mobile perk picker sheet ─────────────────────────────────────────────────

class _PerkPickerSheet extends ConsumerStatefulWidget {
  final bool isSurvivor;
  final List<String> selectedIds;
  final ValueChanged<Perk> onSelect;

  const _PerkPickerSheet({
    required this.isSurvivor,
    required this.selectedIds,
    required this.onSelect,
  });

  @override
  ConsumerState<_PerkPickerSheet> createState() => _PerkPickerSheetState();
}

class _PerkPickerSheetState extends ConsumerState<_PerkPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final perksAsync = widget.isSurvivor
        ? ref.watch(survivorPerksProvider)
        : ref.watch(killerPerksProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
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
            child: perksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (perks) {
                final filtered = perks.where((p) {
                  if (_search.isEmpty) return true;
                  final q = _search.toLowerCase();
                  return p.name.toLowerCase().contains(q) ||
                      p.character.toLowerCase().contains(q) ||
                      p.tags.any((t) => t.toLowerCase().contains(q));
                }).toList();
                return ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final perk = filtered[i];
                    final isUsed = widget.selectedIds.contains(perk.id);
                    final card = Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PerkCard(
                        perk: perk,
                        compact: true,
                        onTap: isUsed ? null : () => widget.onSelect(perk),
                      ),
                    );
                    return RepaintBoundary(
                      child: isUsed
                          ? Opacity(opacity: 0.4, child: card)
                          : card,
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
}
