import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/item.dart';

class ItemRepository {
  static ItemRepository? _instance;
  static ItemRepository get instance => _instance ??= ItemRepository._();
  ItemRepository._();

  List<Item>? _items;

  Future<List<Item>> getSurvivorItems() async {
    if (_items != null) return _items!;
    final raw = await rootBundle.loadString('assets/data/items.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _items = (data['survivor_items'] as List)
        .map((j) => Item.fromJson(j as Map<String, dynamic>))
        .toList();
    return _items!;
  }

  Future<Item?> getById(String id) async {
    final all = await getSurvivorItems();
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
