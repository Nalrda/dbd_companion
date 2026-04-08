import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

class LocaleNotifier extends StateNotifier<Locale?> {
  final SharedPreferences _prefs;
  static const _key = 'app_locale';

  LocaleNotifier(this._prefs) : super(_loadLocale(_prefs));

  static Locale? _loadLocale(SharedPreferences prefs) {
    final langCode = prefs.getString(_key);
    if (langCode == null) return const Locale('en');
    return Locale(langCode);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});
