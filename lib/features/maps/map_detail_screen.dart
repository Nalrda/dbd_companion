import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/map_callout.dart';
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MapImage(imagePath: map.image),
                const SizedBox(height: 20),
                _ClockSection(map: map),
                const SizedBox(height: 16),
                _NamedCalloutsSection(callouts: map.namedCallouts),
                const SizedBox(height: 16),
                _ClockLegend(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapImage extends StatelessWidget {
  final String imagePath;
  const _MapImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, color: AppTheme.textDim, size: 48),
          SizedBox(height: 12),
          Text(
            'Map image coming soon',
            style: TextStyle(color: AppTheme.textDim, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ClockSection extends StatelessWidget {
  final DbdMap map;
  const _ClockSection({required this.map});

  @override
  Widget build(BuildContext context) {
    final hours = ['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Clock Callouts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: hours.length,
            itemBuilder: (context, i) {
              final hour = hours[i];
              final label = map.clockPositions[hour] ?? '$hour Edge';
              final isMain = hour == '12';
              final isShack = hour == '6';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isMain
                      ? AppTheme.primaryDim
                      : isShack
                          ? AppTheme.surfaceElevated
                          : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isMain
                        ? AppTheme.primary
                        : isShack
                            ? AppTheme.accent.withValues(alpha: 0.4)
                            : AppTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isMain ? AppTheme.primary : AppTheme.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          hour,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isMain
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isMain
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isMain
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NamedCalloutsSection extends StatelessWidget {
  final List<String> callouts;
  const _NamedCalloutsSection({required this.callouts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Named Locations',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: callouts
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ClockLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.textDim, size: 16),
              SizedBox(width: 8),
              Text(
                'Clock System Guide',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• Main Building is always at 12\n'
            '• Shack is typically at 6\n'
            '• Numbers go clockwise around the map\n'
            '• Add "Edge" for border areas, "Deep" for far edges\n'
            '• Mid / Top Mid / Bottom Mid = central lane',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textDim,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}
