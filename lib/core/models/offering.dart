class Offering {
  final String id;
  final String name;
  final String rarity; // none, common, uncommon, rare, very_rare, ultra_rare
  final String type;   // shared, survivor, killer
  final String category; // none, bloodpoints, map, fog, hook, chest, mori, escape, hatch, other

  const Offering({
    required this.id,
    required this.name,
    required this.rarity,
    required this.type,
    required this.category,
  });

  factory Offering.fromJson(Map<String, dynamic> json) => Offering(
        id: json['id'] as String,
        name: json['name'] as String,
        rarity: json['rarity'] as String,
        type: json['type'] as String,
        category: json['category'] as String,
      );
}
