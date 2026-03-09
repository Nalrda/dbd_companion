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

  Build({
    required this.id,
    required this.name,
    required this.isSurvivor,
    required this.perkIds,
    this.notes,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Build copyWith({
    String? name,
    bool? isSurvivor,
    List<String>? perkIds,
    String? notes,
    List<String>? tags,
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
    );
  }
}
