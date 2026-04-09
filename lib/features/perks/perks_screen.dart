import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/widgets.dart';

// ─── Perks Screen ─────────────────────────────────────────────────────────────

class PerksScreen extends ConsumerWidget {
  const PerksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPerksAsync = ref.watch(allPerksProvider);
    final filterState = ref.watch(perksNotifierProvider);
    final notifier = ref.read(perksNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        orbs: [
          BackgroundOrb(
            color: AppTheme.primary,
            opacity: 0.15,
            position: Alignment.topLeft,
            size: 380,
          ),
        ],
        child: Column(
          children: [
            PageHeader(
              title: filterState.isSearchVisible
                  ? TextField(
                      key: ValueKey(filterState.searchFieldKey),
                      autofocus: true,
                      style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        hintStyle: GoogleFonts.outfit(color: AppTheme.textDim, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: notifier.updateSearch,
                    )
                  : PageHeader.text(l10n.perks),
              actions: [
                IconButton(
                  icon: Icon(
                    filterState.isSearchVisible ? Icons.close : Icons.search,
                    color: AppTheme.textPrimary,
                  ),
                  onPressed: notifier.toggleSearch,
                ),
              ],
            ),
            Expanded(
              child: allPerksAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
                ),
                data: (_) {
                  final filtered = filterState.filteredPerks;
                  return Column(
                    children: [
                      // Role toggle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: RoleToggle(
                          isSurvivor: filterState.isSurvivor,
                          onChanged: notifier.toggleRole,
                        ),
                      ),
                      // Results count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              l10n.perksCount(filtered.length),
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Perk list
                      Expanded(
                        child: filtered.isEmpty
                            ? _EmptyState(search: filterState.searchQuery)
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  // 2 columns on wide screens
                                  if (constraints.maxWidth > 700) {
                                    return GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 8,
                                        mainAxisExtent: 96,
                                      ),
                                      itemCount: filtered.length,
                                      itemBuilder: (context, i) => PerkCard(perk: filtered[i])
                                          .animate(delay: (i.clamp(0, 15) * 40).ms)
                                          .fadeIn(duration: 300.ms)
                                          .slideY(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut),
                                    );
                                  }
                                  return ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, i) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: PerkCard(perk: filtered[i])
                                          .animate(delay: (i.clamp(0, 15) * 40).ms)
                                          .fadeIn(duration: 300.ms)
                                          .slideY(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String search;
  const _EmptyState({required this.search});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: AppTheme.textDim, size: 48)
                .animate()
                .scale(duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              l10n.noResults,
              style: GoogleFonts.rajdhani(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(delay: 100.ms),
            if (search.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.noPerkFound(search),
                style: GoogleFonts.outfit(color: AppTheme.textDim, fontSize: 13),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
            ],
          ],
        ),
      ),
    );
  }
}
