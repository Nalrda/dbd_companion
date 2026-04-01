import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/builds/build_detail_screen.dart';
import '../features/builds/build_editor_screen.dart';
import '../features/builds/builds_screen.dart';
import '../features/killers/killer_detail_screen.dart';
import '../features/killers/killers_screen.dart';
import '../features/maps/map_detail_screen.dart';
import '../features/maps/maps_screen.dart';
import '../features/matches/match_editor_screen.dart';
import '../features/matches/matches_screen.dart';
import '../features/randomizer/randomizer_screen.dart';
import '../features/group_planner/group_planner_screen.dart';
import '../features/group_planner/group_plan_editor_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell_screen.dart';

Page<void> _fadeSlidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (ctx, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authNotifierProvider);

  return GoRouter(
    initialLocation: '/builds',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.user != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/builds';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _fadeSlidePage(const LoginScreen(), state),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/builds', pageBuilder: (_, state) => _fadeSlidePage(const BuildsScreen(), state)),
          GoRoute(path: '/randomizer', pageBuilder: (_, state) => _fadeSlidePage(const RandomizerScreen(), state)),
          GoRoute(path: '/killers', pageBuilder: (_, state) => _fadeSlidePage(const KillersScreen(), state)),
          GoRoute(path: '/matches', pageBuilder: (_, state) => _fadeSlidePage(const MatchesScreen(), state)),
          GoRoute(path: '/maps', pageBuilder: (_, state) => _fadeSlidePage(const MapsScreen(), state)),
          GoRoute(path: '/group', pageBuilder: (_, state) => _fadeSlidePage(const GroupPlannerScreen(), state)),
        ],
      ),
      GoRoute(
        path: '/builds/create',
        pageBuilder: (context, state) {
          final isSurvivor = state.uri.queryParameters['survivor'] != 'false';
          final perksParam = state.uri.queryParameters['perks'];
          final sharedPerks = perksParam?.split(',').where((s) => s.isNotEmpty).toList();
          final sharedName = state.uri.queryParameters['name'];
          return _fadeSlidePage(
            BuildEditorScreen(
              isSurvivor: isSurvivor,
              sharedPerkIds: sharedPerks,
              sharedName: sharedName,
            ),
            state,
          );
        },
      ),
      GoRoute(
        path: '/builds/:id',
        pageBuilder: (context, state) => _fadeSlidePage(
          BuildDetailScreen(buildId: state.pathParameters['id']!),
          state,
        ),
      ),
      GoRoute(
        path: '/builds/:id/edit',
        pageBuilder: (context, state) => _fadeSlidePage(
          BuildEditorScreen(buildId: state.pathParameters['id']),
          state,
        ),
      ),
      GoRoute(
        path: '/group/:id',
        pageBuilder: (context, state) => _fadeSlidePage(
          GroupPlanEditorScreen(planId: state.pathParameters['id']!),
          state,
        ),
      ),
      GoRoute(
        path: '/maps/:realmId/:mapId',
        pageBuilder: (context, state) => _fadeSlidePage(
          MapDetailScreen(
            realmId: state.pathParameters['realmId']!,
            mapId: state.pathParameters['mapId']!,
          ),
          state,
        ),
      ),
      GoRoute(
        path: '/killers/:id',
        pageBuilder: (context, state) => _fadeSlidePage(
          KillerDetailScreen(killerId: state.pathParameters['id']!),
          state,
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _fadeSlidePage(const SettingsScreen(), state),
      ),
      GoRoute(
        path: '/matches/add',
        pageBuilder: (context, state) {
          final isSurvivor = state.uri.queryParameters['survivor'] != 'false';
          return _fadeSlidePage(MatchEditorScreen(isSurvivor: isSurvivor), state);
        },
      ),
    ],
  );
});
