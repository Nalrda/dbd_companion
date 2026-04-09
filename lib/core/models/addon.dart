class Addon {
  final String id;
  final String name;
  final String rarity;

  const Addon({required this.id, required this.name, required this.rarity});

  factory Addon.fromJson(Map<String, dynamic> json) => Addon(
        id: json['id'] as String,
        name: json['name'] as String,
        rarity: json['rarity'] as String,
      );
}
