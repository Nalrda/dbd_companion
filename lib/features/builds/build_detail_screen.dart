import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/models/addon.dart';
import '../../core/models/build.dart';
import '../../core/models/item.dart';
import '../../core/models/killer.dart';
import '../../core/models/offering.dart';
import '../../core/models/perk.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/addon_repository.dart';
import '../../core/repositories/item_repository.dart';
import '../../core/repositories/killer_repository.dart';
import '../../core/repositories/offering_repository.dart';
import '../../core/repositories/perk_repository.dart';
import '../../core/services/build_share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class BuildDetailScreen extends ConsumerWidget {
  final String buildId;

  const BuildDetailScreen({super.key, required this.buildId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildsAsync = ref.watch(buildsProvider);

    Widget shell(Widget child) => Scaffold(
          body: AppBackground(
            child: Column(
              children: [
                const PageHeader(showBack: true, title: 'Build'),
                Expanded(child: child),
              ],
            ),
          ),
        );

    return buildsAsync.when(
      loading: () => shell(const LoadingView()),
      error: (e, _) => shell(ErrorView(e)),
      data: (builds) {
        final build = builds.where((b) => b.id == buildId).firstOrNull;
        if (build == null) {
          return shell(const EmptyState(
            icon: Icons.search_off,
            title: 'Build not found',
            subtitle: 'It may have been deleted.',
          ));
        }
        return _BuildDetailView(build: build);
      },
    );
  }
}

class _BuildDetailView extends ConsumerStatefulWidget {
  final Build build;
  const _BuildDetailView({required this.build});

  @override
  ConsumerState<_BuildDetailView> createState() => _BuildDetailViewState();
}

class _BuildDetailViewState extends ConsumerState<_BuildDetailView> {
  List<Perk> _perks = [];
  bool _perksLoaded = false;
  Item? _item;
  Offering? _offering;
  Killer? _killer;
  Addon? _addon1;
  Addon? _addon2;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(_BuildDetailView old) {
    super.didUpdateWidget(old);
    // The provider hands us a fresh object after edits / favorite toggles.
    if (!identical(old.build, widget.build)) _loadData();
  }

  Future<void> _loadData() async {
    final perks = await PerkRepository.instance.getPerksByIds(widget.build.perkIds);
    final item = widget.build.itemId != null
        ? await ItemRepository.instance.getById(widget.build.itemId!)
        : null;
    final offering = widget.build.offeringId != null
        ? await OfferingRepository.instance.getById(widget.build.offeringId!)
        : null;
    final killer = widget.build.killerId != null
        ? (await KillerRepository.instance.getAll())
            .cast<Killer?>()
            .firstWhere((k) => k?.id == widget.build.killerId, orElse: () => null)
        : null;
    final addon1 = widget.build.addon1 != null
        ? await AddonRepository.instance.getById(widget.build.addon1!)
        : null;
    final addon2 = widget.build.addon2 != null
        ? await AddonRepository.instance.getById(widget.build.addon2!)
        : null;
    if (mounted) {
      setState(() {
        _perks = perks;
        _perksLoaded = true;
        _item = item;
        _offering = offering;
        _killer = killer;
        _addon1 = addon1;
        _addon2 = addon2;
      });
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _edit() => context.push('/builds/${widget.build.id}/edit');

  void _toggleFavorite() => ref.read(buildsProvider.notifier).toggleFavorite(widget.build.id);

  Future<void> _delete() async {
    final ok = await showAppConfirm(
      context,
      title: 'Delete build?',
      message: '"${widget.build.name}" will be removed permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final notifier = ref.read(buildsProvider.notifier);
    final id = widget.build.id;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/builds');
    }
    await notifier.delete(id);
  }

  void _showShareSheet() {
    final code = BuildShareService.encode(widget.build);
    showAppSheet<void>(
      context,
      maxWidth: 520,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(
              title: 'Share build',
              subtitle: 'Copy the code below and send it to another player.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPanel(
                    cut: 8,
                    color: AppTheme.background.withValues(alpha: 0.6),
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(
                      code,
                      style: AppFonts.body(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Copy code',
                    icon: Icons.copy,
                    expand: true,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      Navigator.pop(ctx);
                      showAppSnack(context, 'Build code copied to clipboard');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = AppLayout.isCompact(context);
    final b = widget.build;
    final roleLabel = b.isSurvivor ? (l10n?.survivor ?? 'Survivor') : (l10n?.killer ?? 'Killer');

    final actions = <Widget>[
      AppIconButton(
        icon: b.isFavorite ? Icons.star : Icons.star_outline,
        tooltip: b.isFavorite ? 'Remove from favorites' : 'Add to favorites',
        active: b.isFavorite,
        onPressed: _toggleFavorite,
      ),
      AppIconButton(
        icon: Icons.delete_outline,
        tooltip: 'Delete build',
        onPressed: _delete,
      ),
      if (!compact) ...[
        AppButton.secondary(
          label: 'Share code',
          icon: Icons.ios_share_outlined,
          compact: true,
          onPressed: _showShareSheet,
        ),
        AppButton(
          label: 'Edit build',
          icon: Icons.edit_outlined,
          compact: true,
          onPressed: _edit,
        ),
      ],
    ];

    return Scaffold(
      bottomNavigationBar: compact ? _bottomBar() : null,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              showBack: true,
              title: '$roleLabel build',
              titleWidget: Row(
                children: [
                  DiamondMark(size: 6, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '$roleLabel build'.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.caption(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              actions: actions,
            ),
            Expanded(
              child: ContentWidth(
                child: SingleChildScrollView(
                  padding: pagePadding(context, top: compact ? 6 : 10, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(compact, roleLabel).entrance(0),
                      SizedBox(height: compact ? 20 : 28),
                      _perksPanel(compact).entrance(1),
                      SizedBox(height: compact ? 12 : 16),
                      _details(compact).entrance(2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'Share',
                  icon: Icons.ios_share_outlined,
                  expand: true,
                  onPressed: _showShareSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Edit build',
                  icon: Icons.edit_outlined,
                  expand: true,
                  onPressed: _edit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(bool compact, String roleLabel) {
    final b = widget.build;
    final metaStyle = AppFonts.body(fontSize: 13.5, color: AppTheme.textTertiary);
    final dot = Text('·', style: metaStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          b.name.toUpperCase(),
          style: AppFonts.display(
            fontSize: compact ? 34 : 48,
            fontWeight: FontWeight.w700,
            letterSpacing: compact ? 1.2 : 1.8,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RoleBadge(isSurvivor: b.isSurvivor, label: roleLabel),
            if (_killer != null) ...[
              Text(
                _killer!.name,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              dot,
            ],
            Text('Updated ${_ago(b.updatedAt)}', style: metaStyle),
            if (!compact) ...[
              dot,
              Text('Created ${_date(b.createdAt)}', style: metaStyle),
            ],
          ],
        ),
      ],
    );
  }

  Widget _perksPanel(bool compact) {
    final b = widget.build;
    final byId = {for (final p in _perks) p.id: p};
    final slots = List<Perk?>.generate(
      4,
      (i) => i < b.perkIds.length ? byId[b.perkIds[i]] : null,
    );
    final loading = !_perksLoaded && b.perkIds.isNotEmpty;

    return AppPanel(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 16, compact ? 12 : 24, compact ? 18 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 0),
            child: SectionLabel(title: 'Perks', count: '${b.perkIds.length}/4'),
          ),
          SizedBox(height: compact ? 18 : 26),
          if (loading)
            const SizedBox(height: 120, child: LoadingView())
          else if (b.perkIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No perks added to this build.',
                textAlign: TextAlign.center,
                style: AppFonts.body(color: AppTheme.textSecondary),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cell = c.maxWidth / 4;
                final diamond = (cell - (compact ? 10 : 36)).clamp(56.0, 120.0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: _PerkColumn(
                          perk: slots[i],
                          index: i,
                          size: diamond,
                          compact: compact,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _details(bool compact) {
    final b = widget.build;
    final loadoutRows = <Widget>[
      if (!b.isSurvivor && _killer != null)
        _InfoRow(
          leading: SquareGlyph(
            icon: Icons.local_fire_department_outlined,
            color: AppTheme.primary,
            size: 40,
          ),
          caption: 'Killer',
          title: _killer!.name,
          subtitle: _killer!.power,
        ),
      if (b.isSurvivor && _item != null)
        _InfoRow(
          leading: ItemIcon(item: _item!, size: 40),
          caption: 'Item',
          title: _item!.name,
          rarity: _item!.rarity,
          rarityColor: AppTheme.rarityColor(_item!.rarity),
        ),
      for (final a in [_addon1, _addon2])
        if (a != null)
          _InfoRow(
            leading: SquareGlyph(
              icon: Icons.extension_outlined,
              color: AppTheme.rarityColor(a.rarity),
              size: 40,
            ),
            caption: 'Add-on',
            title: a.name,
            rarity: a.rarity,
            rarityColor: AppTheme.rarityColor(a.rarity),
          ),
      if (_offering != null)
        _InfoRow(
          leading: SquareGlyph(
            icon: offeringCategoryIcon(_offering!.category),
            color: offeringRarityColor(_offering!.rarity),
            size: 40,
          ),
          caption: 'Offering',
          title: _offering!.name,
          rarity: _offering!.rarity,
          rarityColor: offeringRarityColor(_offering!.rarity),
        ),
    ];

    final hasNotes = b.notes != null && b.notes!.trim().isNotEmpty;
    final hasTags = b.tags.isNotEmpty;

    final loadout = loadoutRows.isEmpty
        ? null
        : AppPanel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel(title: 'Loadout'),
                const SizedBox(height: 12),
                for (final r in loadoutRows)
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: r),
              ],
            ),
          );

    final notesAndTags = !hasNotes && !hasTags
        ? null
        : AppPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasNotes) ...[
                  const SectionLabel(title: 'Notes'),
                  const SizedBox(height: 12),
                  SelectableText(
                    b.notes!.trim(),
                    style: AppFonts.body(
                      fontSize: 14.5,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
                if (hasNotes && hasTags) const SizedBox(height: 20),
                if (hasTags) ...[
                  SectionLabel(title: 'Tags', count: '${b.tags.length}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: b.tags.map((t) => AppTag(t)).toList(),
                  ),
                ],
              ],
            ),
          );

    if (loadout == null && notesAndTags == null) return const SizedBox.shrink();

    if (compact || loadout == null || notesAndTags == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loadout != null) loadout,
          if (loadout != null && notesAndTags != null) const SizedBox(height: 12),
          if (notesAndTags != null) notesAndTags,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: loadout),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: notesAndTags),
      ],
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return _date(t);
  }

  static String _date(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
}

// ─── Pieces ───────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final bool isSurvivor;
  final String label;

  const _RoleBadge({required this.isSurvivor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: ShapeDecoration(
        color: AppTheme.primarySoft,
        shape: AppShapes.notched(
          cut: 5,
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSurvivor ? Icons.directions_run : Icons.local_fire_department_outlined,
            size: 14,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppFonts.display(fontSize: 13, color: AppTheme.textPrimary, letterSpacing: 1.3),
          ),
        ],
      ),
    );
  }
}

/// One perk shown large: diamond, name and owner, centered in its column.
class _PerkColumn extends StatelessWidget {
  final Perk? perk;
  final int index;
  final double size;
  final bool compact;

  const _PerkColumn({
    required this.perk,
    required this.index,
    required this.size,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final p = perk;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          if (p != null)
            Tooltip(message: p.name, child: PerkIcon(perk: p, size: size))
          else
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: DiamondFramePainter(
                  fill: AppTheme.background.withValues(alpha: 0.5),
                  stroke: AppTheme.border,
                ),
              ),
            ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            p?.name ?? 'Empty slot',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.body(
              fontSize: compact ? 13 : 15.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: p != null ? AppTheme.textPrimary : AppTheme.textTertiary,
            ),
          ),
          if (p != null && p.character.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              p.character,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(fontSize: compact ? 11.5 : 12.5, color: AppTheme.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Widget leading;
  final String caption;
  final String title;
  final String? subtitle;
  final String? rarity;
  final Color? rarityColor;

  const _InfoRow({
    required this.leading,
    required this.caption,
    required this.title,
    this.subtitle,
    this.rarity,
    this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    final showRarity = rarity != null && rarity != 'none' && rarity!.isNotEmpty;
    return AppPanel(
      cut: 7,
      color: AppTheme.background.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(caption.toUpperCase(), style: AppFonts.caption(fontSize: 10.5)),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
                  ),
              ],
            ),
          ),
          if (showRarity) ...[
            const SizedBox(width: 8),
            AppTag(rarity!.replaceAll('_', ' '), color: rarityColor),
          ],
        ],
      ),
    );
  }
}
