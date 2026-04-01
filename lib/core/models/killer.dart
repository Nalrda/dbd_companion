class Killer {
  final String id;
  final String name;
  final String power;
  final String powerDescription;
  final double movementSpeed;
  final int terrorRadius;
  final String height;
  final String? iconUrl;

  const Killer({
    required this.id,
    required this.name,
    required this.power,
    required this.powerDescription,
    required this.movementSpeed,
    required this.terrorRadius,
    required this.height,
    this.iconUrl,
  });

  factory Killer.fromJson(Map<String, dynamic> json) {
    return Killer(
      id: json['id'] as String,
      name: json['name'] as String,
      power: json['power'] as String,
      powerDescription: json['powerDescription'] as String,
      movementSpeed: (json['movementSpeed'] as num).toDouble(),
      terrorRadius: json['terrorRadius'] as int,
      height: json['height'] as String,
      iconUrl: json['iconUrl'] as String?,
    );
  }
}
