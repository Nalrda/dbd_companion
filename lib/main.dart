import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/build.dart';
import 'core/models/group_plan.dart';
import 'core/models/perk.dart';
import 'core/theme/app_theme.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(PerkAdapter());
  Hive.registerAdapter(BuildAdapter());
  Hive.registerAdapter(GroupPlanAdapter());

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
