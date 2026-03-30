import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/group_plan.dart';

class GroupPlanRepository {
  static const _uuid = Uuid();

  static GroupPlanRepository? _instance;
  static GroupPlanRepository get instance =>
      _instance ??= GroupPlanRepository._();
  GroupPlanRepository._();

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('group_plans');
  }

  Future<List<GroupPlan>> getAll() async {
    final snap = await _col().orderBy('updatedAt', descending: true).get();
    return snap.docs.map((d) => GroupPlan.fromJson(d.data())).toList();
  }

  Future<GroupPlan> create({required String name, String? notes}) async {
    final plan = GroupPlan(id: _uuid.v4(), name: name, notes: notes);
    await _col().doc(plan.id).set(plan.toJson());
    return plan;
  }

  Future<void> save(GroupPlan plan) async {
    plan.updatedAt = DateTime.now();
    await _col().doc(plan.id).set(plan.toJson());
  }

  Future<void> delete(String id) async {
    await _col().doc(id).delete();
  }

  Future<GroupPlan?> getById(String id) async {
    final doc = await _col().doc(id).get();
    if (!doc.exists) return null;
    return GroupPlan.fromJson(doc.data()!);
  }
}
