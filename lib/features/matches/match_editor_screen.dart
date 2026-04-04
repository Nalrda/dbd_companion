import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/killer.dart';
import '../../core/models/map_callout.dart';
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

  List<String> get _outcomes =>
      _isSurvivor ? _survivorOutcomes : _killerOutcomes;

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
        return const Color(0xFF3E9E44);
      case 'killed':
      case '0k':
      case '1k':
        return AppTheme.accent;
      default:
        return AppTheme.primary;
    }
  }

  Future<void> _save() async {
    if (_outcome == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an outcome first')),
      );
      return;
    }
    try {
      await ref.read(matchesProvider.notifier).add(
        isSurvivor: _isSurvivor,
        outcome: _outcome!,
        characterName: _selectedKillerName,
        mapName: _selectedMapName,
        gensRemaining: _isSurvivor ? null : _gensRemaining,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving match: $e')),
        );
      }
    }
  }

  Future<void> _pickKiller(List<Killer> killers) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _KillerPickerSheet(killers: killers),
    );
    if (result != null) setState(() => _selectedKillerName = result);
  }

  Future<void> _pickMap(List<MapRealm> realms) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _MapPickerSheet(realms: realms),
    );
    if (result != null) setState(() => _selectedMapName = result);
  }

  @override
  Widget build(BuildContext context) {
    final killersAsync = ref.watch(killersProvider);
    final mapsAsync = ref.watch(mapRealmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Match'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'SAVE',
              style: GoogleFonts.rajdhani(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role toggle
            const SectionHeader(title: 'ROLE'),
            const SizedBox(height: 12),
            RoleToggle(
              isSurvivor: _isSurvivor,
              onChanged: (v) => setState(() {
                _isSurvivor = v;
                _outcome = null;
                _gensRemaining = 0;
              }),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'OUTCOME'),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _outcomes.map((o) {
                final selected = _outcome == o;
                final color = _outcomeColor(o);
                return GestureDetector(
                  onTap: () => setState(() => _outcome = o),
                  child: AnimatedScale(
                    scale: selected ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? color : AppTheme.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        _outcomeLabel(o),
                        style: GoogleFonts.rajdhani(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'KILLER PLAYED'),
            const SizedBox(height: 10),
            killersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppTheme.accent)),
              data: (killers) => _PickerButton(
                value: _selectedKillerName,
                hint: 'Select killer...',
                icon: Icons.sports_kabaddi_outlined,
                onTap: () => _pickKiller(killers),
                onClear: _selectedKillerName != null
                    ? () => setState(() => _selectedKillerName = null)
                    : null,
              ),
            ),

            const SizedBox(height: 20),
            const SectionHeader(title: 'MAP'),
            const SizedBox(height: 10),
            mapsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppTheme.accent)),
              data: (realms) => _PickerButton(
                value: _selectedMapName,
                hint: 'Select map...',
                icon: Icons.map_outlined,
                onTap: () => _pickMap(realms),
                onClear: _selectedMapName != null
                    ? () => setState(() => _selectedMapName = null)
                    : null,
              ),
            ),

            // Gens remaining — killer mode only
            if (!_isSurvivor) ...[
              const SizedBox(height: 20),
              const SectionHeader(title: 'GENS REMAINING'),
              const SizedBox(height: 10),
              _GensCounter(
                value: _gensRemaining,
                onChanged: (v) => setState(() => _gensRemaining = v),
              ),
            ],

            const SizedBox(height: 20),
            const SectionHeader(title: 'NOTES'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What went well? What to improve?',
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: DbdButton(
                label: 'Save Match',
                icon: Icons.check,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Picker button ────────────────────────────────────────────────────────────

class _PickerButton extends StatefulWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerButton({
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  State<_PickerButton> createState() => _PickerButtonState();
}

class _PickerButtonState extends State<_PickerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasValue
                  ? AppTheme.primary.withValues(alpha: 0.5)
                  : _hovered
                      ? AppTheme.primary.withValues(alpha: 0.4)
                      : AppTheme.border,
            ),
          ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: hasValue ? AppTheme.primary : AppTheme.textDim,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.value ?? widget.hint,
                style: TextStyle(
                  color: hasValue ? AppTheme.textPrimary : AppTheme.textDim,
                  fontSize: 14,
                ),
              ),
            ),
            if (widget.onClear != null)
              GestureDetector(
                onTap: widget.onClear,
                child: const Icon(Icons.close, size: 16, color: AppTheme.textDim),
              )
            else
              const Icon(Icons.chevron_right, size: 18, color: AppTheme.textDim),
          ],
        ),
      ),
    ),
  );
  }
}

// ─── Gens remaining counter ───────────────────────────────────────────────────

class _GensCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _GensCounter({required this.value, required this.onChanged});

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
          _CounterBtn(
            icon: Icons.remove,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.rajdhani(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: value == 0
                        ? const Color(0xFF3E9E44)
                        : AppTheme.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  value == 0 ? 'all done' : 'gens left',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textDim,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _CounterBtn(
            icon: Icons.add,
            onTap: value < 5 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterBtn({required this.icon, this.onTap});

  @override
  State<_CounterBtn> createState() => _CounterBtnState();
}

class _CounterBtnState extends State<_CounterBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: active ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed && active ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.15)
                : AppTheme.border.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : AppTheme.border,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: active ? AppTheme.primary : AppTheme.textDim,
          ),
        ),
      ),
    );
  }
}

// ─── Killer picker bottom sheet ───────────────────────────────────────────────

class _KillerPickerSheet extends StatefulWidget {
  final List<Killer> killers;
  const _KillerPickerSheet({required this.killers});

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

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search killer...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final killer = filtered[i];
                return ListTile(
                  title: Text(
                    killer.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    killer.power,
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 12),
                  ),
                  onTap: () => Navigator.pop(ctx, killer.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map picker bottom sheet ──────────────────────────────────────────────────

class _MapPickerSheet extends StatefulWidget {
  final List<MapRealm> realms;
  const _MapPickerSheet({required this.realms});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final allMaps = <({String name, String realm})>[
      for (final realm in widget.realms)
        for (final map in realm.maps)
          (name: map.name, realm: realm.realm),
    ];
    final filtered = allMaps
        .where((m) =>
            m.name.toLowerCase().contains(_search.toLowerCase()) ||
            m.realm.toLowerCase().contains(_search.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search map...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final map = filtered[i];
                return ListTile(
                  title: Text(
                    map.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    map.realm,
                    style: const TextStyle(
                        color: AppTheme.textDim, fontSize: 12),
                  ),
                  onTap: () => Navigator.pop(ctx, map.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
