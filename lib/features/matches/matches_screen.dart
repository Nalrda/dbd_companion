import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/match_record.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

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
      appBar: AppBar(
        title: const Text('Match Tracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: RoleToggle(
              isSurvivor: _showSurvivor,
              onChanged: (v) => setState(() => _showSurvivor = v),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/matches/add?survivor=$_showSurvivor'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final matches = all.where((m) => m.isSurvivor == _showSurvivor).toList();

          if (matches.isEmpty) {
            return EmptyState(
              icon: Icons.history_outlined,
              title: 'No matches recorded',
              subtitle: _showSurvivor
                  ? 'Track your survivor games here'
                  : 'Track your killer games here',
              action: DbdButton(
                label: 'Add Match',
                icon: Icons.add,
                onPressed: () => context.push('/matches/add?survivor=$_showSurvivor'),
              ),
            );
          }

          final wins = matches.where((m) => m.isWin).length;
          final winRate = matches.isEmpty ? 0.0 : wins / matches.length;

          return Column(
            children: [
              _StatsHeader(
                total: matches.length,
                wins: wins,
                winRate: winRate,
                isSurvivor: _showSurvivor,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _MatchTile(
                    record: matches[i],
                    onDelete: () => _confirmDelete(matches[i]),
                  ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.04, end: 0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(MatchRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete match?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This match record will be permanently deleted.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(matchesProvider.notifier).delete(record.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
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

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(color: AppTheme.primaryGlow, blurRadius: 16, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBox(label: 'Total', value: '$total'),
              ),
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
          const SizedBox(height: 12),
          Text(
            'WIN RATE',
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: winRate,
              backgroundColor: AppTheme.border,
              color: AppTheme.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(winRate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
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

class _MatchTile extends StatelessWidget {
  final MatchRecord record;
  final VoidCallback onDelete;

  const _MatchTile({required this.record, required this.onDelete});

  Color get _outcomeColor {
    if (record.isWin) return const Color(0xFF3E9E44);
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _outcomeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _outcomeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _outcomeColor.withValues(alpha: 0.4)),
            ),
            child: Icon(
              record.isWin ? Icons.emoji_events_outlined : Icons.close,
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
                  record.outcomeLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _outcomeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (record.characterName != null) ...[
                      const Icon(Icons.person_outline,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        record.characterName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (record.mapName != null) ...[
                      if (record.characterName != null)
                        const Text('  ·  ',
                            style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                      const Icon(Icons.map_outlined,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          record.mapName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!record.isSurvivor && record.gensRemaining != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.bolt_outlined,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${record.gensRemaining} gens remaining',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatDate(record.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppTheme.surfaceElevated,
            icon: const Icon(Icons.more_vert, color: AppTheme.textDim, size: 20),
            onSelected: (v) {
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
