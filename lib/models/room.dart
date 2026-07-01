class Room {
  final String id;
  final String name;

  /// Monthly rent price for this room, in USD. Defaults to 0 when unset.
  final double priceUsd;

  const Room({required this.id, required this.name, this.priceUsd = 0});

  Room copyWith({String? name, double? priceUsd}) => Room(
    id: id,
    name: name ?? this.name,
    priceUsd: priceUsd ?? this.priceUsd,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceUsd': priceUsd,
  };

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'] as String,
    name: j['name'] as String,
    priceUsd: (j['priceUsd'] as num?)?.toDouble() ?? 0,
  );
}
