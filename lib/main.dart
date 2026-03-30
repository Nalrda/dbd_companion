import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/build.dart';
import 'core/models/group_plan.dart';
import 'core/models/match_record.dart';
import 'core/models/perk.dart';
import 'core/theme/app_theme.dart';
import 'app/router.dart';

void main() {
  runZonedGuarded(_appMain, (error, stack) {
    debugPrint('Fatal error: $error\n$stack');
  });
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PerkAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(BuildAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GroupPlanAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MatchRecordAdapter());

  runApp(const ProviderScope(child: DBDCompanionApp()));
}

class DBDCompanionApp extends StatefulWidget {
  const DBDCompanionApp({super.key});

  @override
  State<DBDCompanionApp> createState() => _DBDCompanionAppState();
}

class _DBDCompanionAppState extends State<DBDCompanionApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initDeepLinks();
    }
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Handle link that launched the app from a terminated state
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Handle links while the app is running
    _linkSubscription = appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // Convert dbdcompanion://builds/create?... → /builds/create?...
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
    router.go('$path$query');
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DBD Companion',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
