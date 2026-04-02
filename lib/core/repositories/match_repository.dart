import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/match_record.dart';
import '../services/guest_mode.dart';

class MatchRepository {
  static const _uuid = Uuid();

  static MatchRepository? _instance;
  static MatchRepository get instance => _instance ??= MatchRepository._();
  MatchRepository._();

  bool get _isGuest => GuestMode.isGuest;

  Future<Box<String>> _localBox() => Hive.openBox<String>('guest_matches');

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matches');
  }

  Future<List<MatchRecord>> getAll() async {
    if (_isGuest) {
      final box = await _localBox();
      final records = box.values
          .map((s) => MatchRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    }
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
    if (_isGuest) {
      final box = await _localBox();
      await box.put(record.id, jsonEncode(record.toJson()));
      return record;
    }
    try {
      await _col().doc(record.id).set(record.toJson());
    } on FirebaseException catch (e) {
      throw Exception('Failed to save match: ${e.message}');
    }
    return record;
  }

  Future<void> delete(String id) async {
    if (_isGuest) {
      final box = await _localBox();
      await box.delete(id);
      return;
    }
    try {
      await _col().doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete match: ${e.message}');
    }
  }
}
