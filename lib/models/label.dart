class Label {
  final String id;
  final String name;
  final String color;
  final bool isFavorite;

  Label({
    required this.id,
    required this.name,
    required this.color,
    required this.isFavorite,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(id: json['id'], name: json['name'], color: json['color'], isFavorite: json['is_favorite']);
  }
}