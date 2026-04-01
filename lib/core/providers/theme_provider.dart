import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

const _kThemeColorKey = 'theme_primary_color';

// Override this in main.dart with the real SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider not initialized'),
);

class ThemeColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;

  ThemeColorNotifier(this._prefs)
      : super(Color(_prefs.getInt(_kThemeColorKey) ?? 0xFFCC2828)) {
    AppTheme.updatePrimaryColor(state);
  }

  void setColor(Color color) {
    AppTheme.updatePrimaryColor(color);
    state = color;
    _prefs.setInt(_kThemeColorKey, color.toARGB32());
  }
}

final themeColorProvider =
    StateNotifierProvider<ThemeColorNotifier, Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeColorNotifier(prefs);
});
