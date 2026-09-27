import 'package:flutter/material.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/map_callout.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters realms by the search query. A realm-name match keeps all of its
  /// maps; otherwise only maps whose name or main building match are kept.
  List<MapRealm> _filter(List<MapRealm> realms) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return realms;
    final result = <MapRealm>[];
    for (final r in realms) {
      if (r.realm.toLowerCase().contains(q)) {
        result.add(r);
        continue;
      }
      final maps = r.maps
          .where((m) =>
              m.name.toLowerCase().contains(q) || m.mainBuilding.toLowerCase().contains(q))
          .toList();
      if (maps.isNotEmpty) result.add(MapRealm(id: r.id, realm: r.realm, maps: maps));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final realmsAsync = ref.watch(mapRealmsProvider);
    final all = realmsAsync.valueOrNull ?? const <MapRealm>[];
    final total = all.fold<int>(0, (n, r) => n + r.maps.length);
    final filtered = _filter(all);
    final shown = filtered.fold<int>(0, (n, r) => n + r.maps.length);

    String? subtitle;
    if (realmsAsync.hasValue) {
      subtitle = _search.trim().isEmpty
          ? '$total maps across ${all.length} realms'
          : '$shown of $total maps';
    }

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              title: l10n.mapsTitle,
              subtitle: subtitle,
              bottom: AppSearchField(
                controller: _searchController,
                hint: 'Search maps, realms or buildings',
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: realmsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(e),
                data: (_) => filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: l10n.noResults,
                        subtitle: 'Try a different map or realm name.',
                      )
                    : _content(filtered),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<MapRealm> realms) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = pagePadding(context, top: 4, bottom: 32);
        final wide = constraints.maxWidth > 760;
        var index = 0;

        final slivers = <Widget>[];
        for (var r = 0; r < realms.length; r++) {
          final realm = realms[r];
          slivers.add(SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: r == 0 ? 4 : 26, bottom: 12),
              child: SectionLabel(title: realm.realm, count: '${realm.maps.length}'),
            ),
          ));

          final start = index;
          index += realm.maps.length;
          void open(DbdMap m) => context.push('/maps/${realm.id}/${m.id}');

          if (wide) {
            slivers.add(SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 262,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _MapCard(
                  map: realm.maps[i],
                  onTap: () => open(realm.maps[i]),
                ).entrance(start + i),
                childCount: realm.maps.length,
              ),
            ));
          } else {
            slivers.add(SliverList.separated(
              itemCount: realm.maps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _MapRow(
                map: realm.maps[i],
                onTap: () => open(realm.maps[i]),
              ).entrance(start + i),
            ));
          }
        }

        return ContentWidth(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: pad,
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────

/// Desaturated preview of the callout image, so the bright map art doesn't
/// fight with the accent color in lists.
class MapThumbnail extends StatelessWidget {
  final String image;
  final BoxFit fit;
  final Alignment alignment;

  const MapThumbnail({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.bottomCenter,
  });

  // Luminance with boosted contrast: the navy backdrop drops to black, the
  // periwinkle floor plan becomes a dark warm grey and labels stay light.
  static const _muted = ColorFilter.matrix(<double>[
    0.26, 0.78, 0.26, 0, -122, //
    0.26, 0.78, 0.26, 0, -127, //
    0.26, 0.78, 0.26, 0, -130, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    // The filter is applied while painting the image (DecorationImage), not via
    // ColorFiltered, which would add an offscreen layer per thumbnail and make
    // the grid stutter while scrolling. Map art is opaque, so the fallback
    // icon underneath only shows if the asset is missing.
    return ColoredBox(
      color: AppTheme.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Center(child: Icon(Icons.map_outlined, color: AppTheme.textTertiary, size: 22)),
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: ResizeImage(AssetImage(image), width: 400),
                fit: fit,
                alignment: alignment,
                colorFilter: _muted,
                filterQuality: FilterQuality.medium,
                onError: (_, __) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map row (phones) ─────────────────────────────────────────────────────────

class _MapRow extends StatelessWidget {
  final DbdMap map;
  final VoidCallback onTap;

  const _MapRow({required this.map, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      cut: 8,
      child: Row(
        children: [
          ClipPath(
            clipper: ShapeBorderClipper(shape: AppShapes.notched(cut: 6)),
            child: SizedBox(width: 52, height: 52, child: MapThumbnail(image: map.image)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  map.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(fontSize: 17, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  'Main: ${map.mainBuilding}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 12.5, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppTheme.textTertiary),
        ],
      ),
    );
  }
}

// ─── Map card (wide) ──────────────────────────────────────────────────────────

class _MapCard extends StatelessWidget {
  final DbdMap map;
  final VoidCallback onTap;

  const _MapCard({required this.map, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(1, 1, 1, 0),
              child: ClipPath(
                clipper: const ShapeBorderClipper(shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(9)),
                )),
                child: MapThumbnail(image: map.image),
              ),
            ),
          ),
          Container(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  map.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(fontSize: 16, letterSpacing: 1),
                ),
                const SizedBox(height: 1),
                Text(
                  'Main: ${map.mainBuilding}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
