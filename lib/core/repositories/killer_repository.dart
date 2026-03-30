import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/killer.dart';

class KillerRepository {
  static KillerRepository? _instance;
  static KillerRepository get instance => _instance ??= KillerRepository._();
  KillerRepository._();

  List<Killer>? _cache;

  Future<List<Killer>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/killers.json');
    final Map<String, dynamic> json = jsonDecode(raw);
    _cache = (json['killers'] as List)
        .map((e) => Killer.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
