import 'package:hive/hive.dart';

part 'build.g.dart';

@HiveType(typeId: 1)
class Build extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isSurvivor;

  @HiveField(3)
  List<String> perkIds; // max 4

  @HiveField(4)
  String? notes;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  /// Survivor: item id from items.json. Killer: unused (null).
  @HiveField(8)
  String? itemId;

  /// Add-on slot 1 (free text — used mainly for killer add-ons).
  @HiveField(9)
  String? addon1;

  /// Add-on slot 2 (free text — used mainly for killer add-ons).
  @HiveField(10)
  String? addon2;

  /// Offering id from offerings.json (both survivor and killer).
  @HiveField(11)
  String? offeringId;

  Build({
    required this.id,
    required this.name,
    required this.isSurvivor,
    required this.perkIds,
    this.notes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.itemId,
    this.addon1,
    this.addon2,
    this.offeringId,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static const Object _sentinel = Object();

  Build copyWith({
    String? name,
    bool? isSurvivor,
    List<String>? perkIds,
    String? notes,
    List<String>? tags,
    Object? itemId = _sentinel,
    Object? addon1 = _sentinel,
    Object? addon2 = _sentinel,
    Object? offeringId = _sentinel,
  }) {
    return Build(
      id: id,
      name: name ?? this.name,
      isSurvivor: isSurvivor ?? this.isSurvivor,
      perkIds: perkIds ?? List.from(this.perkIds),
      notes: notes ?? this.notes,
      tags: tags ?? List.from(this.tags),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      itemId: itemId == _sentinel ? this.itemId : itemId as String?,
      addon1: addon1 == _sentinel ? this.addon1 : addon1 as String?,
      addon2: addon2 == _sentinel ? this.addon2 : addon2 as String?,
      offeringId: offeringId == _sentinel ? this.offeringId : offeringId as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isSurvivor': isSurvivor,
      'perkIds': perkIds,
      'notes': notes,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'itemId': itemId,
      'addon1': addon1,
      'addon2': addon2,
      'offeringId': offeringId,
    };
  }

  factory Build.fromJson(Map<String, dynamic> json) {
    return Build(
      id: json['id'] as String,
      name: json['name'] as String,
      isSurvivor: json['isSurvivor'] as bool,
      perkIds: List<String>.from(json['perkIds'] ?? []),
      notes: json['notes'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      itemId: json['itemId'] as String?,
      addon1: json['addon1'] as String?,
      addon2: json['addon2'] as String?,
      offeringId: json['offeringId'] as String?,
    );
  }
}
