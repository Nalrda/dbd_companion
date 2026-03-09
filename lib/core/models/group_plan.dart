import 'package:hive/hive.dart';

part 'group_plan.g.dart';

@HiveType(typeId: 2)
class GroupPlan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> survivor1PerkIds;

  @HiveField(3)
  List<String> survivor2PerkIds;

  @HiveField(4)
  List<String> survivor3PerkIds;

  @HiveField(5)
  List<String> survivor4PerkIds;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  GroupPlan({
    required this.id,
    required this.name,
    List<String>? survivor1PerkIds,
    List<String>? survivor2PerkIds,
    List<String>? survivor3PerkIds,
    List<String>? survivor4PerkIds,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : survivor1PerkIds = survivor1PerkIds ?? [],
        survivor2PerkIds = survivor2PerkIds ?? [],
        survivor3PerkIds = survivor3PerkIds ?? [],
        survivor4PerkIds = survivor4PerkIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  List<String> getPerkIdsForSurvivor(int index) {
    switch (index) {
      case 0: return survivor1PerkIds;
      case 1: return survivor2PerkIds;
      case 2: return survivor3PerkIds;
      case 3: return survivor4PerkIds;
      default: return [];
    }
  }

  void setPerkIdsForSurvivor(int index, List<String> ids) {
    switch (index) {
      case 0: survivor1PerkIds = ids; break;
      case 1: survivor2PerkIds = ids; break;
      case 2: survivor3PerkIds = ids; break;
      case 3: survivor4PerkIds = ids; break;
    }
    updatedAt = DateTime.now();
  }

  int get totalPerksCount =>
      survivor1PerkIds.length +
      survivor2PerkIds.length +
      survivor3PerkIds.length +
      survivor4PerkIds.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'survivor1PerkIds': survivor1PerkIds,
    'survivor2PerkIds': survivor2PerkIds,
    'survivor3PerkIds': survivor3PerkIds,
    'survivor4PerkIds': survivor4PerkIds,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory GroupPlan.fromJson(Map<String, dynamic> json) => GroupPlan(
    id: json['id'],
    name: json['name'],
    survivor1PerkIds: List<String>.from(json['survivor1PerkIds'] ?? []),
    survivor2PerkIds: List<String>.from(json['survivor2PerkIds'] ?? []),
    survivor3PerkIds: List<String>.from(json['survivor3PerkIds'] ?? []),
    survivor4PerkIds: List<String>.from(json['survivor4PerkIds'] ?? []),
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
