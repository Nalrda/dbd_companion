import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/perk.dart';

class PerkRepository {
  static PerkRepository? _instance;
  static PerkRepository get instance => _instance ??= PerkRepository._();
  PerkRepository._();

  List<Perk>? _allPerks;

  Future<List<Perk>> getAllPerks() async {
    if (_allPerks != null) return _allPerks!;
    await _loadPerks();
    return _allPerks!;
  }

  Future<List<Perk>> getSurvivorPerks() async {
    final all = await getAllPerks();
    return all.where((p) => p.isSurvivor).toList();
  }

  Future<List<Perk>> getKillerPerks() async {
    final all = await getAllPerks();
    return all.where((p) => !p.isSurvivor).toList();
  }

  Future<Perk?> getPerkById(String id) async {
    final all = await getAllPerks();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Perk>> getPerksByIds(List<String> ids) async {
    final all = await getAllPerks();
    return all.where((p) => ids.contains(p.id)).toList();
  }

  Future<void> _loadPerks() async {
    final jsonStr = await rootBundle.loadString('assets/data/perks.json');
    final Map<String, dynamic> data = json.decode(jsonStr);

    final survivorPerks = (data['survivor_perks'] as List)
        .map((j) => Perk.fromJson(j as Map<String, dynamic>, isSurvivor: true))
        .toList();

    final killerPerks = (data['killer_perks'] as List)
        .map((j) => Perk.fromJson(j as Map<String, dynamic>, isSurvivor: false))
        .toList();

    _allPerks = [...survivorPerks, ...killerPerks];
  }
}
