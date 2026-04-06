import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/killer.dart';
import '../../../core/repositories/killer_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/dbdle_providers.dart';
import '../widgets/killer_guess_row.dart';

class KillerGuessScreen extends ConsumerStatefulWidget {
  const KillerGuessScreen({super.key});

  @override
  ConsumerState<KillerGuessScreen> createState() => _KillerGuessScreenState();
}

class _KillerGuessScreenState extends ConsumerState<KillerGuessScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Killer> _allKillers = [];
  List<Killer> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadKillers();
  }

  Future<void> _loadKillers() async {
    final killers = await KillerRepository.instance.getAll();
    if (mounted) setState(() => _allKillers = killers);
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final lower = query.toLowerCase();
    final gameState = ref.read(killerGameProvider).valueOrNull;
    final guessedIds = gameState?.guesses.map((g) => g.killer.id).toSet() ?? {};
    setState(() {
      _suggestions = _allKillers
          .where((k) =>
              !guessedIds.contains(k.id) &&
              k.name.toLowerCase().contains(lower))
          .take(8)
          .toList();
    });
  }

  void _submitGuess(Killer killer) {
    ref.read(killerGameProvider.notifier).guess(killer);
    _controller.clear();
    setState(() => _suggestions = []);
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(killerGameProvider);

    return gameAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (game) {
        if (game.targetKiller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildGame(game);
      },
    );
  }

  Widget _buildGame(KillerGameState game) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'GUESS THE KILLER',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.guesses.length} guess${game.guesses.length != 1 ? 'es' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Legend ───────────────────────────────────────────────────────────
          _Legend(),
          const SizedBox(height: 20),

          // ── Won banner ───────────────────────────────────────────────────────
          if (game.isWon) ...[
            _WonBanner(
              killerName: game.targetKiller!.name,
              power: game.targetKiller!.power,
              guessCount: game.guesses.length,
            ),
            const SizedBox(height: 20),
          ],

          // ── Input (hidden when won) ──────────────────────────────────────────
          if (!game.isWon) ...[
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type a killer name…',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        color: AppTheme.textSecondary,
                        onPressed: () {
                          _controller.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: _suggestions
                      .map(
                        (k) => _KillerSuggestionTile(
                          killer: k,
                          onTap: () => _submitGuess(k),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],

          // ── Guess history ────────────────────────────────────────────────────
          if (game.guesses.isNotEmpty) ...[
            // Column headers
            _GuessTableHeader(),
            const SizedBox(height: 6),
            ...game.guesses.reversed.map((g) => KillerGuessRow(guess: g)),
          ],
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _GuessTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Expanded(flex: 3, child: SizedBox()),
          const SizedBox(width: 8),
          _HeaderLabel('HEIGHT', flex: 2),
          const SizedBox(width: 6),
          _HeaderLabel('SPEED', flex: 2),
          const SizedBox(width: 6),
          _HeaderLabel('TERROR', flex: 2),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderLabel(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.rajdhani(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _LegendItem(
            icon: Icons.check_rounded,
            color: Color(0xFF4CAF50),
            label: 'Correct',
          ),
          _LegendItem(
            icon: Icons.arrow_upward_rounded,
            color: AppTheme.accent,
            label: 'Too low',
          ),
          _LegendItem(
            icon: Icons.arrow_downward_rounded,
            color: AppTheme.accent,
            label: 'Too high',
          ),
          _LegendItem(
            icon: Icons.close_rounded,
            color: Color(0xFFCC3333),
            label: 'Wrong',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Killer Suggestion Tile ───────────────────────────────────────────────────

class _KillerSuggestionTile extends StatefulWidget {
  final Killer killer;
  final VoidCallback onTap;

  const _KillerSuggestionTile({required this.killer, required this.onTap});

  @override
  State<_KillerSuggestionTile> createState() => _KillerSuggestionTileState();
}

class _KillerSuggestionTileState extends State<_KillerSuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Skull icon placeholder (no killer images available)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.sports_kabaddi,
                    color: AppTheme.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.killer.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      widget.killer.power,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Won Banner ───────────────────────────────────────────────────────────────

class _WonBanner extends StatelessWidget {
  final String killerName;
  final String power;
  final int guessCount;

  const _WonBanner({
    required this.killerName,
    required this.power,
    required this.guessCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF4CAF50), size: 32),
          const SizedBox(height: 8),
          Text(
            killerName.toUpperCase(),
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            power,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            guessCount == 1
                ? 'First try!'
                : 'Solved in $guessCount guess${guessCount != 1 ? 'es' : ''}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Come back tomorrow for a new killer!',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
