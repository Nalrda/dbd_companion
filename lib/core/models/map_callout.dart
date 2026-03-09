class MapRealm {
  final String id;
  final String realm;
  final List<DbdMap> maps;

  const MapRealm({
    required this.id,
    required this.realm,
    required this.maps,
  });

  factory MapRealm.fromJson(Map<String, dynamic> json) => MapRealm(
        id: json['id'] as String,
        realm: json['realm'] as String,
        maps: (json['maps'] as List).map((m) => DbdMap.fromJson(m)).toList(),
      );
}

class DbdMap {
  final String id;
  final String name;
  final String image;
  final String mainBuilding;
  final Map<String, String> clockPositions;
  final List<String> namedCallouts;

  const DbdMap({
    required this.id,
    required this.name,
    required this.image,
    required this.mainBuilding,
    required this.clockPositions,
    required this.namedCallouts,
  });

  factory DbdMap.fromJson(Map<String, dynamic> json) => DbdMap(
        id: json['id'] as String,
        name: json['name'] as String,
        image: json['image'] as String,
        mainBuilding: json['mainBuilding'] as String,
        clockPositions: Map<String, String>.from(json['clockPositions'] as Map),
        namedCallouts: List<String>.from(json['namedCallouts'] as List),
      );
}
