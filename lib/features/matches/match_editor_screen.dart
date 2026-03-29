import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _characterController = TextEditingController();
  final _mapController = TextEditingController();
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
    _characterController.dispose();
    _mapController.dispose();
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
        const SnackBar(content: Text('Please select an outcome')),
      );
      return;
    }
    await ref.read(matchesProvider.notifier).add(
      isSurvivor: _isSurvivor,
      outcome: _outcome!,
      characterName: _characterController.text.trim().isEmpty
          ? null
          : _characterController.text.trim(),
      mapName: _mapController.text.trim().isEmpty
          ? null
          : _mapController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
                        color: selected
                            ? color
                            : AppTheme.border,
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
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            SectionHeader(
              title: _isSurvivor ? 'KILLER PLAYED' : 'CHARACTER PLAYED',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _characterController,
              decoration: InputDecoration(
                hintText: _isSurvivor
                    ? 'e.g. The Trapper'
                    : 'e.g. The Nurse',
              ),
            ),

            const SizedBox(height: 20),
            const SectionHeader(title: 'MAP'),
            const SizedBox(height: 10),
            TextField(
              controller: _mapController,
              decoration: const InputDecoration(
                hintText: 'e.g. Badham Preschool',
              ),
            ),

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
