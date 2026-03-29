import 'package:hive/hive.dart';

part 'match_record.g.dart';

/// Outcome string values:
/// Survivor: 'escaped' | 'killed'
/// Killer: '0k' | '1k' | '2k' | '3k' | '4k'
@HiveType(typeId: 3)
class MatchRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  bool isSurvivor;

  @HiveField(2)
  String outcome;

  /// Who played killer (when survivor) or character name (when killer)
  @HiveField(3)
  String? characterName;

  @HiveField(4)
  String? mapName;

  @HiveField(5)
  List<String> perkIds;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  MatchRecord({
    required this.id,
    required this.isSurvivor,
    required this.outcome,
    this.characterName,
    this.mapName,
    List<String>? perkIds,
    this.notes,
    DateTime? createdAt,
  })  : perkIds = perkIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  String get outcomeLabel {
    if (isSurvivor) {
      return outcome == 'escaped' ? 'Escaped' : 'Killed';
    }
    switch (outcome) {
      case '0k': return '0 Kills';
      case '1k': return '1 Kill';
      case '2k': return '2 Kills';
      case '3k': return '3 Kills';
      case '4k': return '4 Kills';
      default: return outcome;
    }
  }

  bool get isWin {
    if (isSurvivor) return outcome == 'escaped';
    return outcome == '3k' || outcome == '4k';
  }
}
