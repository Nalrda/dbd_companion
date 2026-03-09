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

  @HiveField(13)
  String? survivor1OfferingId;

  @HiveField(14)
  String? survivor2OfferingId;

  @HiveField(15)
  String? survivor3OfferingId;

  @HiveField(16)
  String? survivor4OfferingId;

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
    this.survivor1OfferingId,
    this.survivor2OfferingId,
    this.survivor3OfferingId,
    this.survivor4OfferingId,
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

  String? getOfferingIdForSurvivor(int index) {
    switch (index) {
      case 0: return survivor1OfferingId;
      case 1: return survivor2OfferingId;
      case 2: return survivor3OfferingId;
      case 3: return survivor4OfferingId;
      default: return null;
    }
  }

  void setOfferingIdForSurvivor(int index, String? id) {
    switch (index) {
      case 0: survivor1OfferingId = id; break;
      case 1: survivor2OfferingId = id; break;
      case 2: survivor3OfferingId = id; break;
      case 3: survivor4OfferingId = id; break;
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
    'survivor1OfferingId': survivor1OfferingId,
    'survivor2OfferingId': survivor2OfferingId,
    'survivor3OfferingId': survivor3OfferingId,
    'survivor4OfferingId': survivor4OfferingId,
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
    survivor1OfferingId: json['survivor1OfferingId'] as String?,
    survivor2OfferingId: json['survivor2OfferingId'] as String?,
    survivor3OfferingId: json['survivor3OfferingId'] as String?,
    survivor4OfferingId: json['survivor4OfferingId'] as String?,
  );
}
