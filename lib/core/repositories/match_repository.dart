import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/match_record.dart';

class MatchRepository {
  static const String _boxName = 'matches';
  static const _uuid = Uuid();

  static MatchRepository? _instance;
  static MatchRepository get instance => _instance ??= MatchRepository._();
  MatchRepository._();

  Box<MatchRecord>? _box;

  Future<Box<MatchRecord>> get _openBox async {
    _box ??= await Hive.openBox<MatchRecord>(_boxName);
    return _box!;
  }

  Future<List<MatchRecord>> getAll() async {
    final box = await _openBox;
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    final box = await _openBox;
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
    await box.put(record.id, record);
    return record;
  }

  Future<void> delete(String id) async {
    final box = await _openBox;
    await box.delete(id);
  }
}
