import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dbd_companion/l10n/generated/app_localizations.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
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
    final compact = AppLayout.isCompact(context);
    final filtered = filterState.filteredPerks;

    final search = AppSearchField(
      key: ValueKey(filterState.searchFieldKey),
      hint: l10n.searchHint,
      autofocus: true,
      onChanged: notifier.updateSearch,
    );
    final role = RoleToggle(
      expand: compact,
      isSurvivor: filterState.isSurvivor,
      onChanged: notifier.toggleRole,
    );

    final Widget filters;
    if (compact) {
      filters = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          role,
          if (filterState.isSearchVisible) ...[const SizedBox(height: 10), search],
        ],
      );
    } else {
      filters = Row(
        children: [
          role,
          if (filterState.isSearchVisible) ...[
            const SizedBox(width: 12),
            Expanded(child: search),
          ],
        ],
      );
    }

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              title: l10n.perks,
              subtitle: allPerksAsync.hasValue ? l10n.perksCount(filtered.length) : null,
              actions: [
                AppIconButton(
                  icon: filterState.isSearchVisible ? Icons.close : Icons.search,
                  tooltip: filterState.isSearchVisible ? 'Close search' : 'Search',
                  active: filterState.isSearchVisible,
                  onPressed: notifier.toggleSearch,
                ),
              ],
              bottom: filters,
            ),
            Expanded(
              child: allPerksAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(e),
                data: (_) {
                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: l10n.noResults,
                      subtitle: filterState.searchQuery.isNotEmpty
                          ? l10n.noPerkFound(filterState.searchQuery)
                          : '',
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final pad = pagePadding(context, top: 4, bottom: 24);
                      Widget itemAt(int i) => PerkCard(perk: filtered[i]).entrance(i);
                      return ContentWidth(
                        child: constraints.maxWidth > 760
                            ? GridView.builder(
                                padding: pad,
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 540,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 8,
                                  mainAxisExtent: 96,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => itemAt(i),
                              )
                            : ListView.separated(
                                padding: pad,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => itemAt(i),
                              ),
                      );
                    },
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
