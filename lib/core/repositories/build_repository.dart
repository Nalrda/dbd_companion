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
    final snap = await _col().orderBy('updatedAt', descending: true).get();
    return snap.docs.map((d) => Build.fromJson(d.data())).toList();
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
    await _col().doc(build.id).set(build.toJson());
    return build;
  }

  Future<void> saveBuild(Build build) async {
    await _col().doc(build.id).set(build.toJson());
  }

  Future<void> deleteBuild(String id) async {
    await _col().doc(id).delete();
  }

  Future<Build?> getBuildById(String id) async {
    final doc = await _col().doc(id).get();
    if (!doc.exists) return null;
    return Build.fromJson(doc.data()!);
  }
}
