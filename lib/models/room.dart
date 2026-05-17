class Room {
  final String id;
  final String name;

  const Room({required this.id, required this.name});

  Room copyWith({String? name}) => Room(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Room.fromJson(Map<String, dynamic> j) =>
      Room(id: j['id'] as String, name: j['name'] as String);
}
