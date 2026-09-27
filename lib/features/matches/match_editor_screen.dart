import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/killer.dart';
import '../../core/models/map_callout.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class MatchEditorScreen extends ConsumerStatefulWidget {
  final bool isSurvivor;
  const MatchEditorScreen({super.key, required this.isSurvivor});

  @override
  ConsumerState<MatchEditorScreen> createState() => _MatchEditorScreenState();
}

class _MatchEditorScreenState extends ConsumerState<MatchEditorScreen> {
  late bool _isSurvivor;
  String? _outcome;
  String? _selectedKillerName;
  String? _selectedMapName;
  int _gensRemaining = 0;
  final List<String?> _perkSlots = List.filled(4, null);
  final _notesController = TextEditingController();

  static const _survivorOutcomes = ['escaped', 'killed'];
  static const _killerOutcomes = ['4k', '3k', '2k', '1k', '0k'];

  @override
  void initState() {
    super.initState();
    _isSurvivor = widget.isSurvivor;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _outcomes => _isSurvivor ? _survivorOutcomes : _killerOutcomes;

  String _outcomeLabel(String outcome) {
    switch (outcome) {
      case 'escaped': return 'Escaped';
      case 'killed': return 'Killed';
      case '4k': return '4 Kills';
      case '3k': return '3 Kills';
      case '2k': return '2 Kills';
      case '1k': return '1 Kill';
      case '0k': return '0 Kills';
      default: return outcome;
    }
  }

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'escaped':
      case '4k':
      case '3k':
        return AppTheme.success;
      case 'killed':
      case '0k':
      case '1k':
        return AppTheme.danger;
      default:
        return AppTheme.textPrimary;
    }
  }

  Future<void> _save() async {
    if (_outcome == null) {
      showAppSnack(context, 'Select an outcome first', error: true);
      return;
    }
    final perkIds = _perkSlots.whereType<String>().toList();
    try {
      await ref.read(matchesProvider.notifier).add(
        isSurvivor: _isSurvivor,
        outcome: _outcome!,
        characterName: _selectedKillerName,
        mapName: _selectedMapName,
        perkIds: perkIds.isEmpty ? null : perkIds,
        gensRemaining: _isSurvivor ? null : _gensRemaining,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/matches');
      }
    } catch (e) {
      if (mounted) showAppSnack(context, 'Error saving match: $e', error: true);
    }
  }

  void _setRole(bool v) => setState(() {
        _isSurvivor = v;
        _outcome = null;
        _gensRemaining = 0;
        _perkSlots.fillRange(0, 4, null);
      });

  Future<void> _pickKiller(List<Killer> killers) async {
    final result = await showAppSheet<String>(
      context,
      builder: (ctx) => _KillerPickerSheet(
        killers: killers,
        selected: _selectedKillerName,
        title: _isSurvivor ? 'Killer faced' : 'Killer played',
      ),
    );
    if (result != null) setState(() => _selectedKillerName = result);
  }

  Future<void> _pickMap(List<MapRealm> realms) async {
    final result = await showAppSheet<String>(
      context,
      builder: (ctx) => _MapPickerSheet(realms: realms, selected: _selectedMapName),
    );
    if (result != null) setState(() => _selectedMapName = result);
  }

  Future<void> _pickPerk(int slot) async {
    final result = await showAppSheet<_PerkPick>(
      context,
      builder: (ctx) => _PerkPickerSheet(
        isSurvivor: _isSurvivor,
        slot: slot,
        current: _perkSlots[slot],
        usedIds: _perkSlots.whereType<String>().toList(),
      ),
    );
    if (result != null) setState(() => _perkSlots[slot] = result.perkId);
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    final killersAsync = ref.watch(killersProvider);
    final mapsAsync = ref.watch(mapRealmsProvider);
    final perksAsync = _isSurvivor ? ref.watch(survivorPerksProvider) : ref.watch(killerPerksProvider);
    final perksById = {
      for (final p in perksAsync.valueOrNull ?? const <Perk>[]) p.id: p,
    };

    final outcome = _section(
      'Outcome',
      _OutcomeSelector(
        outcomes: _outcomes,
        value: _outcome,
        isSurvivor: _isSurvivor,
        labelOf: _outcomeLabel,
        colorOf: _outcomeColor,
        onChanged: (o) => setState(() => _outcome = o),
      ),
    );

    final gens = _isSurvivor
        ? null
        : _section(
            'Gens remaining',
            _GensSelector(
              value: _gensRemaining,
              onChanged: (v) => setState(() => _gensRemaining = v),
            ),
          );

    final killer = _section(
      _isSurvivor ? 'Killer faced' : 'Killer played',
      killersAsync.when(
        loading: () => const _FieldSkeleton(),
        error: (e, _) => Text('Error: $e', style: AppFonts.body(color: AppTheme.danger)),
        data: (killers) => _PickerField(
          value: _selectedKillerName,
          hint: 'Select killer',
          icon: Icons.local_fire_department_outlined,
          onTap: () => _pickKiller(killers),
          onClear: _selectedKillerName != null
              ? () => setState(() => _selectedKillerName = null)
              : null,
        ),
      ),
    );

    final map = _section(
      'Map',
      mapsAsync.when(
        loading: () => const _FieldSkeleton(),
        error: (e, _) => Text('Error: $e', style: AppFonts.body(color: AppTheme.danger)),
        data: (realms) => _PickerField(
          value: _selectedMapName,
          hint: 'Select map',
          icon: Icons.map_outlined,
          onTap: () => _pickMap(realms),
          onClear: _selectedMapName != null
              ? () => setState(() => _selectedMapName = null)
              : null,
        ),
      ),
    );

    final perks = _section(
      'Perks used',
      _PerkSlots(
        perks: _perkSlots.map((id) => id == null ? null : perksById[id]).toList(),
        onTap: _pickPerk,
      ),
      count: '${_perkSlots.whereType<String>().length}/4',
    );

    final notes = _section(
      'Notes',
      TextField(
        controller: _notesController,
        maxLines: compact ? 3 : 5,
        minLines: 3,
        style: AppFonts.body(),
        decoration: const InputDecoration(hintText: 'What went well? What to improve?'),
      ),
    );

    final Widget form;
    if (compact) {
      form = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [outcome, if (gens != null) gens, killer, map, perks, notes],
      );
    } else {
      form = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [outcome, if (gens != null) gens, notes],
            ),
          ),
          const SizedBox(width: 36),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [killer, map, perks],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              showBack: true,
              title: 'Add match',
              subtitle: _isSurvivor ? 'Log a survivor game' : 'Log a killer game',
              actions: [
                AppButton(
                  label: 'Save',
                  icon: Icons.check,
                  compact: true,
                  onPressed: _save,
                ),
              ],
              bottom: compact
                  ? RoleToggle(expand: true, isSurvivor: _isSurvivor, onChanged: _setRole)
                  : Row(children: [RoleToggle(isSurvivor: _isSurvivor, onChanged: _setRole)]),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ContentWidth(
                  child: Padding(
                    padding: pagePadding(context, top: 6, bottom: 32),
                    child: form,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child, {String? count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(title: title, count: count),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Outcome selector ─────────────────────────────────────────────────────────

class _OutcomeSelector extends StatelessWidget {
  final List<String> outcomes;
  final String? value;
  final bool isSurvivor;
  final String Function(String) labelOf;
  final Color Function(String) colorOf;
  final ValueChanged<String> onChanged;

  const _OutcomeSelector({
    required this.outcomes,
    required this.value,
    required this.isSurvivor,
    required this.labelOf,
    required this.colorOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < outcomes.length; i++) {
      final o = outcomes[i];
      if (i > 0) children.add(SizedBox(width: isSurvivor ? 10 : 6));
      children.add(Expanded(
        child: _OutcomeToggle(
          selected: value == o,
          color: colorOf(o),
          onTap: () => onChanged(o),
          child: isSurvivor
              ? _SurvivorOutcome(
                  label: labelOf(o),
                  icon: o == 'escaped' ? Icons.directions_run : Icons.close,
                )
              : _KillerOutcome(kills: o.replaceAll('k', '')),
        ),
      ));
    }
    return Row(children: children);
  }
}

class _SurvivorOutcome extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SurvivorOutcome({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.display(fontSize: 20, color: color, letterSpacing: 1.6),
          ),
        ),
      ],
    );
  }
}

class _KillerOutcome extends StatelessWidget {
  final String kills;
  const _KillerOutcome({required this.kills});

  @override
  Widget build(BuildContext context) {
    final color = DefaultTextStyle.of(context).style.color;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(kills, style: AppFonts.display(fontSize: 28, color: color, height: 1)),
        const SizedBox(height: 2),
        Text(
          kills == '1' ? 'KILL' : 'KILLS',
          style: AppFonts.caption(fontSize: 10, color: color?.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

/// Large notched toggle tinted with the outcome color when selected.
class _OutcomeToggle extends StatelessWidget {
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  const _OutcomeToggle({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? color : AppTheme.textSecondary;
    return SizedBox(
      height: 72,
      child: AppPanel(
        onTap: onTap,
        cut: 9,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        color: selected ? Color.alphaBlend(color.withValues(alpha: 0.14), AppTheme.surface) : null,
        borderColor: selected ? color.withValues(alpha: 0.8) : null,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ─── Gens selector ────────────────────────────────────────────────────────────

class _GensSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _GensSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i <= 5; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: AppPanel(
                    onTap: () => onChanged(i),
                    selected: value == i,
                    cut: 7,
                    padding: EdgeInsets.zero,
                    child: Center(
                      child: Text(
                        '$i',
                        style: AppFonts.display(
                          fontSize: 20,
                          color: value == i ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value == 0
              ? 'All generators were completed'
              : '$value ${value == 1 ? 'generator' : 'generators'} left when the match ended',
          style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
        ),
      ],
    );
  }
}

// ─── Picker field ─────────────────────────────────────────────────────────────

class _PickerField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return SizedBox(
      height: 52,
      child: AppPanel(
        onTap: onTap,
        cut: 8,
        padding: const EdgeInsets.only(left: 14, right: 4),
        child: Row(
          children: [
            Icon(icon, size: 19, color: hasValue ? AppTheme.primary : AppTheme.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.body(
                  fontSize: 15,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? AppTheme.textPrimary : AppTheme.textTertiary,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18, color: AppTheme.textTertiary),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right, size: 20, color: AppTheme.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 52,
        child: AppPanel(padding: EdgeInsets.zero, child: SizedBox.expand()),
      );
}

// ─── Perk slots ───────────────────────────────────────────────────────────────

class _PerkSlots extends StatelessWidget {
  final List<Perk?> perks;
  final ValueChanged<int> onTap;

  const _PerkSlots({required this.perks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(child: _PerkSlotTile(index: i, perk: perks[i], onTap: () => onTap(i))),
      ],
    );
  }
}

class _PerkSlotTile extends StatelessWidget {
  final int index;
  final Perk? perk;
  final VoidCallback onTap;

  const _PerkSlotTile({required this.index, required this.perk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    final p = perk;
    return Tooltip(
      message: p?.name ?? 'Add perk ${index + 1}',
      child: InkWell(
        onTap: onTap,
        customBorder: AppShapes.notched(cut: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(a),
                    child: child,
                  ),
                ),
                child: p != null
                    ? PerkIcon(key: ValueKey(p.id), perk: p, size: size)
                    : SizedBox(
                        key: ValueKey('empty_$index'),
                        width: size,
                        height: size,
                        child: CustomPaint(
                          painter: DiamondFramePainter(
                            fill: AppTheme.background.withValues(alpha: 0.5),
                            stroke: AppTheme.borderHighlight,
                          ),
                          child: const Center(
                            child: Icon(Icons.add, size: 20, color: AppTheme.textTertiary),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 30,
                child: Text(
                  p?.name ?? 'Perk ${index + 1}',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: p != null
                      ? AppFonts.body(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.25)
                      : AppFonts.caption(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheets ───────────────────────────────────────────────────────────────────

class _SearchSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String hint;
  final ValueChanged<String> onSearch;
  final Widget? trailing;
  final Widget list;

  const _SearchSheet({
    required this.title,
    this.subtitle,
    required this.hint,
    required this.onSearch,
    this.trailing,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sheetHeight(context),
      child: Column(
        children: [
          SheetHeader(title: title, subtitle: subtitle, trailing: trailing),
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

class _KillerPickerSheet extends StatefulWidget {
  final List<Killer> killers;
  final String? selected;
  final String title;
  const _KillerPickerSheet({required this.killers, required this.selected, required this.title});

  @override
  State<_KillerPickerSheet> createState() => _KillerPickerSheetState();
}

class _KillerPickerSheetState extends State<_KillerPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.killers
        .where((k) => k.name.toLowerCase().contains(_search.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return _SearchSheet(
      title: widget.title,
      hint: 'Search killer',
      onSearch: (v) => setState(() => _search = v),
      list: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final killer = filtered[i];
          return PickerRow(
            leading: const SquareGlyph(
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.textSecondary,
              size: 36,
            ),
            title: killer.name,
            subtitle: killer.power,
            selected: killer.name == widget.selected,
            onTap: () => Navigator.pop(ctx, killer.name),
          );
        },
      ),
    );
  }
}

class _MapPickerSheet extends StatefulWidget {
  final List<MapRealm> realms;
  final String? selected;
  const _MapPickerSheet({required this.realms, required this.selected});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final allMaps = <({String name, String realm})>[
      for (final realm in widget.realms)
        for (final map in realm.maps) (name: map.name, realm: realm.realm),
    ];
    final filtered = allMaps
        .where((m) =>
            m.name.toLowerCase().contains(_search.toLowerCase()) ||
            m.realm.toLowerCase().contains(_search.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return _SearchSheet(
      title: 'Map',
      hint: 'Search map or realm',
      onSearch: (v) => setState(() => _search = v),
      list: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) {
          final map = filtered[i];
          return PickerRow(
            leading: const SquareGlyph(
              icon: Icons.map_outlined,
              color: AppTheme.textSecondary,
              size: 36,
            ),
            title: map.name,
            subtitle: map.realm,
            selected: map.name == widget.selected,
            onTap: () => Navigator.pop(ctx, map.name),
          );
        },
      ),
    );
  }
}

/// Result of the perk sheet: a perk id, or null to clear the slot.
class _PerkPick {
  final String? perkId;
  const _PerkPick(this.perkId);
}

class _PerkPickerSheet extends ConsumerStatefulWidget {
  final bool isSurvivor;
  final int slot;
  final String? current;
  final List<String> usedIds;

  const _PerkPickerSheet({
    required this.isSurvivor,
    required this.slot,
    required this.current,
    required this.usedIds,
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
      title: 'Perk ${widget.slot + 1}',
      subtitle: widget.isSurvivor ? 'Survivor perks' : 'Killer perks',
      hint: 'Search perks',
      onSearch: (v) => setState(() => _search = v),
      trailing: widget.current != null
          ? AppButton.ghost(
              label: 'Remove',
              icon: Icons.close,
              compact: true,
              onPressed: () => Navigator.pop(context, const _PerkPick(null)),
            )
          : null,
      list: perksAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(e),
        data: (perks) {
          final q = _search.toLowerCase();
          final filtered = perks.where((p) {
            if (q.isEmpty) return true;
            return p.name.toLowerCase().contains(q) ||
                p.character.toLowerCase().contains(q) ||
                p.tags.any((t) => t.toLowerCase().contains(q));
          }).toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final perk = filtered[i];
              final isCurrent = perk.id == widget.current;
              final isUsed = !isCurrent && widget.usedIds.contains(perk.id);
              final card = Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PerkCard(
                  perk: perk,
                  compact: true,
                  isSelected: isCurrent,
                  onTap: isUsed ? null : () => Navigator.pop(ctx, _PerkPick(perk.id)),
                ),
              );
              return RepaintBoundary(
                child: isUsed ? Opacity(opacity: 0.4, child: card) : card,
              );
            },
          );
        },
      ),
    );
  }
}
