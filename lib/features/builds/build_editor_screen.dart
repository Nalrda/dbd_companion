import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/models/addon.dart';
import '../../core/models/build.dart';
import '../../core/models/killer.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/addon_repository.dart';
import '../../core/repositories/item_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

/// Width from which the editor shows the loadout and a persistent perk
/// browser side by side.
const double _twoColumnMin = 900;

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
  final _tagController = TextEditingController();
  final _perkSearchController = TextEditingController();
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
    if (build.id.isEmpty || !mounted) return;
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
      // Tags are now editable here, so start from the saved ones.
      _tags
        ..clear()
        ..addAll(build.tags);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _perkSearchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Please enter a build name', error: true);
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
    if (!mounted) return;
    // Opened from a deep link or after a web refresh there is nothing to pop.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.buildId != null ? '/builds/${widget.buildId}' : '/builds');
    }
  }

  bool get _twoColumn => MediaQuery.sizeOf(context).width >= _twoColumnMin;

  /// Slot the perk browser fills next: the explicitly selected slot, else the
  /// first empty one.
  int? get _targetSlot {
    if (_editingSlot != null) return _editingSlot;
    final i = _perkSlots.indexOf(null);
    return i == -1 ? null : i;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = AppLayout.isCompact(context);
    final perksAsync =
        _isSurvivor ? ref.watch(survivorPerksProvider) : ref.watch(killerPerksProvider);
    final role = _isSurvivor ? (l10n?.survivor ?? 'Survivor') : (l10n?.killer ?? 'Killer');
    final filled = _perkSlots.whereType<String>().length;
    final isEdit = widget.buildId != null;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              showBack: true,
              title: isEdit ? 'Edit build' : 'New build',
              subtitle: '$role build  ·  $filled/4 perks',
              actions: [
                if (!compact)
                  AppButton.ghost(
                    label: 'Cancel',
                    compact: true,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/builds'),
                  ),
                AppButton(
                  label: 'Save',
                  icon: Icons.check,
                  compact: true,
                  onPressed: _save,
                ),
              ],
            ),
            Expanded(
              child: perksAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(e),
                data: (perks) => _buildBody(perks),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Perk> allPerks) {
    final perksById = {for (final p in allPerks) p.id: p};

    if (!_twoColumn) {
      return ContentWidth(
        child: SingleChildScrollView(
          padding: pagePadding(context, top: 4, bottom: 40),
          child: _buildLoadout(perksById, twoColumn: false),
        ),
      );
    }

    final pad = pagePadding(context);
    return ContentWidth(
      child: Padding(
        padding: EdgeInsets.only(left: pad.left, right: pad.right),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 4, bottom: 40, right: 24),
                child: _buildLoadout(perksById, twoColumn: true),
              ),
            ),
            const VerticalDivider(width: 1),
            SizedBox(
              width: 400,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: _buildPerkBrowser(allPerks),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Loadout column ────────────────────────────────────────────────────────

  Widget _buildLoadout(Map<String, Perk> perksById, {required bool twoColumn}) {
    const gap = SizedBox(height: 26);
    const labelGap = SizedBox(height: 12);
    final filled = _perkSlots.whereType<String>().length;

    Widget slot(int i) {
      final perkId = _perkSlots[i];
      final targeted = twoColumn && _targetSlot == i;
      return _EditorPerkSlot(
        index: i,
        perk: perkId != null ? perksById[perkId] : null,
        targeted: targeted,
        hint: twoColumn
            ? (targeted
                ? (perkId == null ? 'Pick a perk from the list' : 'Pick a perk to replace it')
                : 'Click to fill this slot')
            : 'Tap to choose a perk',
        onTap: () => _openPerkPicker(i),
        onRemove: perkId != null
            ? () => setState(() {
                  _perkSlots[i] = null;
                  if (_editingSlot == i) _editingSlot = null;
                })
            : null,
      );
    }

    final perkSlots = twoColumn
        ? Column(
            children: [
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: slot(row * 2)),
                    const SizedBox(width: 10),
                    Expanded(child: slot(row * 2 + 1)),
                  ],
                ),
              ],
            ],
          )
        : Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                slot(i),
              ],
            ],
          );

    final addon1 = _AddonSlot(
      label: 'Add-on 1',
      addonId: _selectedAddon1Id,
      onTap: () => _openAddonPicker(slot: 1),
      onRemove: _selectedAddon1Id != null ? () => setState(() => _selectedAddon1Id = null) : null,
    );
    final addon2 = _AddonSlot(
      label: 'Add-on 2',
      addonId: _selectedAddon2Id,
      onTap: () => _openAddonPicker(slot: 2),
      onRemove: _selectedAddon2Id != null ? () => setState(() => _selectedAddon2Id = null) : null,
    );
    final addons = twoColumn
        ? Row(
            children: [
              Expanded(child: addon1),
              const SizedBox(width: 10),
              Expanded(child: addon2),
            ],
          )
        : Column(children: [addon1, const SizedBox(height: 8), addon2]);

    final hasAddonSource = _isSurvivor ? _selectedItemId != null : _selectedKillerId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(title: 'Name'),
        labelGap,
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          style: AppFonts.body(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            hintText: 'Build name...',
            prefixIcon: Icon(Icons.drive_file_rename_outline, size: 18),
          ),
        ),
        if (!_isSurvivor) ...[
          gap,
          const SectionLabel(title: 'Killer'),
          labelGap,
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
        ],
        gap,
        SectionLabel(
          title: 'Perks',
          count: '$filled/4',
          trailing: twoColumn && _editingSlot != null
              ? _TextAction(
                  label: 'Done',
                  onTap: () => setState(() => _editingSlot = null),
                )
              : null,
        ),
        labelGap,
        perkSlots,
        if (_isSurvivor) ...[
          gap,
          const SectionLabel(title: 'Item'),
          labelGap,
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
        ],
        if (hasAddonSource) ...[
          gap,
          SectionLabel(title: _isSurvivor ? 'Item add-ons' : 'Killer add-ons'),
          labelGap,
          addons,
        ],
        gap,
        const SectionLabel(title: 'Offering'),
        labelGap,
        OfferingSlot(
          selectedOfferingId: _selectedOfferingId,
          isSurvivor: _isSurvivor,
          onTap: _openOfferingPicker,
          onRemove:
              _selectedOfferingId != null ? () => setState(() => _selectedOfferingId = null) : null,
        ),
        gap,
        const SectionLabel(title: 'Notes'),
        labelGap,
        TextField(
          controller: _notesController,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          style: AppFonts.body(fontSize: 14, height: 1.45),
          decoration: const InputDecoration(
            hintText: 'Build notes, strategy tips...',
            alignLabelWithHint: true,
          ),
        ),
        gap,
        SectionLabel(title: 'Tags', count: _tags.isEmpty ? null : '${_tags.length}'),
        labelGap,
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in _tags)
                Tooltip(
                  message: 'Remove tag',
                  child: AppChip(
                    label: t,
                    icon: Icons.close,
                    onTap: () => setState(() => _tags.remove(t)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                style: AppFonts.body(fontSize: 14),
                textInputAction: TextInputAction.done,
                onSubmitted: _addTag,
                decoration: const InputDecoration(
                  hintText: 'Add a tag (e.g. solo, meta)',
                  prefixIcon: Icon(Icons.sell_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: Icons.add,
              tooltip: 'Add tag',
              size: 44,
              onPressed: () => _addTag(_tagController.text),
            ),
          ],
        ),
      ],
    );
  }

  void _addTag(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    setState(() {
      if (!_tags.contains(t)) _tags.add(t);
      _tagController.clear();
    });
  }

  // ─── Perk browser (wide) ───────────────────────────────────────────────────

  Widget _buildPerkBrowser(List<Perk> all) {
    final filtered = all.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.character.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    final target = _targetSlot;
    final String status;
    if (target == null) {
      status = 'All slots are full — select a slot to replace its perk';
    } else if (_perkSlots[target] != null) {
      status = 'Replacing perk ${target + 1}';
    } else {
      status = 'Adding to perk ${target + 1}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title: 'Perk browser', count: '${filtered.length}'),
        const SizedBox(height: 12),
        AppSearchField(
          controller: _perkSearchController,
          hint: 'Search perks, characters, tags',
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            DiamondMark(
              size: 6,
              color: target == null ? AppTheme.textTertiary : AppTheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(
                  fontSize: 13,
                  color: target == null ? AppTheme.textTertiary : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'No perks found',
                  subtitle: 'Try a different name, character or tag.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final perk = filtered[index];
                    final isUsed = _perkSlots.contains(perk.id);
                    final card = PerkCard(
                      perk: perk,
                      compact: true,
                      isSelected: isUsed,
                      onTap: () => _onBrowserPerkTap(perk),
                    );
                    return RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: isUsed
                            ? Tooltip(message: 'In this build — click to remove', child: card)
                            : card,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _onBrowserPerkTap(Perk perk) {
    final used = _perkSlots.indexOf(perk.id);
    if (used != -1) {
      setState(() {
        _perkSlots[used] = null;
        if (_editingSlot == used) _editingSlot = null;
      });
      return;
    }
    final target = _targetSlot;
    if (target == null) {
      showAppSnack(context, 'All 4 perk slots are full. Select a slot to replace its perk.');
      return;
    }
    setState(() {
      _perkSlots[target] = perk.id;
      _editingSlot = null;
    });
  }

  // ─── Pickers ──────────────────────────────────────────────────────────────

  void _openItemPicker() {
    showAppSheet<void>(
      context,
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
    showAppSheet<void>(
      context,
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

    showAppSheet<void>(
      context,
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
    showAppSheet<void>(
      context,
      builder: (ctx) => OfferingPickerSheet(
        selectedId: _selectedOfferingId,
        isSurvivor: _isSurvivor,
        onSelect: (offering) {
          setState(() => _selectedOfferingId = offering.id == 'no_offering' ? null : offering.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _openPerkPicker(int slot) {
    if (_twoColumn) {
      // Wide: the persistent browser fills the selected slot.
      setState(() => _editingSlot = _editingSlot == slot ? null : slot);
      return;
    }
    setState(() => _editingSlot = slot);
    showAppSheet<void>(
      context,
      builder: (ctx) => _PerkPickerSheet(
        isSurvivor: _isSurvivor,
        slotIndex: slot,
        selectedIds: _perkSlots.whereType<String>().toList(),
        onSelect: (perk) {
          setState(() => _perkSlots[slot] = perk.id);
          Navigator.pop(ctx);
        },
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _editingSlot = null);
    });
  }
}

// ─── Small text action ────────────────────────────────────────────────────────

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: AppShapes.notched(cut: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label.toUpperCase(),
          style: AppFonts.caption(color: AppTheme.primary, fontSize: 12),
        ),
      ),
    );
  }
}

// ─── Editor perk slot ─────────────────────────────────────────────────────────
// Like [PerkSlot], but can be highlighted as the browser's target slot.

class _EditorPerkSlot extends StatelessWidget {
  final int index;
  final Perk? perk;
  final bool targeted;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _EditorPerkSlot({
    required this.index,
    required this.perk,
    required this.targeted,
    required this.hint,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = perk;
    final label = AppLocalizations.of(context)?.perkNumber(index + 1) ?? 'Perk ${index + 1}';
    final captionColor = targeted ? AppTheme.primary : AppTheme.textTertiary;

    return SizedBox(
      height: 80,
      child: AppPanel(
        onTap: onTap,
        selected: targeted,
        cut: 8,
        color: p == null && !targeted ? AppTheme.background.withValues(alpha: 0.4) : null,
        padding: EdgeInsets.fromLTRB(p == null ? 14 : 8, 6, 4, 6),
        child: Row(
          children: [
            if (p != null)
              PerkIcon(perk: p, size: 64, showCategoryGlow: targeted)
            else
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(48),
                      painter: DiamondFramePainter(
                        fill: Colors.transparent,
                        stroke: targeted
                            ? AppTheme.primary.withValues(alpha: 0.7)
                            : AppTheme.borderHighlight,
                      ),
                    ),
                    Icon(Icons.add, size: 18, color: captionColor),
                  ],
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label.toUpperCase(),
                      style: AppFonts.caption(color: captionColor, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    p?.name ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: p != null
                        ? AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600)
                        : AppFonts.body(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  if (p != null)
                    Text(
                      p.character,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
                    ),
                ],
              ),
            ),
            if (onRemove != null) SlotRemoveButton(onPressed: onRemove!),
          ],
        ),
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
    final addon = _addon;
    final rarityColor = addon != null ? AppTheme.rarityColor(addon.rarity) : AppTheme.border;

    return BaseSlot(
      isEmpty: addon == null,
      height: 60,
      filledBorderColor: rarityColor.withValues(alpha: 0.45),
      emptyIcon: Icons.extension_outlined,
      emptyLabel: widget.label,
      onTap: widget.onTap,
      contentPadding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      filledContent: addon == null
          ? const SizedBox()
          : Row(
              children: [
                SquareGlyph(icon: Icons.extension_outlined, color: rarityColor, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        addon.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        addon.rarity.replaceAll('_', ' ').toUpperCase(),
                        style: AppFonts.caption(color: rarityColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (widget.onRemove != null) SlotRemoveButton(onPressed: widget.onRemove!),
              ],
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
            ? killers.firstWhere((k) => k.id == selectedKillerId, orElse: () => killers.first)
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
      emptyIcon: Icons.local_fire_department_outlined,
      emptyLabel: 'Choose Killer',
      onTap: onTap,
      contentPadding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      filledContent: killer == null
          ? const SizedBox()
          : Row(
              children: [
                SquareGlyph(
                  icon: Icons.local_fire_department_outlined,
                  color: AppTheme.primary,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        killer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        killer.power.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.caption(color: AppTheme.textSecondary, fontSize: 11),
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

// ─── Shared sheet scaffold ────────────────────────────────────────────────────

class _SearchSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String hint;
  final ValueChanged<String> onSearch;
  final Widget list;

  const _SearchSheet({
    required this.title,
    this.subtitle,
    required this.hint,
    required this.onSearch,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sheetHeight(context),
      child: Column(
        children: [
          SheetHeader(title: title, subtitle: subtitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: hint,
              autofocus: !AppLayout.isCompact(context),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(child: list),
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

    return _SearchSheet(
      title: 'Choose Killer',
      hint: 'Search killers...',
      onSearch: (v) => setState(() => _search = v),
      list: killersAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(e),
        data: (killers) {
          final q = _search.toLowerCase();
          final filtered = _search.isEmpty
              ? killers
              : killers
                  .where(
                      (k) => k.name.toLowerCase().contains(q) || k.power.toLowerCase().contains(q))
                  .toList();

          if (filtered.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No killers found',
              subtitle: 'Try a different name or power.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final killer = filtered[i];
              return PickerRow(
                leading: SquareGlyph(
                  icon: Icons.local_fire_department_outlined,
                  color: AppTheme.primary,
                  size: 38,
                ),
                title: killer.name,
                subtitle: killer.power,
                subtitleColor: AppTheme.textSecondary,
                selected: killer.id == widget.selectedId,
                onTap: () => widget.onSelect(killer),
              );
            },
          );
        },
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
    if (!mounted) return;
    setState(() {
      _addons = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget list;
    if (_loading) {
      list = const LoadingView();
    } else {
      final filtered = _addons.where((a) {
        if (a.id == widget.excludeId) return false;
        if (_search.isEmpty) return true;
        return a.name.toLowerCase().contains(_search.toLowerCase());
      }).toList();

      list = filtered.isEmpty
          ? const EmptyState(
              icon: Icons.search_off,
              title: 'No add-ons found',
              subtitle: 'Try a different search.',
            )
          : ListView.builder(
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
    }

    return _SearchSheet(
      title: 'Choose Add-on',
      hint: 'Search add-ons...',
      onSearch: (v) => setState(() => _search = v),
      list: list,
    );
  }
}

// ─── Perk picker sheet (phones) ───────────────────────────────────────────────

class _PerkPickerSheet extends ConsumerStatefulWidget {
  final bool isSurvivor;
  final int slotIndex;
  final List<String> selectedIds;
  final ValueChanged<Perk> onSelect;

  const _PerkPickerSheet({
    required this.isSurvivor,
    required this.slotIndex,
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
    final perksAsync =
        widget.isSurvivor ? ref.watch(survivorPerksProvider) : ref.watch(killerPerksProvider);

    return _SearchSheet(
      title: 'Choose Perk',
      subtitle: 'Slot ${widget.slotIndex + 1} of 4',
      hint: 'Search perks...',
      onSearch: (v) => setState(() => _search = v),
      list: perksAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(e),
        data: (perks) {
          final filtered = perks.where((p) {
            if (_search.isEmpty) return true;
            final q = _search.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.character.toLowerCase().contains(q) ||
                p.tags.any((t) => t.toLowerCase().contains(q));
          }).toList();

          if (filtered.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No perks found',
              subtitle: 'Try a different name, character or tag.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final perk = filtered[i];
              final isUsed = widget.selectedIds.contains(perk.id);
              final card = Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PerkCard(
                  perk: perk,
                  compact: true,
                  isSelected: isUsed,
                  onTap: isUsed ? null : () => widget.onSelect(perk),
                ),
              );
              return RepaintBoundary(
                child: isUsed ? Opacity(opacity: 0.5, child: card) : card,
              );
            },
          );
        },
      ),
    );
  }
}
