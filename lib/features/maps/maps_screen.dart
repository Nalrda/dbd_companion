import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/map_callout.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class MapsScreen extends ConsumerWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsAsync = ref.watch(mapRealmsProvider);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: PageHeader.text('Map Callouts')),
          Expanded(child: realmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (realms) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: realms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            return _RealmCard(realm: realms[i])
                .animate()
                .fadeIn(delay: (i * 40).ms)
                .slideY(begin: 0.05, end: 0);
          },
        ),
      )),
        ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGlow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
            child: Row(
              children: [
                // Left red accent strip
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGlow,
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      realm.realm,
                      style: GoogleFonts.rajdhani(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${realm.maps.length} ${realm.maps.length == 1 ? 'map' : 'maps'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          ...realm.maps.map((map) => _MapListTile(map: map, realmId: realm.id)),
        ],
        ),
      ),
    );
  }
}

class _MapListTile extends StatelessWidget {
  final DbdMap map;
  final String realmId;
  const _MapListTile({required this.map, required this.realmId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      splashColor: AppTheme.primaryGlow,
      highlightColor: AppTheme.primaryGlow.withValues(alpha: 0.5),
      onTap: () => context.push('/maps/$realmId/${map.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  map.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Main: ${map.mainBuilding}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppTheme.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}
