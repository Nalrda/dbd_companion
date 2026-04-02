import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/match_record.dart';

class MatchRepository {
  static const _uuid = Uuid();

  static MatchRepository? _instance;
  static MatchRepository get instance => _instance ??= MatchRepository._();
  MatchRepository._();

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matches');
  }

  Future<List<MatchRecord>> getAll() async {
    try {
      final snap = await _col().orderBy('createdAt', descending: true).get();
      return snap.docs.map((d) => MatchRecord.fromJson(d.data())).toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to load matches: ${e.message}');
    }
  }

  Future<MatchRecord> create({
    required bool isSurvivor,
    required String outcome,
    String? characterName,
    String? mapName,
    List<String>? perkIds,
    String? notes,
    int? gensRemaining,
  }) async {
    final record = MatchRecord(
      id: _uuid.v4(),
      isSurvivor: isSurvivor,
      outcome: outcome,
      characterName: characterName,
      mapName: mapName,
      perkIds: perkIds,
      notes: notes,
      gensRemaining: gensRemaining,
    );
    try {
      await _col().doc(record.id).set(record.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to save match: ${e.message}');
    }
    return record;
  }

  Future<void> delete(String id) async {
    try {
      await _col().doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete match: ${e.message}');
    }
  }
}
