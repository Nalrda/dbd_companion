import 'dart:async';
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

class DBDCompanionApp extends StatelessWidget {
  const DBDCompanionApp({super.key});

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
