class Killer {
  final String id;
  final String name;
  final String alias;
  final String power;
  final String powerDescription;
  final double movementSpeed;
  final int terrorRadius;
  final String height;
  final String tip;
  final String? iconUrl;

  const Killer({
    required this.id,
    required this.name,
    required this.alias,
    required this.power,
    required this.powerDescription,
    required this.movementSpeed,
    required this.terrorRadius,
    required this.height,
    required this.tip,
    this.iconUrl,
  });

  factory Killer.fromJson(Map<String, dynamic> json) {
    return Killer(
      id: json['id'] as String,
      name: json['name'] as String,
      alias: json['alias'] as String,
      power: json['power'] as String,
      powerDescription: json['powerDescription'] as String,
      movementSpeed: (json['movementSpeed'] as num).toDouble(),
      terrorRadius: json['terrorRadius'] as int,
      height: json['height'] as String,
      tip: json['tip'] as String,
      iconUrl: json['iconUrl'] as String?,
    );
  }
}
