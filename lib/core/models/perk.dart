import 'package:hive/hive.dart';

part 'perk.g.dart';

@HiveType(typeId: 0)
class Perk extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String character;

  @HiveField(5)
  final bool isSurvivor;

  @HiveField(6)
  final String? iconUrl;

  final List<String> tags;

  Perk({
    required this.id,
    required this.name,
    required this.character,
    required this.isSurvivor,
    this.iconUrl,
    List<String>? tags,
  }) : tags = tags ?? [];

  factory Perk.fromJson(Map<String, dynamic> json, {required bool isSurvivor}) {
    return Perk(
      id: json['id'] as String,
      name: json['name'] as String,
      character: json['character'] as String,
      isSurvivor: isSurvivor,
      iconUrl: json['iconUrl'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'character': character,
      'isSurvivor': isSurvivor,
      'iconUrl': iconUrl,
      'tags': tags,
    };
  }
}
