import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/models/perk.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'app/router.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(_appMain, (error, stack) {
    debugPrint('Fatal error: $error\n$stack');
  });
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PerkAdapter());

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DBDCompanionApp(),
    ),
  );
}

class DBDCompanionApp extends ConsumerWidget {
  const DBDCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Watching themeColorProvider triggers a full rebuild when the color changes,
    // causing AppTheme.dark to re-evaluate with the updated static primary color.
    final themeColor = ref.watch(themeColorProvider);
    return MaterialApp.router(
      key: ValueKey(themeColor.toARGB32()),
      title: 'DBD Companion',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
