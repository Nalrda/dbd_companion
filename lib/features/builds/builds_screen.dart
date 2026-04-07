import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/models/build.dart';
import '../../core/providers/providers.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/design_system.dart';

class BuildsScreen extends ConsumerStatefulWidget {
  const BuildsScreen({super.key});

  @override
  ConsumerState<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends ConsumerState<BuildsScreen> {
  bool _showSurvivor = true;
  bool _showFavoritesOnly = false;
  String _search = '';
  bool _searchVisible = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildsAsync = ref.watch(buildsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _GlowFAB(
        onPressed: () =>
            context.push('/builds/create?survivor=$_showSurvivor'),
      ),
      body: AppBackground(
        orbs: [
          BackgroundOrb(
            color: AppTheme.primary,
            opacity: 0.18,
            position: Alignment.topRight,
            size: 380,
          ),
        ],
        child: Column(
          children: [
            PageHeader(
              title: _searchVisible
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search builds...',
                        border: InputBorder.none,
                        hintStyle:
                            GoogleFonts.outfit(color: AppTheme.textTertiary),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    )
                  : PageHeader.text(
                      AppLocalizations.of(context)!.myBuilds),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  color: AppTheme.textSecondary,
                  tooltip: 'Import build',
                  onPressed: _showImportDialog,
                ),
                IconButton(
                  icon: Icon(
                    _searchVisible ? Icons.close : Icons.search,
                    color: _searchVisible
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() {
                    _searchVisible = !_searchVisible;
                    if (!_searchVisible) {
                      _search = '';
                      _searchController.clear();
                    }
                  }),
                ),
                IconButton(
                  icon: Icon(
                    _showFavoritesOnly ? Icons.star : Icons.star_outline,
                    color: _showFavoritesOnly
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                  tooltip: 'Favorites only',
                  onPressed: () =>
                      setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                ),
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
              child: buildsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (builds) {
                  var filtered =
                      builds.where((b) => b.isSurvivor == _showSurvivor).toList();

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

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: _showFavoritesOnly
                          ? Icons.star_outline
                          : _search.isNotEmpty
                              ? Icons.search_off
                              : Icons.build_outlined,
                      title: _showFavoritesOnly
                          ? 'No favorites yet'
                          : _search.isNotEmpty
                              ? 'No results'
                              : AppLocalizations.of(context)!.noBuildsYet,
                      subtitle: _showFavoritesOnly
                          ? 'Star a build to add it here'
                          : _search.isNotEmpty
                              ? 'Try a different search'
                              : _showSurvivor
                                  ? AppLocalizations.of(context)!
                                      .createFirstSurvivorBuild
                                  : AppLocalizations.of(context)!
                                      .createFirstKillerBuild,
                      action: (_showFavoritesOnly || _search.isNotEmpty)
                          ? null
                          : DbdButton(
                              label:
                                  AppLocalizations.of(context)!.createBuild,
                              icon: Icons.add,
                              onPressed: () => context.push(
                                  '/builds/create?survivor=$_showSurvivor'),
                            ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 110,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _BuildListItem(
                              item: filtered[index],
                              onTap: () => context
                                  .push('/builds/${filtered[index].id}'),
                              onDelete: () => _confirmDelete(filtered[index]),
                              onToggleFavorite: () => ref
                                  .read(buildsProvider.notifier)
                                  .toggleFavorite(filtered[index].id),
                            )
                                .animate()
                                .fadeIn(delay: (index * 30).ms)
                                .slideY(begin: 0.05, end: 0);
                          },
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _BuildListItem(
                            item: filtered[index],
                            onTap: () =>
                                context.push('/builds/${filtered[index].id}'),
                            onDelete: () => _confirmDelete(filtered[index]),
                            onToggleFavorite: () => ref
                                .read(buildsProvider.notifier)
                                .toggleFavorite(filtered[index].id),
                          )
                              .animate()
                              .fadeIn(delay: (index * 40).ms)
                              .slideY(begin: 0.05, end: 0);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: 'Import Build',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a build code shared by another player.',
              style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary, fontSize: 13),
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'DBD:...'),
            ),
          ],
        ),
        cancelLabel: 'Cancel',
        confirmLabel: 'Import',
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () {
          final imported = BuildShareService.decode(controller.text);
          if (imported == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid build code')),
            );
            return;
          }
          Navigator.pop(ctx);
          context.push('/builds/create', extra: imported);
        },
      ),
    );
  }

  void _confirmDelete(Build build) {
    showDialog(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: 'Delete build?',
        content: Text(
          'Are you sure you want to delete "${build.name}"?',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
        ),
        cancelLabel: 'Cancel',
        confirmLabel: 'Delete',
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () {
          Navigator.pop(ctx);
          ref.read(buildsProvider.notifier).delete(build.id);
        },
      ),
    );
  }
}

// ─── Build List Item ──────────────────────────────────────────────────────────

class _BuildListItem extends StatefulWidget {
  final Build item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _BuildListItem({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  State<_BuildListItem> createState() => _BuildListItemState();
}

class _BuildListItemState extends State<_BuildListItem> {
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.surfaceElevated
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.item.isFavorite
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : _hovered
                      ? AppTheme.borderHighlight
                      : AppTheme.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
              if (widget.item.isFavorite)
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
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
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.2),
                      AppTheme.primaryDim.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  widget.item.isSurvivor
                      ? Icons.person
                      : Icons.sports_kabaddi,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.item.name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.item.perkIds.length}/4 perks',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (widget.item.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: widget.item.tags
                            .take(3)
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    t,
                                    style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onToggleFavorite,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    widget.item.isFavorite ? Icons.star : Icons.star_outline,
                    color: widget.item.isFavorite
                        ? AppTheme.primary
                        : AppTheme.textTertiary,
                    size: 20,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                color: AppTheme.backgroundSecondary,
                icon: Icon(Icons.more_vert,
                    color: AppTheme.textTertiary, size: 20),
                onSelected: (v) {
                  if (v == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: GoogleFonts.outfit(
                            color: AppTheme.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Glass Dialog ─────────────────────────────────────────────────────────────

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _GlassDialog({
    required this.title,
    required this.content,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.border),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppTheme.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: content,
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelLabel,
              style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text(confirmLabel,
              style: GoogleFonts.outfit(color: AppTheme.primary)),
        ),
      ],
    );
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
