import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/killer.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';

class KillerDetailScreen extends ConsumerWidget {
  final String killerId;
  const KillerDetailScreen({super.key, required this.killerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final killersAsync = ref.watch(killersProvider);
    return killersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (killers) {
        Killer? killer;
        try {
          killer = killers.firstWhere((k) => k.id == killerId);
        } catch (_) {
          return const Scaffold(
              body: Center(child: Text('Killer not found')));
        }
        return _KillerDetailView(killer: killer);
      },
    );
  }
}

class _KillerDetailView extends StatelessWidget {
  final Killer killer;
  const _KillerDetailView({required this.killer});

  Color get _diffColor {
    switch (killer.difficulty) {
      case 'easy': return const Color(0xFF3E9E44);
      case 'intermediate': return AppTheme.primary;
      case 'hard': return AppTheme.accent;
      case 'very hard': return const Color(0xFF8B35D6);
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(killer.name)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                    boxShadow: const [
                      BoxShadow(
                          color: AppTheme.primaryGlow,
                          blurRadius: 16,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              AppTheme.primaryDim.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppTheme.primary.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            killer.name.replaceFirst('The ', '')[0],
                            style: GoogleFonts.rajdhani(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              killer.name,
                              style: GoogleFonts.rajdhani(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              killer.alias,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    _diffColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color:
                                        _diffColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                _capitalize(killer.difficulty),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _diffColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.05, end: 0),

                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                      icon: Icons.speed,
                      label: 'SPEED',
                      value: '${killer.movementSpeed} m/s',
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                      icon: Icons.radio_button_checked,
                      label: 'TERROR RADIUS',
                      value: '${killer.terrorRadius} m',
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _StatCard(
                      icon: Icons.height,
                      label: 'HEIGHT',
                      value: _capitalize(killer.height),
                    )),
                  ],
                ).animate().fadeIn(delay: 80.ms),

                const SizedBox(height: 20),
                const SectionHeader(title: 'POWER'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        killer.power,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        killer.powerDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 120.ms),

                const SizedBox(height: 20),
                const SectionHeader(title: 'TIP'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDim.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          killer.tip,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 160.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
