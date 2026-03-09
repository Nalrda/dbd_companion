import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/map_callout.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class MapsScreen extends ConsumerWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsAsync = ref.watch(mapRealmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Callouts'),
      ),
      body: realmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (realms) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: realms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final realm = realms[i];
            return _RealmCard(realm: realm)
                .animate()
                .fadeIn(delay: (i * 40).ms)
                .slideY(begin: 0.05, end: 0);
          },
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    realm.realm,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
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
      onTap: () => context.push('/maps/${realmId}/${map.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    map.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Main: ${map.mainBuilding}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}
