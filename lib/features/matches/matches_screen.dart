import 'package:flutter/material.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/match_record.dart';
import '../../core/models/perk.dart';
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

  void _add() => context.push('/matches/add?survivor=$_showSurvivor');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact = AppLayout.isCompact(context);
    final matchesAsync = ref.watch(matchesProvider);
    final perksById = {
      for (final p in ref.watch(allPerksProvider).valueOrNull ?? const <Perk>[]) p.id: p,
    };

    final all = matchesAsync.valueOrNull ?? const <MatchRecord>[];
    final roleCount = all.where((m) => m.isSurvivor == _showSurvivor).length;

    final roleToggle = RoleToggle(
      expand: compact,
      isSurvivor: _showSurvivor,
      onChanged: (v) => setState(() => _showSurvivor = v),
    );

    return Scaffold(
      floatingActionButton: compact ? AppFab(label: l10n.addMatch, onPressed: _add) : null,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              title: l10n.matchesTitle,
              subtitle: matchesAsync.hasValue
                  ? '$roleCount ${_showSurvivor ? l10n.survivor : l10n.killer} '
                      '${roleCount == 1 ? 'match' : 'matches'}'
                  : null,
              actions: [
                if (!compact)
                  AppButton(
                    label: l10n.addMatch,
                    icon: Icons.add,
                    compact: true,
                    onPressed: _add,
                  ),
              ],
              bottom: compact ? roleToggle : Row(children: [roleToggle]),
            ),
            Expanded(
              child: matchesAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(e),
                data: (all) {
                  final matches = all.where((m) => m.isSurvivor == _showSurvivor).toList();

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey('$_showSurvivor-${matches.isEmpty}'),
                      child: matches.isEmpty
                          ? EmptyState(
                              icon: Icons.history_outlined,
                              title: l10n.noMatchesRecorded,
                              subtitle: _showSurvivor
                                  ? l10n.trackSurvivorGames
                                  : l10n.trackKillerGames,
                              action: AppButton(
                                label: l10n.addMatch,
                                icon: Icons.add,
                                onPressed: _add,
                              ),
                            )
                          : _content(matches, perksById, compact),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<MatchRecord> matches, Map<String, Perk> perksById, bool compact) {
    final wins = matches.where((m) => m.isWin).length;
    final double rate;
    if (_showSurvivor) {
      rate = wins / matches.length;
    } else {
      final totalKills = matches.fold<int>(0, (sum, m) {
        final k = int.tryParse(m.outcome.replaceAll('k', '')) ?? 0;
        return sum + k;
      });
      rate = totalKills / (matches.length * 4);
    }

    final stats = _StatsStrip(
      total: matches.length,
      wins: wins,
      rate: rate,
      isSurvivor: _showSurvivor,
      compact: compact,
    );

    List<Perk?> perksOf(MatchRecord m) => m.perkIds.map((id) => perksById[id]).toList();

    if (compact) {
      return ContentWidth(
        child: ListView.separated(
          padding: pagePadding(context, top: 2, bottom: 96),
          itemCount: matches.length + 2,
          separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 20 : (i == 1 ? 12 : 6)),
          itemBuilder: (_, i) {
            if (i == 0) return stats;
            if (i == 1) {
              return SectionLabel(title: 'History', count: '${matches.length}');
            }
            final m = matches[i - 2];
            return _MatchRow(
              record: m,
              perks: perksOf(m),
              onDelete: () => _confirmDelete(m),
            ).entrance(i - 2);
          },
        ),
      );
    }

    return ContentWidth(
      child: ListView(
        padding: pagePadding(context, top: 2, bottom: 32),
        children: [
          stats,
          const SizedBox(height: 26),
          SectionLabel(title: 'History', count: '${matches.length}'),
          const SizedBox(height: 12),
          _MatchTable(
            matches: matches,
            isSurvivor: _showSurvivor,
            perksOf: perksOf,
            onDelete: _confirmDelete,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(MatchRecord record) async {
    final ok = await showAppConfirm(
      context,
      title: 'Delete match?',
      message: 'This match record will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) ref.read(matchesProvider.notifier).delete(record.id);
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Color _outcomeColor(MatchRecord m) => m.isWin ? AppTheme.success : AppTheme.danger;

String _characterLabel(bool isSurvivor) => isSurvivor ? 'Killer faced' : 'Killer played';

String _when(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
}

String _fullDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
    '  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

// ─── Stats strip ──────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final int total;
  final int wins;
  final double rate;
  final bool isSurvivor;
  final bool compact;

  const _StatsStrip({
    required this.total,
    required this.wins,
    required this.rate,
    required this.isSurvivor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final losses = total - wins;
    final winLabel = isSurvivor ? 'Escapes' : 'Merciless 3–4k';
    final lossLabel = isSurvivor ? 'Deaths' : 'Below 3k';

    final tiles = [
      StatTile(label: 'Total', value: '$total'),
      StatTile(label: winLabel, value: '$wins', color: AppTheme.success),
      StatTile(label: lossLabel, value: '$losses', color: AppTheme.danger),
    ];

    final rateBlock = _RateBar(
      label: isSurvivor ? 'Escape rate' : 'Kill rate',
      rate: rate,
      large: !compact,
    );

    if (compact) {
      return AppPanel(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [for (final t in tiles) Expanded(child: t)]),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),
            rateBlock,
          ],
        ),
      );
    }

    Widget divider() => Container(
          width: 1,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          color: AppTheme.border,
        );

    return AppPanel(
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 18),
      child: Row(
        children: [
          for (final t in tiles) ...[Expanded(child: t), divider()],
          Expanded(flex: 3, child: rateBlock),
        ],
      ),
    );
  }
}

class _RateBar extends StatelessWidget {
  final String label;
  final double rate;
  final bool large;

  const _RateBar({required this.label, required this.rate, this.large = false});

  @override
  Widget build(BuildContext context) {
    final pct = '${(rate * 100).toStringAsFixed(1)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(label.toUpperCase(), style: AppFonts.caption(color: AppTheme.textSecondary)),
            ),
            Text(
              pct,
              style: AppFonts.display(
                fontSize: large ? 30 : 22,
                color: AppTheme.primary,
                letterSpacing: 0.5,
                height: 1.05,
              ),
            ),
          ],
        ),
        SizedBox(height: large ? 10 : 8),
        _ThinBar(value: rate),
      ],
    );
  }
}

/// 3 px track with a primary fill and a small diamond at the head.
class _ThinBar extends StatelessWidget {
  final double value;
  const _ThinBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 9,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 3, color: AppTheme.border),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: v),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, t, __) => Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(height: 3, width: w * t, color: AppTheme.primary),
                    Positioned(
                      left: (w * t - 4.5).clamp(0.0, w - 9),
                      child: DiamondMark(size: 6.4, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Outcome marker ───────────────────────────────────────────────────────────

/// Diamond tinted by outcome: an exit / cross glyph for survivor matches,
/// the kill count for killer matches.
class _OutcomeMarker extends StatelessWidget {
  final MatchRecord record;
  final double size;

  const _OutcomeMarker({required this.record, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = _outcomeColor(record);
    final Widget glyph = record.isSurvivor
        ? Icon(
            record.isWin ? Icons.directions_run : Icons.close,
            size: size * 0.4,
            color: c,
          )
        : Text(
            record.outcome.toUpperCase(),
            style: AppFonts.display(fontSize: size * 0.34, color: c, letterSpacing: 0.4),
          );
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: DiamondFramePainter(
          fill: Color.alphaBlend(c.withValues(alpha: 0.14), AppTheme.surface),
          stroke: c.withValues(alpha: 0.75),
        ),
        child: Center(child: glyph),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  final VoidCallback onDelete;
  const _RowMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(Icons.more_horiz, size: 20, color: AppTheme.textTertiary),
      onSelected: (v) {
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
              const SizedBox(width: 10),
              Text('Delete', style: AppFonts.body(color: AppTheme.danger)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Match row (phone) ────────────────────────────────────────────────────────

class _MatchRow extends StatelessWidget {
  final MatchRecord record;
  final List<Perk?> perks;
  final VoidCallback onDelete;

  const _MatchRow({required this.record, required this.perks, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = _outcomeColor(record);
    final meta = [
      if (record.characterName != null) record.characterName!,
      if (record.mapName != null) record.mapName!,
    ].join('  ·  ');
    final gens = record.gensRemaining;

    return AppPanel(
      cut: 8,
      padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
      child: Row(
        children: [
          _OutcomeMarker(record: record, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              record.outcomeLabel.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.display(fontSize: 17, color: c, letterSpacing: 1.1),
                            ),
                          ),
                          if (gens != null) ...[
                            const SizedBox(width: 8),
                            AppTag('$gens ${gens == 1 ? 'gen' : 'gens'} left'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _when(record.createdAt),
                      style: AppFonts.body(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  meta.isEmpty ? 'No details' : meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 13,
                    color: meta.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary,
                  ),
                ),
                if (perks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  HeroMode(
                    enabled: false,
                    child: PerkDiamondRow(perks: perks, size: 26),
                  ),
                ],
              ],
            ),
          ),
          _RowMenu(onDelete: onDelete),
        ],
      ),
    );
  }
}

// ─── Match table (wide) ───────────────────────────────────────────────────────

class _MatchTable extends StatelessWidget {
  final List<MatchRecord> matches;
  final bool isSurvivor;
  final List<Perk?> Function(MatchRecord) perksOf;
  final ValueChanged<MatchRecord> onDelete;

  const _MatchTable({
    required this.matches,
    required this.isSurvivor,
    required this.perksOf,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final showPerks = matches.any((m) => m.perkIds.isNotEmpty);

    Widget cells({
      required Widget result,
      required Widget character,
      required Widget map,
      Widget? gens,
      Widget? perks,
      required Widget date,
      required Widget trailing,
    }) {
      return Row(
        children: [
          SizedBox(width: 170, child: result),
          Expanded(flex: 3, child: character),
          Expanded(flex: 3, child: map),
          if (!isSurvivor) SizedBox(width: 90, child: gens),
          if (showPerks) SizedBox(width: 128, child: perks),
          SizedBox(width: 150, child: date),
          SizedBox(width: 44, child: trailing),
        ],
      );
    }

    Text head(String s) => Text(s.toUpperCase(), style: AppFonts.caption());
    Text cell(String? s) => Text(
          s ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.body(
            fontSize: 14,
            color: s == null ? AppTheme.textTertiary : AppTheme.textPrimary,
          ),
        );

    return AppPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 10),
            child: cells(
              result: head('Result'),
              character: head(_characterLabel(isSurvivor)),
              map: head('Map'),
              gens: head('Gens left'),
              perks: head('Perks'),
              date: head('Date'),
              trailing: const SizedBox(),
            ),
          ),
          for (var i = 0; i < matches.length; i++) ...[
            const Divider(),
            _TableRow(
              child: cells(
                result: Row(
                  children: [
                    _OutcomeMarker(record: matches[i], size: 32),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        matches[i].outcomeLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.display(
                          fontSize: 16,
                          color: _outcomeColor(matches[i]),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                character: cell(matches[i].characterName),
                map: cell(matches[i].mapName),
                gens: Text(
                  matches[i].gensRemaining?.toString() ?? '—',
                  style: AppFonts.display(fontSize: 17, color: AppTheme.textSecondary),
                ),
                perks: HeroMode(
                  enabled: false,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: matches[i].perkIds.isEmpty
                        ? Text('—', style: AppFonts.body(color: AppTheme.textTertiary))
                        : PerkDiamondRow(perks: perksOf(matches[i]), size: 28, spacing: 2),
                  ),
                ),
                date: Tooltip(
                  message: _fullDate(matches[i].createdAt),
                  child: Text(
                    _when(matches[i].createdAt),
                    style: AppFonts.body(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
                trailing: _RowMenu(onDelete: () => onDelete(matches[i])),
              ),
            ).entrance(i),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final Widget child;
  const _TableRow({required this.child});

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        color: _hovered ? AppTheme.surfaceElevated : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
        child: widget.child,
      ),
    );
  }
}
