import 'package:go_router/go_router.dart';
import '../features/builds/build_detail_screen.dart';
import '../features/builds/build_editor_screen.dart';
import '../features/builds/builds_screen.dart';
import '../features/maps/map_detail_screen.dart';
import '../features/maps/maps_screen.dart';
import '../features/randomizer/randomizer_screen.dart';
import '../features/group_planner/group_planner_screen.dart';
import '../features/group_planner/group_plan_editor_screen.dart';
import 'shell_screen.dart';

final router = GoRouter(
  initialLocation: '/builds',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/builds', builder: (_, __) => const BuildsScreen()),
        GoRoute(path: '/randomizer', builder: (_, __) => const RandomizerScreen()),
        GoRoute(path: '/maps', builder: (_, __) => const MapsScreen()),
        GoRoute(path: '/group', builder: (_, __) => const GroupPlannerScreen()),
      ],
    ),
    GoRoute(
      path: '/builds/create',
      builder: (context, state) {
        final isSurvivor = state.uri.queryParameters['survivor'] != 'false';
        return BuildEditorScreen(isSurvivor: isSurvivor);
      },
    ),
    GoRoute(
      path: '/builds/:id',
      builder: (context, state) =>
          BuildDetailScreen(buildId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/builds/:id/edit',
      builder: (context, state) => BuildEditorScreen(
        buildId: state.pathParameters['id'],
        isSurvivor: true,
      ),
    ),
    GoRoute(
      path: '/group/:id',
      builder: (context, state) =>
          GroupPlanEditorScreen(planId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/maps/:realmId/:mapId',
      builder: (context, state) => MapDetailScreen(
        realmId: state.pathParameters['realmId']!,
        mapId: state.pathParameters['mapId']!,
      ),
    ),
  ],
);
