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

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String rarity;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final bool isSurvivor;

  @HiveField(7)
  final String? iconUrl;

  Perk({
    required this.id,
    required this.name,
    required this.character,
    required this.description,
    required this.rarity,
    required this.category,
    required this.isSurvivor,
    this.iconUrl,
  });

  factory Perk.fromJson(Map<String, dynamic> json, {required bool isSurvivor}) {
    return Perk(
      id: json['id'] as String,
      name: json['name'] as String,
      character: json['character'] as String,
      description: json['description'] as String,
      rarity: json['rarity'] as String,
      category: json['category'] as String,
      isSurvivor: isSurvivor,
      iconUrl: json['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'character': character,
      'description': description,
      'rarity': rarity,
      'category': category,
      'isSurvivor': isSurvivor,
      'iconUrl': iconUrl,
    };
  }
}
