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
    try {
      final snap = await _col().orderBy('updatedAt', descending: true).get();
      return snap.docs.map((d) => GroupPlan.fromJson(d.data())).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to load group plans: ${e.message}');
    }
  }

  Future<GroupPlan> create({required String name, String? notes}) async {
    final plan = GroupPlan(id: _uuid.v4(), name: name, notes: notes);
    try {
      await _col().doc(plan.id).set(plan.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to create group plan: ${e.message}');
    }
    return plan;
  }

  Future<void> save(GroupPlan plan) async {
    plan.updatedAt = DateTime.now();
    try {
      await _col().doc(plan.id).set(plan.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to save group plan: ${e.message}');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _col().doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete group plan: ${e.message}');
    }
  }

  Future<GroupPlan?> getById(String id) async {
    try {
      final doc = await _col().doc(id).get();
      if (!doc.exists) return null;
      return GroupPlan.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch group plan: ${e.message}');
    }
  }

  /// Creates a new plan from [template], assigning a fresh UUID.
  Future<GroupPlan> createFull(GroupPlan template) async {
    final plan = GroupPlan(
      id: _uuid.v4(),
      name: template.name,
      notes: template.notes,
      survivor1PerkIds: List<String>.from(template.survivor1PerkIds),
      survivor2PerkIds: List<String>.from(template.survivor2PerkIds),
      survivor3PerkIds: List<String>.from(template.survivor3PerkIds),
      survivor4PerkIds: List<String>.from(template.survivor4PerkIds),
      survivor1ItemId: template.survivor1ItemId,
      survivor2ItemId: template.survivor2ItemId,
      survivor3ItemId: template.survivor3ItemId,
      survivor4ItemId: template.survivor4ItemId,
      survivor1OfferingId: template.survivor1OfferingId,
      survivor2OfferingId: template.survivor2OfferingId,
      survivor3OfferingId: template.survivor3OfferingId,
      survivor4OfferingId: template.survivor4OfferingId,
    );
    try {
      await _col().doc(plan.id).set(plan.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to import group plan: ${e.message}');
    }
    return plan;
  }
}
