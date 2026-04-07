import 'package:flutter/material.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/map_callout.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/design_system.dart';

class MapsScreen extends ConsumerWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsAsync = ref.watch(mapRealmsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        orbs: [
          BackgroundOrb(
            color: AppTheme.primary,
            opacity: 0.15,
            position: Alignment.topCenter,
            size: 400,
          ),
        ],
        child: Column(
          children: [
            PageHeader(
              title: PageHeader.text(
                  AppLocalizations.of(context)!.mapsTitle),
            ),
            Expanded(
              child: realmsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (realms) => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: realms.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    return _RealmCard(realm: realms[i])
                        .animate()
                        .fadeIn(delay: (i * 40).ms)
                        .slideY(begin: 0.05, end: 0);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealmCard extends StatelessWidget {
  final MapRealm realm;
  const _RealmCard({required this.realm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: Row(
              children: [
                // Accent left strip
                Container(
                  width: 3,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppTheme.primary, AppTheme.primaryDim],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      realm.realm,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${realm.maps.length} ${realm.maps.length == 1 ? 'map' : 'maps'}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.border),
          ...realm.maps.map((map) =>
              _MapListTile(map: map, realmId: realm.id)),
        ],
      ),
    );
  }
}

class _MapListTile extends StatefulWidget {
  final DbdMap map;
  final String realmId;
  const _MapListTile({required this.map, required this.realmId});

  @override
  State<_MapListTile> createState() => _MapListTileState();
}

class _MapListTileState extends State<_MapListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () =>
            context.push('/maps/${widget.realmId}/${widget.map.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered
              ? AppTheme.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.map.name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Main: ${widget.map.mainBuilding}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: _hovered
                    ? AppTheme.primary
                    : AppTheme.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
