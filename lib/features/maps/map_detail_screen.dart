import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class MapDetailScreen extends ConsumerWidget {
  final String realmId;
  final String mapId;

  const MapDetailScreen({
    super.key,
    required this.realmId,
    required this.mapId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsAsync = ref.watch(mapRealmsProvider);

    return realmsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (realms) {
        final realm = realms.firstWhere((r) => r.id == realmId);
        final map = realm.maps.firstWhere((m) => m.id == mapId);

        return Scaffold(
          appBar: AppBar(
            title: Text(map.name),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.border),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              // On wide screens, constrain the map viewer to prevent it from
              // stretching too wide and losing detail
              final viewerMaxWidth = isWide ? 800.0 : double.infinity;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: viewerMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5.0,
                        boundaryMargin: const EdgeInsets.all(40),
                        child: Image.asset(
                          map.image,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined,
                                      color: AppTheme.textDim, size: 48),
                                  SizedBox(height: 12),
                                  Text(
                                    'Map image coming soon',
                                    style: TextStyle(
                                        color: AppTheme.textDim, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
