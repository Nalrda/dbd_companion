import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/offering.dart';

class OfferingRepository {
  OfferingRepository._();
  static final instance = OfferingRepository._();

  List<Offering>? _cache;

  Future<List<Offering>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/offerings.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['offerings'] as List)
        .map((e) => Offering.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<Offering>> getAll() => _load();

  Future<List<Offering>> getForRole({required bool isSurvivor}) async {
    final all = await _load();
    final role = isSurvivor ? 'survivor' : 'killer';
    return all.where((o) => o.type == 'shared' || o.type == role).toList();
  }

  Future<Offering?> getById(String id) async {
    final all = await _load();
    try {
      return all.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
