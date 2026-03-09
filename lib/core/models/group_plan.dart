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

  @HiveField(9)
  String? survivor1ItemId;

  @HiveField(10)
  String? survivor2ItemId;

  @HiveField(11)
  String? survivor3ItemId;

  @HiveField(12)
  String? survivor4ItemId;

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
    this.survivor1ItemId,
    this.survivor2ItemId,
    this.survivor3ItemId,
    this.survivor4ItemId,
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

  String? getItemIdForSurvivor(int index) {
    switch (index) {
      case 0: return survivor1ItemId;
      case 1: return survivor2ItemId;
      case 2: return survivor3ItemId;
      case 3: return survivor4ItemId;
      default: return null;
    }
  }

  void setItemIdForSurvivor(int index, String? id) {
    switch (index) {
      case 0: survivor1ItemId = id; break;
      case 1: survivor2ItemId = id; break;
      case 2: survivor3ItemId = id; break;
      case 3: survivor4ItemId = id; break;
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
    'survivor1ItemId': survivor1ItemId,
    'survivor2ItemId': survivor2ItemId,
    'survivor3ItemId': survivor3ItemId,
    'survivor4ItemId': survivor4ItemId,
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
    survivor1ItemId: json['survivor1ItemId'] as String?,
    survivor2ItemId: json['survivor2ItemId'] as String?,
    survivor3ItemId: json['survivor3ItemId'] as String?,
    survivor4ItemId: json['survivor4ItemId'] as String?,
  );
}
