import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/build.dart';

class BuildRepository {
  static const _uuid = Uuid();

  static BuildRepository? _instance;
  static BuildRepository get instance => _instance ??= BuildRepository._();
  BuildRepository._();

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('builds');
  }

  Future<List<Build>> getAllBuilds() async {
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
  }) async {
    final build = Build(
      id: _uuid.v4(),
      name: name,
      isSurvivor: isSurvivor,
      perkIds: perkIds ?? [],
      notes: notes,
      tags: tags,
    );
    try {
      await _col().doc(build.id).set(build.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to create build: ${e.message}');
    }
    return build;
  }

  Future<void> saveBuild(Build build) async {
    try {
      await _col().doc(build.id).set(build.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to save build: ${e.message}');
    }
  }

  Future<void> deleteBuild(String id) async {
    try {
      await _col().doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete build: ${e.message}');
    }
  }

  Future<Build?> getBuildById(String id) async {
    try {
      final doc = await _col().doc(id).get();
      if (!doc.exists) return null;
      return Build.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch build: ${e.message}');
    }
  }
}
