import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group_plan.dart';

class GroupPlanRepository {
  static const String _boxName = 'group_plans';
  static const _uuid = Uuid();

  static GroupPlanRepository? _instance;
  static GroupPlanRepository get instance => _instance ??= GroupPlanRepository._();
  GroupPlanRepository._();

  Box<GroupPlan>? _box;

  Future<Box<GroupPlan>> get _openBox async {
    _box ??= await Hive.openBox<GroupPlan>(_boxName);
    return _box!;
  }

  Future<List<GroupPlan>> getAll() async {
    final box = await _openBox;
    return box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<GroupPlan> create({required String name, String? notes}) async {
    final box = await _openBox;
    final plan = GroupPlan(id: _uuid.v4(), name: name, notes: notes);
    await box.put(plan.id, plan);
    return plan;
  }

  Future<void> save(GroupPlan plan) async {
    final box = await _openBox;
    plan.updatedAt = DateTime.now();
    await box.put(plan.id, plan);
  }

  Future<void> delete(String id) async {
    final box = await _openBox;
    await box.delete(id);
  }

  Future<GroupPlan?> getById(String id) async {
    final box = await _openBox;
    return box.get(id);
  }
}
