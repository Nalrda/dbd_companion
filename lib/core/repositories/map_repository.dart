import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/map_callout.dart';

class MapRepository {
  List<MapRealm>? _cache;

  Future<List<MapRealm>> getRealms() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/maps.json');
    final list = jsonDecode(raw) as List;
    _cache = list.map((e) => MapRealm.fromJson(e)).toList();
    return _cache!;
  }
}
