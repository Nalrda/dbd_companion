import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/map_callout.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import 'maps_screen.dart' show MapThumbnail;

/// Aspect ratio of the bundled callout images (2000 × 2200).
const _imageAspect = 2000 / 2200;

class MapDetailScreen extends ConsumerStatefulWidget {
  final String realmId;
  final String mapId;

  const MapDetailScreen({
    super.key,
    required this.realmId,
    required this.mapId,
  });

  @override
  ConsumerState<MapDetailScreen> createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends ConsumerState<MapDetailScreen> {
  final _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _resetZoom() => _transform.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final realmsAsync = ref.watch(mapRealmsProvider);

    return Scaffold(
      body: AppBackground(
        child: realmsAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(e),
          data: (realms) {
            final realm = realms.where((r) => r.id == widget.realmId).firstOrNull;
            final map = realm?.maps.where((m) => m.id == widget.mapId).firstOrNull;
            if (realm == null || map == null) {
              return const Column(
                children: [
                  PageHeader(title: 'Map', showBack: true),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.map_outlined,
                      title: 'Map not found',
                      subtitle: 'This map is no longer available.',
                    ),
                  ),
                ],
              );
            }
            return _body(realm, map);
          },
        ),
      ),
    );
  }

  Widget _body(MapRealm realm, DbdMap map) {
    return Column(
      children: [
        PageHeader(
          showBack: true,
          title: map.name,
          subtitle: realm.realm,
          onBack: () => context.canPop() ? context.pop() : context.go('/maps'),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final pad = pagePadding(context, top: 2, bottom: 24);
              final info = _Info(realm: realm, map: map);

              if (wide) {
                return ContentWidth(
                  child: Padding(
                    padding: pad,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: AspectRatio(
                              aspectRatio: _imageAspect,
                              child: _viewer(map),
                            ),
                          ).entrance(0),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 340,
                          child: SingleChildScrollView(child: info.entrance(1)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ContentWidth(
                maxWidth: 640,
                child: ListView(
                  // While zoomed in, drags pan the map instead of the page.
                  physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                  padding: pad,
                  children: [
                    AspectRatio(aspectRatio: _imageAspect, child: _viewer(map)).entrance(0),
                    const SizedBox(height: 24),
                    info.entrance(1),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _viewer(DbdMap map) {
    return AppPanel(
      padding: const EdgeInsets.all(1),
      cut: 14,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: AppShapes.notched(cut: 13)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppTheme.backgroundSecondary,
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 0.5,
                maxScale: 5.0,
                boundaryMargin: const EdgeInsets.all(40),
                child: Image.asset(
                  map.image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined, color: AppTheme.textTertiary, size: 44),
                        const SizedBox(height: 12),
                        Text(
                          'Map image coming soon',
                          style: AppFonts.body(color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _zoomed
                    ? AppIconButton(
                        key: const ValueKey('reset'),
                        icon: Icons.zoom_out_map,
                        tooltip: 'Reset zoom',
                        onPressed: _resetZoom,
                      )
                    : IgnorePointer(
                        key: const ValueKey('hint'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: ShapeDecoration(
                            color: AppTheme.background.withValues(alpha: 0.82),
                            shape: AppShapes.notched(
                              cut: 5,
                              side: const BorderSide(color: AppTheme.border),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_in, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                AppLayout.isCompact(context) ? 'PINCH TO ZOOM' : 'SCROLL TO ZOOM',
                                style: AppFonts.caption(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info column ──────────────────────────────────────────────────────────────

class _Info extends StatelessWidget {
  final MapRealm realm;
  final DbdMap map;

  const _Info({required this.realm, required this.map});

  @override
  Widget build(BuildContext context) {
    final siblings = realm.maps.where((m) => m.id != map.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel(title: 'Details'),
        const SizedBox(height: 12),
        AppPanel(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              _DetailRow(label: 'Realm', value: realm.realm),
              const Divider(),
              _DetailRow(label: 'Main building', value: map.mainBuilding),
              const Divider(),
              _DetailRow(
                label: 'Maps in realm',
                value: '${realm.maps.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionLabel(title: 'Reading callouts'),
        const SizedBox(height: 12),
        AppPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _LegendRow(
                badge: '1–12',
                title: 'Clock positions',
                text: 'Around the map edge — 12 is the top of the map.',
              ),
              const SizedBox(height: 14),
              _LegendRow(
                badge: 'M',
                title: 'Main building',
                text: map.mainBuilding,
                solid: true,
              ),
              const SizedBox(height: 14),
              const _LegendRow(
                badge: 'MID',
                title: 'Middle',
                text: 'The center of the map.',
              ),
            ],
          ),
        ),
        if (siblings.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionLabel(title: 'Also in ${realm.realm}', count: '${siblings.length}'),
          const SizedBox(height: 12),
          for (final s in siblings) ...[
            _SiblingRow(
              map: s,
              onTap: () => context.replace('/maps/${realm.id}/${s.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: AppFonts.caption(fontSize: 12)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String badge;
  final String title;
  final String text;
  final bool solid;

  const _LegendRow({
    required this.badge,
    required this.title,
    required this.text,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 36,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: solid ? AppTheme.background : AppTheme.surfaceElevated,
            shape: AppShapes.notched(
              cut: 6,
              side: BorderSide(color: solid ? AppTheme.borderHighlight : AppTheme.border),
            ),
          ),
          child: Text(badge, style: AppFonts.display(fontSize: 15, letterSpacing: 0.8)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title.toUpperCase(), style: AppFonts.display(fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 1),
              Text(
                text,
                style: AppFonts.body(fontSize: 13, color: AppTheme.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SiblingRow extends StatelessWidget {
  final DbdMap map;
  final VoidCallback onTap;

  const _SiblingRow({required this.map, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      cut: 8,
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      child: Row(
        children: [
          ClipPath(
            clipper: ShapeBorderClipper(shape: AppShapes.notched(cut: 5)),
            child: SizedBox(width: 40, height: 40, child: MapThumbnail(image: map.image)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  map.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(fontSize: 15, letterSpacing: 1),
                ),
                Text(
                  'Main: ${map.mainBuilding}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(fontSize: 12, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppTheme.textTertiary),
        ],
      ),
    );
  }
}
