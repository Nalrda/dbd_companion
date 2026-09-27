import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/models/build.dart';
import '../../core/models/killer.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class BuildsScreen extends ConsumerStatefulWidget {
  const BuildsScreen({super.key});

  @override
  ConsumerState<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends ConsumerState<BuildsScreen> {
  bool _showSurvivor = true;
  bool _showFavoritesOnly = false;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _create() => context.push('/builds/create?survivor=$_showSurvivor');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact = AppLayout.isCompact(context);
    final buildsAsync = ref.watch(buildsProvider);
    final perksById = {
      for (final p in ref.watch(allPerksProvider).valueOrNull ?? const <Perk>[]) p.id: p,
    };
    final killerNames = {
      for (final k in ref.watch(killersProvider).valueOrNull ?? const <Killer>[]) k.id: k.name,
    };

    final all = buildsAsync.valueOrNull ?? const <Build>[];
    final roleCount = all.where((b) => b.isSurvivor == _showSurvivor).length;

    final filters = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoleToggle(
                expand: true,
                isSurvivor: _showSurvivor,
                onChanged: (v) => setState(() => _showSurvivor = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: 8),
                  _favoritesToggle(),
                ],
              ),
            ],
          )
        : Row(
            children: [
              RoleToggle(
                isSurvivor: _showSurvivor,
                onChanged: (v) => setState(() => _showSurvivor = v),
              ),
              const SizedBox(width: 12),
              Expanded(child: _searchField()),
              const SizedBox(width: 8),
              _favoritesToggle(),
            ],
          );

    return Scaffold(
      floatingActionButton:
          compact ? AppFab(label: l10n.createBuild, onPressed: _create) : null,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              title: l10n.myBuilds,
              subtitle: buildsAsync.hasValue
                  ? '$roleCount ${_showSurvivor ? l10n.survivor : l10n.killer} '
                      '${roleCount == 1 ? 'build' : 'builds'}'
                  : null,
              actions: [
                AppIconButton(
                  icon: Icons.download_outlined,
                  tooltip: 'Import build',
                  onPressed: _showImportDialog,
                ),
                if (!compact)
                  AppButton(
                    label: l10n.createBuild,
                    icon: Icons.add,
                    compact: true,
                    onPressed: _create,
                  ),
              ],
              bottom: filters,
            ),
            Expanded(
              child: buildsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(e),
                data: (builds) {
                  var filtered = builds.where((b) => b.isSurvivor == _showSurvivor).toList();
                  if (_showFavoritesOnly) {
                    filtered = filtered.where((b) => b.isFavorite).toList();
                  }
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    filtered = filtered
                        .where((b) =>
                            b.name.toLowerCase().contains(q) ||
                            b.tags.any((t) => t.toLowerCase().contains(q)))
                        .toList();
                  }
                  filtered.sort((a, b) {
                    if (a.isFavorite && !b.isFavorite) return -1;
                    if (!a.isFavorite && b.isFavorite) return 1;
                    return b.updatedAt.compareTo(a.updatedAt);
                  });

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey('$_showSurvivor-$_showFavoritesOnly-${filtered.isEmpty}'),
                      child: filtered.isEmpty
                          ? _empty(l10n)
                          : _list(filtered, perksById, killerNames),
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

  Widget _searchField() => AppSearchField(
        controller: _searchController,
        hint: 'Search builds or tags',
        onChanged: (v) => setState(() => _search = v),
      );

  Widget _favoritesToggle() => AppIconButton(
        icon: _showFavoritesOnly ? Icons.star : Icons.star_outline,
        tooltip: 'Favorites only',
        active: _showFavoritesOnly,
        size: 42,
        onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
      );

  Widget _empty(AppLocalizations l10n) {
    if (_showFavoritesOnly) {
      return const EmptyState(
        icon: Icons.star_outline,
        title: 'No favorites yet',
        subtitle: 'Star a build to pin it here.',
      );
    }
    if (_search.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.noResults,
        subtitle: 'Try a different name or tag.',
      );
    }
    return EmptyState(
      icon: Icons.handyman_outlined,
      title: l10n.noBuildsYet,
      subtitle: _showSurvivor ? l10n.createFirstSurvivorBuild : l10n.createFirstKillerBuild,
      action: AppButton(label: l10n.createBuild, icon: Icons.add, onPressed: _create),
    );
  }

  Widget _list(List<Build> builds, Map<String, Perk> perksById, Map<String, String> killerNames) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = pagePadding(context, top: 4, bottom: 96);
        Widget itemAt(int i) {
          final b = builds[i];
          return _BuildCard(
            item: b,
            perks: b.perkIds.map((id) => perksById[id]).toList(),
            killerName: b.killerId != null ? killerNames[b.killerId] : null,
            onTap: () => context.push('/builds/${b.id}'),
            onEdit: () => context.push('/builds/${b.id}/edit'),
            onDelete: () => _confirmDelete(b),
            onToggleFavorite: () => ref.read(buildsProvider.notifier).toggleFavorite(b.id),
          ).entrance(i);
        }

        final wide = constraints.maxWidth > 760;
        return ContentWidth(
          child: wide
              ? GridView.builder(
                  padding: pad,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 540,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 124,
                  ),
                  itemCount: builds.length,
                  itemBuilder: (_, i) => itemAt(i),
                )
              : ListView.separated(
                  padding: pad,
                  itemCount: builds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => itemAt(i),
                ),
        );
      },
    );
  }

  Future<void> _showImportDialog() async {
    final code = await showAppTextPrompt(
      context,
      title: 'Import build',
      message: 'Paste a build code shared by another player.',
      hint: 'DBD:...',
      confirmLabel: 'Import',
      maxLines: 3,
    );
    if (code == null || !mounted) return;
    final imported = BuildShareService.decode(code);
    if (imported == null) {
      showAppSnack(context, 'Invalid build code', error: true);
      return;
    }
    context.push('/builds/create', extra: imported);
  }

  Future<void> _confirmDelete(Build build) async {
    final ok = await showAppConfirm(
      context,
      title: 'Delete build?',
      message: '"${build.name}" will be removed permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) ref.read(buildsProvider.notifier).delete(build.id);
  }
}

// ─── Build card ───────────────────────────────────────────────────────────────

class _BuildCard extends StatelessWidget {
  final Build item;
  final List<Perk?> perks;
  final String? killerName;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _BuildCard({
    required this.item,
    required this.perks,
    required this.killerName,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (killerName != null) killerName!,
      '${item.perkIds.length}/4 perks',
      _ago(item.updatedAt),
    ].join('  ·  ');

    return AppPanel(
      onTap: onTap,
      edgeColor: item.isFavorite ? AppTheme.primary : null,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(fontSize: 18, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    PerkDiamondRow(perks: perks, size: 36),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          clipBehavior: Clip.hardEdge,
                          children: item.tags.take(3).map((t) => AppTag(t)).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: item.isFavorite ? 'Unfavorite' : 'Favorite',
                visualDensity: VisualDensity.compact,
                onPressed: onToggleFavorite,
                icon: Icon(
                  item.isFavorite ? Icons.star : Icons.star_outline,
                  size: 20,
                  color: item.isFavorite ? AppTheme.primary : AppTheme.textTertiary,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_horiz, size: 20, color: AppTheme.textTertiary),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: AppFonts.body(color: AppTheme.danger)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
  }
}
