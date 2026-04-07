import 'package:flutter/material.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/match_record.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/design_system.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  bool _showSurvivor = true;

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _GlowFAB(
        onPressed: () =>
            context.push('/matches/add?survivor=$_showSurvivor'),
      ),
      body: AppBackground(
        orbs: [
          BackgroundOrb(
            color: AppTheme.primary,
            opacity: 0.16,
            position: Alignment.topLeft,
            size: 360,
          ),
          BackgroundOrb(
            color: AppTheme.primaryDim,
            opacity: 0.12,
            position: Alignment.bottomRight,
            size: 320,
          ),
        ],
        child: Column(
          children: [
            PageHeader(
              title: PageHeader.text(
                  AppLocalizations.of(context)!.matchesTitle),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: RoleToggle(
                    isSurvivor: _showSurvivor,
                    onChanged: (v) => setState(() => _showSurvivor = v),
                  ),
                ),
              ],
            ),
            Expanded(
              child: matchesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (all) {
                  final matches = all
                      .where((m) => m.isSurvivor == _showSurvivor)
                      .toList();

                  if (matches.isEmpty) {
                    return EmptyState(
                      icon: Icons.history_outlined,
                      title: AppLocalizations.of(context)!.noMatchesRecorded,
                      subtitle: _showSurvivor
                          ? AppLocalizations.of(context)!.trackSurvivorGames
                          : AppLocalizations.of(context)!.trackKillerGames,
                      action: DbdButton(
                        label: AppLocalizations.of(context)!.addMatch,
                        icon: Icons.add,
                        onPressed: () => context.push(
                            '/matches/add?survivor=$_showSurvivor'),
                      ),
                    );
                  }

                  final wins = matches.where((m) => m.isWin).length;
                  final double rate;
                  if (_showSurvivor) {
                    rate = wins / matches.length;
                  } else {
                    final totalKills = matches.fold<int>(0, (sum, m) {
                      final k =
                          int.tryParse(m.outcome.replaceAll('k', '')) ?? 0;
                      return sum + k;
                    });
                    rate = totalKills / (matches.length * 4);
                  }

                  return Column(
                    children: [
                      _StatsHeader(
                        total: matches.length,
                        wins: wins,
                        winRate: rate,
                        isSurvivor: _showSurvivor,
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: matches.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _MatchTile(
                            record: matches[i],
                            onDelete: () => _confirmDelete(matches[i]),
                          )
                              .animate()
                              .fadeIn(delay: (i * 30).ms)
                              .slideY(begin: 0.05, end: 0),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(MatchRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        title: 'Delete match?',
        content: const Text('This match record will be permanently deleted.'),
        cancelLabel: 'Cancel',
        confirmLabel: 'Delete',
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(matchesProvider.notifier).delete(record.id);
        },
      ),
    );
  }
}

// ─── Stats header ─────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final int total;
  final int wins;
  final double winRate;
  final bool isSurvivor;

  const _StatsHeader({
    required this.total,
    required this.wins,
    required this.winRate,
    required this.isSurvivor,
  });

  @override
  Widget build(BuildContext context) {
    final losses = total - wins;
    final winLabel = isSurvivor ? 'Escapes' : 'Merciless (3-4k)';
    final lossLabel = isSurvivor ? 'Deaths' : 'Sacrificed (0-2k)';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        borderColor: AppTheme.primary.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _StatBox(label: 'Total', value: '$total')),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: winLabel,
                    value: '$wins',
                    color: const Color(0xFF3E9E44),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: lossLabel,
                    value: '$losses',
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isSurvivor ? 'ESCAPE RATE' : 'KILL RATE',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: winRate,
                backgroundColor: AppTheme.border,
                color: AppTheme.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(winRate * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatBox({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Match tile ───────────────────────────────────────────────────────────────

class _MatchTile extends StatefulWidget {
  final MatchRecord record;
  final VoidCallback onDelete;

  const _MatchTile({required this.record, required this.onDelete});

  @override
  State<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<_MatchTile> {
  bool _hovered = false;

  Color get _outcomeColor {
    if (widget.record.isWin) return const Color(0xFF3E9E44);
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.surfaceElevated : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? _outcomeColor.withValues(alpha: 0.4)
                : _outcomeColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _outcomeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _outcomeColor.withValues(alpha: 0.35)),
              ),
              child: Icon(
                widget.record.isWin
                    ? Icons.emoji_events_outlined
                    : Icons.close,
                color: _outcomeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.record.outcomeLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _outcomeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (widget.record.characterName != null) ...[
                        const Icon(Icons.person_outline,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          widget.record.characterName!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (widget.record.mapName != null) ...[
                        if (widget.record.characterName != null)
                          Text('  ·  ',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textTertiary, fontSize: 12)),
                        const Icon(Icons.map_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            widget.record.mapName!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(widget.record.createdAt),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: AppTheme.backgroundSecondary,
              icon: const Icon(Icons.more_vert,
                  color: AppTheme.textTertiary, size: 20),
              onSelected: (v) {
                if (v == 'delete') widget.onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: GoogleFonts.outfit(color: AppTheme.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
        '  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Glowing FAB ─────────────────────────────────────────────────────────────

class _GlowFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _GlowFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
