import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/build.dart';
import '../services/guest_mode.dart';

class BuildRepository {
  static const _uuid = Uuid();

  static BuildRepository? _instance;
  static BuildRepository get instance => _instance ??= BuildRepository._();
  BuildRepository._();

  bool get _isGuest => GuestMode.isGuest;

  Future<Box<String>> _localBox() => Hive.openBox<String>('guest_builds');

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('builds');
  }

  Future<List<Build>> getAllBuilds() async {
    if (_isGuest) {
      final box = await _localBox();
      final builds = box.values
          .map((s) => Build.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return builds;
    }
    try {
      final snap = await _col().orderBy('updatedAt', descending: true).get();
      return snap.docs.map((d) => Build.fromJson(d.data())).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to load builds: ${e.message}');
    }
  }

  Future<List<Build>> getSurvivorBuilds() async {
    final all = await getAllBuilds();
    return all.where((b) => b.isSurvivor).toList();
  }

  Future<List<Build>> getKillerBuilds() async {
    final all = await getAllBuilds();
    return all.where((b) => !b.isSurvivor).toList();
  }

  Future<Build> createBuild({
    required String name,
    required bool isSurvivor,
    List<String>? perkIds,
    String? notes,
    List<String>? tags,
    String? itemId,
    String? addon1,
    String? addon2,
    String? offeringId,
  }) async {
    final build = Build(
      id: _uuid.v4(),
      name: name,
      isSurvivor: isSurvivor,
      perkIds: perkIds ?? [],
      notes: notes,
      tags: tags,
      itemId: itemId,
      addon1: addon1,
      addon2: addon2,
      offeringId: offeringId,
    );
    if (_isGuest) {
      final box = await _localBox();
      await box.put(build.id, jsonEncode(build.toJson()));
      return build;
    }
    try {
      await _col().doc(build.id).set(build.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to create build: ${e.message}');
    }
    return build;
  }

  Future<void> saveBuild(Build build) async {
    if (_isGuest) {
      final box = await _localBox();
      await box.put(build.id, jsonEncode(build.toJson()));
      return;
    }
    try {
      await _col().doc(build.id).set(build.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to save build: ${e.message}');
    }
  }

  Future<void> deleteBuild(String id) async {
    if (_isGuest) {
      final box = await _localBox();
      await box.delete(id);
      return;
    }
    try {
      await _col().doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete build: ${e.message}');
    }
  }

  Future<Build?> getBuildById(String id) async {
    if (_isGuest) {
      final box = await _localBox();
      final s = box.get(id);
      if (s == null) return null;
      return Build.fromJson(jsonDecode(s) as Map<String, dynamic>);
    }
    try {
      final doc = await _col().doc(id).get();
      if (!doc.exists) return null;
      return Build.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch build: ${e.message}');
    }
  }
}
