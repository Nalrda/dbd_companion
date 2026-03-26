class Item {
  final String id;
  final String name;
  final String category; // none, medkit, flashlight, toolbox, key, map
  final String rarity;

  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        rarity: json['rarity'] as String,
      );
}
