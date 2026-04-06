import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/perk.dart';
import '../../../core/repositories/perk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/dbdle_providers.dart';
import '../widgets/blur_reveal_icon.dart';

class PerkGuessScreen extends ConsumerStatefulWidget {
  const PerkGuessScreen({super.key});

  @override
  ConsumerState<PerkGuessScreen> createState() => _PerkGuessScreenState();
}

class _PerkGuessScreenState extends ConsumerState<PerkGuessScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Perk> _allPerks = [];
  List<Perk> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadPerks();
  }

  Future<void> _loadPerks() async {
    final perks = await PerkRepository.instance.getAllPerks();
    if (mounted) setState(() => _allPerks = perks);
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final lower = query.toLowerCase();
    final gameState = ref.read(perkGameProvider).valueOrNull;
    final guessedIds = {
      ...?gameState?.wrongGuesses.map((p) => p.id),
      if (gameState?.targetPerk != null && gameState!.isWon)
        gameState.targetPerk!.id,
    };
    setState(() {
      _suggestions = _allPerks
          .where((p) =>
              !guessedIds.contains(p.id) &&
              p.name.toLowerCase().contains(lower))
          .take(8)
          .toList();
    });
  }

  void _submitGuess(Perk perk) {
    ref.read(perkGameProvider.notifier).guess(perk);
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
    final gameAsync = ref.watch(perkGameProvider);

    return gameAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (game) {
        if (game.targetPerk == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildGame(game);
      },
    );
  }

  Widget _buildGame(PerkGameState game) {
    final target = game.targetPerk!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Text(
            'GUESS THE PERK',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${game.wrongGuesses.length} guess${game.wrongGuesses.length != 1 ? 'es' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textDim,
            ),
          ),
          const SizedBox(height: 28),

          // ── Blurred icon ─────────────────────────────────────────────────────
          Center(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: BlurRevealIcon(
                perk: target,
                blurSigma: game.isWon ? 0 : game.blurSigma,
                size: 140,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Won state ────────────────────────────────────────────────────────
          if (game.isWon) ...[
            _WonBanner(perk: target, guessCount: game.wrongGuesses.length),
            const SizedBox(height: 24),
          ],

          // ── Input (hidden when won) ──────────────────────────────────────────
          if (!game.isWon) ...[
            _SearchField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              suggestions: _suggestions,
              onSelect: _submitGuess,
            ),
            const SizedBox(height: 24),
          ],

          // ── Wrong guesses list ───────────────────────────────────────────────
          if (game.wrongGuesses.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PREVIOUS GUESSES',
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...game.wrongGuesses.reversed.map(
              (perk) => _WrongGuessChip(perk: perk),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Search Field + Dropdown ──────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final List<Perk> suggestions;
  final ValueChanged<Perk> onSelect;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Type a perk name…',
            prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    color: AppTheme.textSecondary,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: suggestions
                  .map(
                    (perk) => _SuggestionTile(
                      perk: perk,
                      onTap: () => onSelect(perk),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  final Perk perk;
  final VoidCallback onTap;

  const _SuggestionTile({required this.perk, required this.onTap});

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PerkIcon(perk: widget.perk, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.perk.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      widget.perk.character,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.perk.isSurvivor ? 'SURVIVOR' : 'KILLER',
                style: GoogleFonts.rajdhani(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: widget.perk.isSurvivor
                      ? const Color(0xFF4CAF50)
                      : AppTheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wrong Guess Chip ─────────────────────────────────────────────────────────

class _WrongGuessChip extends StatelessWidget {
  final Perk perk;

  const _WrongGuessChip({required this.perk});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          PerkIcon(perk: perk, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              perk.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.close, color: Color(0xFFCC3333), size: 16),
        ],
      ),
    );
  }
}

// ─── Won Banner ───────────────────────────────────────────────────────────────

class _WonBanner extends StatelessWidget {
  final Perk perk;
  final int guessCount;

  const _WonBanner({required this.perk, required this.guessCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            perk.name.toUpperCase(),
            style: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            guessCount == 0
                ? 'First try!'
                : 'Solved in ${guessCount + 1} guess${guessCount + 1 != 1 ? 'es' : ''}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Come back tomorrow for a new perk!',
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
