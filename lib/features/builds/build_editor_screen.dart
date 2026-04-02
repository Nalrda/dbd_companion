import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/build.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
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
  late TextEditingController _addon1Controller;
  late TextEditingController _addon2Controller;
  late bool _isSurvivor;
  late List<String?> _perkSlots;
  final List<String> _tags = [];
  String _searchQuery = '';
  int? _editingSlot;
  Build? _existingBuild;
  String? _selectedItemId;
  String? _selectedOfferingId;

  @override
  void initState() {
    super.initState();
    _perkSlots = List.filled(4, null);

    final imported = widget.sharedBuild;
    if (imported != null) {
      _isSurvivor = imported.isSurvivor;
      _nameController = TextEditingController(text: imported.name);
      _notesController = TextEditingController(text: imported.notes ?? '');
      _addon1Controller = TextEditingController(text: imported.addon1 ?? '');
      _addon2Controller = TextEditingController(text: imported.addon2 ?? '');
      _selectedItemId = imported.itemId;
      _selectedOfferingId = imported.offeringId;
      for (int i = 0; i < imported.perkIds.length && i < 4; i++) {
        _perkSlots[i] = imported.perkIds[i];
      }
      _tags.addAll(imported.tags);
    } else {
      _isSurvivor = widget.isSurvivor;
      _nameController = TextEditingController(text: widget.sharedName ?? '');
      _notesController = TextEditingController();
      _addon1Controller = TextEditingController();
      _addon2Controller = TextEditingController();
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
      _addon1Controller.text = build.addon1 ?? '';
      _addon2Controller.text = build.addon2 ?? '';
      for (int i = 0; i < build.perkIds.length && i < 4; i++) {
        _perkSlots[i] = build.perkIds[i];
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _addon1Controller.dispose();
    _addon2Controller.dispose();
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
    final addon1 = _addon1Controller.text.trim().isEmpty ? null : _addon1Controller.text.trim();
    final addon2 = _addon2Controller.text.trim().isEmpty ? null : _addon2Controller.text.trim();

    if (_existingBuild != null) {
      final updated = _existingBuild!.copyWith(
        name: name,
        perkIds: perkIds,
        notes: _notesController.text.trim(),
        tags: _tags,
        itemId: _selectedItemId,
        addon1: addon1,
        addon2: addon2,
        offeringId: _selectedOfferingId,
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
        addon1: addon1,
        addon2: addon2,
        offeringId: _selectedOfferingId,
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
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: perksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (perks) => _buildBody(perks),
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
            style: const TextStyle(
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
                  ? () => setState(() => _selectedItemId = null)
                  : null,
            ),
          ] else ...[
            const SectionHeader(title: 'ADD-ONS'),
            const SizedBox(height: 10),
            TextField(
              controller: _addon1Controller,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add-on 1...',
                prefixIcon: Icon(Icons.extension_outlined, color: AppTheme.textDim, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addon2Controller,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add-on 2...',
                prefixIcon: Icon(Icons.extension_outlined, color: AppTheme.textDim, size: 18),
              ),
            ),
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
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Build notes, strategy tips...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

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
          setState(() => _selectedItemId = item.id == 'no_item' ? null : item.id);
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
    // On narrow screens always show bottom sheet
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
              style: const TextStyle(color: AppTheme.textPrimary),
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

// ─── Mobile perk picker sheet ────────────────────────────────────────────────

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
              style: const TextStyle(color: AppTheme.textPrimary),
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
