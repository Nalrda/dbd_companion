import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/addon.dart';

class AddonRepository {
  static AddonRepository? _instance;
  static AddonRepository get instance => _instance ??= AddonRepository._();
  AddonRepository._();

  Map<String, dynamic>? _raw;

  Future<Map<String, dynamic>> _load() async {
    if (_raw != null) return _raw!;
    final str = await rootBundle.loadString('assets/data/addons.json');
    _raw = jsonDecode(str) as Map<String, dynamic>;
    return _raw!;
  }

  Future<List<Addon>> getKillerAddons(String killerId) async {
    final data = await _load();
    final killerMap = data['killer_addons'] as Map<String, dynamic>;
    final list = killerMap[killerId] as List<dynamic>? ?? [];
    return list.map((e) => Addon.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Addon>> getItemAddons(String itemCategory) async {
    final data = await _load();
    final itemMap = data['item_addons'] as Map<String, dynamic>;
    final list = itemMap[itemCategory] as List<dynamic>? ?? [];
    return list.map((e) => Addon.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Addon?> getById(String id) async {
    final data = await _load();

    final killerMap = data['killer_addons'] as Map<String, dynamic>;
    for (final list in killerMap.values) {
      for (final e in list as List<dynamic>) {
        final addon = Addon.fromJson(e as Map<String, dynamic>);
        if (addon.id == id) return addon;
      }
    }

    final itemMap = data['item_addons'] as Map<String, dynamic>;
    for (final list in itemMap.values) {
      for (final e in list as List<dynamic>) {
        final addon = Addon.fromJson(e as Map<String, dynamic>);
        if (addon.id == id) return addon;
      }
    }

    return null;
  }
}
